require "test_helper"

class Api::V1::AnnouncementsControllerComprehensiveTest < ActionDispatch::IntegrationTest
  def setup
    @admin_user = create(:user, :admin)
    @manager_user = create(:user, :manager)
    @staff_user = create(:user, :staff)
    @read_only_user = create(:user, :read_only)
    
    @published_announcements = create_list(:announcement, 5, :published)
    @draft_announcements = create_list(:announcement, 3, :draft)
    @urgent_announcements = create_list(:announcement, 2, :urgent, :published)
  end

  # Index Action Tests
  test "should get announcements index for all authenticated users" do
    [@admin_user, @manager_user, @staff_user, @read_only_user].each do |user|
      mock_current_user(user)
      get api_v1_announcements_path, headers: auth_headers_for(user)
      
      assert_response :success, "User with role #{user.role} should access announcements"
      json_response = JSON.parse(response.body)
      
      assert_equal 'success', json_response['status']
      assert json_response['data']['announcements'].is_a?(Array)
      
      # Should only return published announcements for non-admin users
      unless user.role == 3  # admin
        published_count = json_response['data']['announcements'].count
        assert published_count <= @published_announcements.length + @urgent_announcements.length
      end
    end
  end

  test "should deny announcements index without authentication" do
    get api_v1_announcements_path
    
    assert_response :unauthorized
  end

  test "should filter announcements by category" do
    mock_current_user(@staff_user)
    get api_v1_announcements_path,
        params: { category: 'urgent' },
        headers: auth_headers_for(@staff_user)
    
    assert_response :success
    json_response = JSON.parse(response.body)
    
    urgent_announcements = json_response['data']['announcements']
    assert urgent_announcements.all? { |ann| ann['category'] == 'urgent' }
  end

  test "should filter announcements by priority" do
    mock_current_user(@staff_user)
    get api_v1_announcements_path,
        params: { priority: 'urgent' },
        headers: auth_headers_for(@staff_user)
    
    assert_response :success
    json_response = JSON.parse(response.body)
    
    urgent_priority = json_response['data']['announcements']
    assert urgent_priority.all? { |ann| ann['priority'] == 'urgent' }
  end

  test "should search announcements by title and content" do
    searchable = create(:announcement, :published, 
                       title: 'Important Meeting Announcement',
                       content: 'Team meeting scheduled for tomorrow')
    
    mock_current_user(@staff_user)
    get api_v1_announcements_path,
        params: { search: 'meeting' },
        headers: auth_headers_for(@staff_user)
    
    assert_response :success
    json_response = JSON.parse(response.body)
    
    found_announcements = json_response['data']['announcements']
    assert found_announcements.any? { |ann| ann['id'] == searchable.id }
  end

  test "should paginate announcements" do
    mock_current_user(@staff_user)
    get api_v1_announcements_path,
        params: { page: 1, per_page: 3 },
        headers: auth_headers_for(@staff_user)
    
    assert_response :success
    json_response = JSON.parse(response.body)
    
    assert json_response['data']['announcements'].length <= 3
    assert json_response['data']['pagination'].present?
    assert json_response['data']['pagination']['current_page'] == 1
  end

  test "should order announcements by published_at desc by default" do
    mock_current_user(@staff_user)
    get api_v1_announcements_path, headers: auth_headers_for(@staff_user)
    
    assert_response :success
    json_response = JSON.parse(response.body)
    
    announcements = json_response['data']['announcements']
    return if announcements.length < 2
    
    # Check that published dates are in descending order
    dates = announcements.map { |ann| DateTime.parse(ann['published_at']) }
    assert_equal dates.sort.reverse, dates
  end

  # Show Action Tests
  test "should show published announcement to all authenticated users" do
    announcement = @published_announcements.first
    
    [@admin_user, @manager_user, @staff_user, @read_only_user].each do |user|
      mock_current_user(user)
      get api_v1_announcement_path(announcement), headers: auth_headers_for(user)
      
      assert_response :success
      json_response = JSON.parse(response.body)
      
      assert_equal 'success', json_response['status']
      assert_equal announcement.id, json_response['data']['announcement']['id']
    end
  end

  test "should deny draft announcement access to non-admin users" do
    draft = @draft_announcements.first
    
    [@manager_user, @staff_user, @read_only_user].each do |user|
      mock_current_user(user)
      get api_v1_announcement_path(draft), headers: auth_headers_for(user)
      
      assert_response :forbidden
    end
  end

  test "should allow draft announcement access to admin users" do
    draft = @draft_announcements.first
    mock_current_user(@admin_user)
    
    get api_v1_announcement_path(draft), headers: auth_headers_for(@admin_user)
    
    assert_response :success
  end

  test "should return not found for non-existent announcement" do
    mock_current_user(@staff_user)
    
    get api_v1_announcement_path(999999), headers: auth_headers_for(@staff_user)
    
    assert_response :not_found
  end

  # Create Action Tests (Admin only)
  test "should create announcement with admin auth" do
    mock_current_user(@admin_user)
    
    announcement_params = {
      announcement: {
        title: 'New System Update',
        content: 'We will be updating the system next week. Please prepare accordingly.',
        author: @admin_user.name,
        category: 'general',
        priority: 'normal',
        is_published: true
      }
    }
    
    assert_difference('Announcement.count') do
      post api_v1_announcements_path,
           params: announcement_params.to_json,
           headers: auth_headers_for(@admin_user)
    end
    
    assert_response :success
    json_response = JSON.parse(response.body)
    
    assert_equal 'success', json_response['status']
    assert_equal 'New System Update', json_response['data']['announcement']['title']
  end

  test "should create draft announcement" do
    mock_current_user(@admin_user)
    
    draft_params = {
      announcement: {
        title: 'Draft Announcement',
        content: 'This is a draft announcement.',
        author: @admin_user.name,
        category: 'general',
        priority: 'normal',
        is_published: false
      }
    }
    
    assert_difference('Announcement.count') do
      post api_v1_announcements_path,
           params: draft_params.to_json,
           headers: auth_headers_for(@admin_user)
    end
    
    assert_response :success
    json_response = JSON.parse(response.body)
    
    assert_equal false, json_response['data']['announcement']['is_published']
    assert_nil json_response['data']['announcement']['published_at']
  end

  test "should not create announcement with invalid data" do
    mock_current_user(@admin_user)
    
    invalid_params = {
      announcement: {
        title: '',  # Invalid - required
        content: 'Short',  # Invalid - too short
        category: 'invalid_category'  # Invalid - not in list
      }
    }
    
    assert_no_difference('Announcement.count') do
      post api_v1_announcements_path,
           params: invalid_params.to_json,
           headers: auth_headers_for(@admin_user)
    end
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal 'error', json_response['status']
  end

  test "should deny announcement creation for non-admin users" do
    [@manager_user, @staff_user, @read_only_user].each do |user|
      mock_current_user(user)
      
      announcement_params = {
        announcement: attributes_for(:announcement)
      }
      
      assert_no_difference('Announcement.count') do
        post api_v1_announcements_path,
             params: announcement_params.to_json,
             headers: auth_headers_for(user)
      end
      
      assert_response :forbidden
    end
  end

  # Update Action Tests
  test "should update announcement with admin auth" do
    announcement = @published_announcements.first
    mock_current_user(@admin_user)
    
    update_params = {
      announcement: {
        title: 'Updated Announcement Title',
        priority: 'high'
      }
    }
    
    patch api_v1_announcement_path(announcement),
          params: update_params.to_json,
          headers: auth_headers_for(@admin_user)
    
    assert_response :success
    json_response = JSON.parse(response.body)
    
    assert_equal 'Updated Announcement Title', json_response['data']['announcement']['title']
    assert_equal 'high', json_response['data']['announcement']['priority']
  end

  test "should publish draft announcement" do
    draft = @draft_announcements.first
    mock_current_user(@admin_user)
    
    publish_params = {
      announcement: {
        is_published: true
      }
    }
    
    patch api_v1_announcement_path(draft),
          params: publish_params.to_json,
          headers: auth_headers_for(@admin_user)
    
    assert_response :success
    json_response = JSON.parse(response.body)
    
    assert_equal true, json_response['data']['announcement']['is_published']
    assert_not_nil json_response['data']['announcement']['published_at']
  end

  test "should deny announcement update for non-admin users" do
    announcement = @published_announcements.first
    
    [@manager_user, @staff_user, @read_only_user].each do |user|
      mock_current_user(user)
      
      update_params = {
        announcement: { title: 'Unauthorized Update' }
      }
      
      patch api_v1_announcement_path(announcement),
            params: update_params.to_json,
            headers: auth_headers_for(user)
      
      assert_response :forbidden
    end
  end

  # Destroy Action Tests
  test "should destroy announcement with admin auth" do
    announcement = @published_announcements.first
    mock_current_user(@admin_user)
    
    assert_difference('Announcement.count', -1) do
      delete api_v1_announcement_path(announcement),
             headers: auth_headers_for(@admin_user)
    end
    
    assert_response :success
  end

  test "should deny announcement destruction for non-admin users" do
    announcement = @published_announcements.first
    
    [@manager_user, @staff_user, @read_only_user].each do |user|
      mock_current_user(user)
      
      assert_no_difference('Announcement.count') do
        delete api_v1_announcement_path(announcement),
               headers: auth_headers_for(user)
      end
      
      assert_response :forbidden
    end
  end

  # Statistics Tests
  test "should get announcement statistics for admin" do
    mock_current_user(@admin_user)
    get api_v1_announcements_path + '/statistics',
        headers: auth_headers_for(@admin_user)
    
    assert_response :success
    json_response = JSON.parse(response.body)
    
    assert json_response['data']['statistics'].present?
    assert json_response['data']['statistics']['total_announcements'].present?
    assert json_response['data']['statistics']['published_count'].present?
    assert json_response['data']['statistics']['draft_count'].present?
    assert json_response['data']['statistics']['by_category'].present?
    assert json_response['data']['statistics']['by_priority'].present?
  end

  test "should deny statistics access for non-admin users" do
    [@manager_user, @staff_user, @read_only_user].each do |user|
      mock_current_user(user)
      get api_v1_announcements_path + '/statistics',
          headers: auth_headers_for(user)
      
      assert_response :forbidden
    end
  end

  # Bulk Operations Tests
  test "should bulk publish announcements with admin auth" do
    draft_ids = @draft_announcements.map(&:id)
    mock_current_user(@admin_user)
    
    patch api_v1_announcements_path + '/bulk_publish',
          params: { announcement_ids: draft_ids }.to_json,
          headers: auth_headers_for(@admin_user)
    
    assert_response :success
    json_response = JSON.parse(response.body)
    
    assert_equal 'success', json_response['status']
    assert json_response['data']['published_count'] > 0
    
    # Verify announcements were published
    @draft_announcements.each(&:reload)
    assert @draft_announcements.all?(&:is_published)
  end

  # Edge Cases and Error Handling
  test "should handle missing parameters gracefully" do
    mock_current_user(@admin_user)
    
    post api_v1_announcements_path,
         params: {}.to_json,
         headers: auth_headers_for(@admin_user)
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal 'error', json_response['status']
  end

  test "should validate announcement category and priority" do
    mock_current_user(@admin_user)
    
    invalid_params = {
      announcement: {
        title: 'Valid Title',
        content: 'Valid content for the announcement',
        author: @admin_user.name,
        category: 'nonexistent_category',
        priority: 'nonexistent_priority'
      }
    }
    
    post api_v1_announcements_path,
         params: invalid_params.to_json,
         headers: auth_headers_for(@admin_user)
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert json_response['errors'].present?
  end
end
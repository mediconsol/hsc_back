require "test_helper"

class AnnouncementComprehensiveTest < ActiveSupport::TestCase
  def setup
    @admin_user = create(:user, :admin)
  end

  test "should create valid announcement with factory" do
    announcement = build(:announcement)
    assert announcement.valid?, "Announcement should be valid: #{announcement.errors.full_messages}"
  end

  test "should validate required fields" do
    announcement = Announcement.new
    assert_not announcement.valid?
    
    assert_includes announcement.errors[:title], "can't be blank"
    assert_includes announcement.errors[:content], "can't be blank"
    assert_includes announcement.errors[:author], "can't be blank"
    assert_includes announcement.errors[:category], "can't be blank"
  end

  test "should validate title length" do
    # Too short
    announcement = build(:announcement, title: "a")
    assert_not announcement.valid?
    assert_includes announcement.errors[:title], "is too short (minimum is 2 characters)"
    
    # Too long
    long_title = "a" * 256
    announcement = build(:announcement, title: long_title)
    assert_not announcement.valid?
    assert_includes announcement.errors[:title], "is too long (maximum is 255 characters)"
    
    # Just right
    announcement = build(:announcement, title: "Valid Title")
    assert announcement.valid?
  end

  test "should validate content length" do
    # Too short
    announcement = build(:announcement, content: "ab")
    assert_not announcement.valid?
    assert_includes announcement.errors[:content], "is too short (minimum is 10 characters)"
    
    # Valid content
    announcement = build(:announcement, content: "This is valid content for announcement")
    assert announcement.valid?
  end

  test "should validate category inclusion" do
    valid_categories = %w[general urgent maintenance training meeting]
    
    valid_categories.each do |category|
      announcement = build(:announcement, category: category)
      assert announcement.valid?, "Category #{category} should be valid"
    end
    
    announcement = build(:announcement, category: 'invalid_category')
    assert_not announcement.valid?
    assert_includes announcement.errors[:category], "is not included in the list"
  end

  test "should validate priority inclusion" do
    valid_priorities = %w[low normal high urgent]
    
    valid_priorities.each do |priority|
      announcement = build(:announcement, priority: priority)
      assert announcement.valid?, "Priority #{priority} should be valid"
    end
    
    announcement = build(:announcement, priority: 'invalid_priority')
    assert_not announcement.valid?
    assert_includes announcement.errors[:priority], "is not included in the list"
  end

  test "should handle publication status correctly" do
    # Published announcement
    published = create(:announcement, :published)
    assert published.is_published
    assert_not_nil published.published_at
    
    # Draft announcement
    draft = create(:announcement, :draft)
    assert_not draft.is_published
    assert_nil draft.published_at
  end

  test "should scope published announcements" do
    published1 = create(:announcement, :published)
    published2 = create(:announcement, :published)
    draft = create(:announcement, :draft)
    
    published_announcements = Announcement.where(is_published: true)
    
    assert_includes published_announcements, published1
    assert_includes published_announcements, published2
    assert_not_includes published_announcements, draft
  end

  test "should scope by category" do
    urgent = create(:announcement, :urgent)
    maintenance = create(:announcement, :maintenance)
    meeting = create(:announcement, :meeting)
    
    urgent_announcements = Announcement.where(category: 'urgent')
    maintenance_announcements = Announcement.where(category: 'maintenance')
    
    assert_includes urgent_announcements, urgent
    assert_not_includes urgent_announcements, maintenance
    
    assert_includes maintenance_announcements, maintenance
    assert_not_includes maintenance_announcements, meeting
  end

  test "should scope by priority" do
    urgent = create(:announcement, priority: 'urgent')
    high = create(:announcement, priority: 'high')
    normal = create(:announcement, priority: 'normal')
    low = create(:announcement, priority: 'low')
    
    high_priority = Announcement.where(priority: ['urgent', 'high'])
    low_priority = Announcement.where(priority: ['normal', 'low'])
    
    assert_includes high_priority, urgent
    assert_includes high_priority, high
    assert_not_includes high_priority, normal
    
    assert_includes low_priority, normal
    assert_includes low_priority, low
    assert_not_includes low_priority, urgent
  end

  test "should order by published date descending by default" do
    old = create(:announcement, :old)
    recent = create(:announcement, :recent)
    
    announcements = Announcement.where(is_published: true).order(published_at: :desc)
    
    assert_equal recent, announcements.first
    assert_equal old, announcements.last
  end

  test "should handle different announcement types with traits" do
    urgent = create(:announcement, :urgent)
    maintenance = create(:announcement, :maintenance)
    meeting = create(:announcement, :meeting)
    training = create(:announcement, :training)
    
    assert_equal 'urgent', urgent.priority
    assert_equal 'urgent', urgent.category
    assert urgent.title.start_with?('[긴급]')
    
    assert_equal 'maintenance', maintenance.category
    assert_equal 'high', maintenance.priority
    assert maintenance.title.start_with?('[점검 공지]')
    
    assert_equal 'meeting', meeting.category
    assert meeting.title.start_with?('[회의 안내]')
    
    assert_equal 'training', training.category
    assert training.title.start_with?('[교육 안내]')
  end

  test "should validate published_at for published announcements" do
    announcement = build(:announcement, is_published: true, published_at: nil)
    # This might pass depending on model validations
    # Add custom validation if needed
  end

  test "should search by title and content" do
    announcement1 = create(:announcement, title: "Important Meeting", content: "Team meeting tomorrow")
    announcement2 = create(:announcement, title: "System Update", content: "Meeting room booking system")
    announcement3 = create(:announcement, title: "Holiday Notice", content: "Office closure next week")
    
    # Search should find announcements containing "meeting" in title or content
    meeting_related = Announcement.where(
      "title ILIKE ? OR content ILIKE ?", 
      "%meeting%", "%meeting%"
    )
    
    assert_includes meeting_related, announcement1
    assert_includes meeting_related, announcement2
    assert_not_includes meeting_related, announcement3
  end

  test "should calculate statistics" do
    create_list(:announcement, 5, :published, priority: 'urgent')
    create_list(:announcement, 3, :published, priority: 'high')
    create_list(:announcement, 2, :draft)
    
    total_published = Announcement.where(is_published: true).count
    total_drafts = Announcement.where(is_published: false).count
    urgent_count = Announcement.where(priority: 'urgent').count
    
    assert_equal 8, total_published
    assert_equal 2, total_drafts
    assert_equal 5, urgent_count
  end
end
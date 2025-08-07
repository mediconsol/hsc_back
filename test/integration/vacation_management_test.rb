require "test_helper"

class VacationManagementTest < ActionDispatch::IntegrationTest
  def setup
    # Create test data directly in the database to avoid fixture issues
    @admin = User.create!(
      name: "관리자",
      email: "admin@test.com",
      password: "password123",
      role: 0  # admin
    )
    
    @manager = User.create!(
      name: "매니저",
      email: "manager@test.com", 
      password: "password123",
      role: 1  # manager
    )
    
    @employee = Employee.create!(
      name: "김의사",
      department: "의료진",
      position: "주치의",
      employment_type: "full_time",
      hire_date: 2.years.ago,
      phone: "010-1234-5678",
      email: "kim@test.com",
      base_salary: 5000000,
      salary_type: "monthly",
      status: "active"
    )
    
    # Mock authentication for API calls
    @auth_headers = {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
  end

  test "employee annual leave balance calculation" do
    # Test annual leave balance calculation
    balance = @employee.annual_leave_balance
    
    # Employee hired 2 years ago should have 15 + 1 = 16 days
    assert_equal 16, balance
  end

  test "create leave request with valid data" do
    valid_params = {
      employee_id: @employee.id,
      leave_request: {
        leave_type: 'annual',
        start_date: Date.current + 1.week,
        end_date: Date.current + 1.week + 2.days,
        days_requested: 3,
        reason: '가족 여행'
      }
    }

    assert_difference('LeaveRequest.count') do
      post '/api/v1/leave_requests', params: valid_params, headers: @auth_headers
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    
    assert_equal 'success', json_response['status']
    assert_equal '휴가 신청이 완료되었습니다.', json_response['message']
    
    leave_request = LeaveRequest.last
    assert_equal 'annual', leave_request.leave_type
    assert_equal 'pending', leave_request.status
    assert_equal 3, leave_request.days_requested
  end

  test "reject leave request with invalid data" do
    invalid_params = {
      employee_id: @employee.id,
      leave_request: {
        leave_type: '',  # Invalid: empty
        start_date: Date.current + 1.week,
        end_date: Date.current + 1.week - 1.day,  # Invalid: end before start
        days_requested: -1,  # Invalid: negative
        reason: ''  # Invalid: empty
      }
    }

    assert_no_difference('LeaveRequest.count') do
      post '/api/v1/leave_requests', params: invalid_params, headers: @auth_headers
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal 'error', json_response['status']
  end

  test "approve leave request workflow" do
    # Create a leave request
    leave_request = LeaveRequest.create!(
      employee: @employee,
      leave_type: 'annual',
      start_date: Date.current + 1.week,
      end_date: Date.current + 1.week + 2.days,
      days_requested: 3,
      reason: '휴가 신청',
      status: 'pending'
    )

    # Check initial employee balance
    initial_balance = @employee.annual_leave_balance
    
    # Approve the leave request
    patch "/api/v1/leave_requests/#{leave_request.id}/approve", headers: @auth_headers

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
    assert_equal '휴가 신청이 승인되었습니다.', json_response['message']

    # Check that the leave request status changed
    leave_request.reload
    assert_equal 'approved', leave_request.status
    assert_not_nil leave_request.approved_at
    
    # Check that annual leave balance was decreased
    @employee.reload
    updated_balance = @employee.annual_leave_balance
    assert_equal initial_balance - 3, updated_balance
  end

  test "reject leave request workflow" do
    # Create a leave request
    leave_request = LeaveRequest.create!(
      employee: @employee,
      leave_type: 'annual',
      start_date: Date.current + 1.week,
      end_date: Date.current + 1.week + 2.days,
      days_requested: 3,
      reason: '휴가 신청',
      status: 'pending'
    )

    rejection_params = { rejection_reason: '업무 일정상 불가능' }
    
    # Reject the leave request
    patch "/api/v1/leave_requests/#{leave_request.id}/reject", params: rejection_params, headers: @auth_headers

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
    assert_equal '휴가 신청이 반려되었습니다.', json_response['message']

    # Check that the leave request status changed
    leave_request.reload
    assert_equal 'rejected', leave_request.status
    assert_equal '업무 일정상 불가능', leave_request.rejection_reason
    assert_not_nil leave_request.rejected_at
  end

  test "cancel leave request" do
    # Create a future leave request
    leave_request = LeaveRequest.create!(
      employee: @employee,
      leave_type: 'annual',
      start_date: Date.current + 1.week,
      end_date: Date.current + 1.week + 2.days,
      days_requested: 3,
      reason: '휴가 신청',
      status: 'pending'
    )

    # Cancel the leave request
    patch "/api/v1/leave_requests/#{leave_request.id}/cancel", headers: @auth_headers

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
    assert_equal '휴가 신청이 취소되었습니다.', json_response['message']

    # Check that the leave request status changed
    leave_request.reload
    assert_equal 'cancelled', leave_request.status
  end

  test "cannot cancel leave request that already started" do
    # Create a leave request that already started
    leave_request = LeaveRequest.create!(
      employee: @employee,
      leave_type: 'annual',
      start_date: Date.current - 1.day,  # Started yesterday
      end_date: Date.current + 1.day,
      days_requested: 3,
      reason: '휴가 신청',
      status: 'approved'
    )

    # Try to cancel the leave request
    patch "/api/v1/leave_requests/#{leave_request.id}/cancel", headers: @auth_headers

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal 'error', json_response['status']
    assert_equal '취소할 수 없는 상태입니다.', json_response['message']
  end

  test "get pending approvals" do
    # Create some leave requests
    pending_request = LeaveRequest.create!(
      employee: @employee,
      leave_type: 'annual',
      start_date: Date.current + 1.week,
      end_date: Date.current + 1.week + 2.days,
      days_requested: 3,
      reason: '휴가 신청',
      status: 'pending'
    )

    get '/api/v1/leave_requests/pending_approvals', headers: @auth_headers

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
    assert json_response['data']['pending_requests'].is_a?(Array)
    assert json_response['data']['count'] >= 1
  end

  test "get statistics" do
    # Create some leave requests for statistics
    LeaveRequest.create!(
      employee: @employee,
      leave_type: 'annual',
      start_date: Date.current.beginning_of_year + 1.month,
      end_date: Date.current.beginning_of_year + 1.month + 2.days,
      days_requested: 3,
      reason: '휴가 신청',
      status: 'approved'
    )

    get '/api/v1/leave_requests/statistics', headers: @auth_headers

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
    
    stats = json_response['data']
    assert stats['total_requests'].is_a?(Integer)
    assert stats['approved_requests'].is_a?(Integer)
    assert stats['pending_requests'].is_a?(Integer)
    assert stats['leave_type_breakdown'].is_a?(Array)
  end

  test "get annual leave status for employee" do
    get "/api/v1/leave_requests/annual_leave_status?employee_id=#{@employee.id}", headers: @auth_headers

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
    
    data = json_response['data']
    assert_equal @employee.id, data['employee_id']
    assert_equal @employee.name, data['employee_name']
    assert data['total_annual_leave'].is_a?(Integer)
    assert data['used_annual_leave'].is_a?(Integer)
    assert data['remaining_annual_leave'].is_a?(Integer)
  end

  test "leave request validation rules" do
    # Test end date before start date
    invalid_request = LeaveRequest.new(
      employee: @employee,
      leave_type: 'annual',
      start_date: Date.current + 1.week,
      end_date: Date.current + 1.week - 1.day,  # End before start
      days_requested: 3,
      reason: '휴가 신청',
      status: 'pending'
    )
    
    assert_not invalid_request.valid?
    assert_includes invalid_request.errors[:end_date], '종료일은 시작일보다 늦어야 합니다'
  end

  test "annual leave balance validation" do
    # Mock insufficient balance
    @employee.stubs(:annual_leave_balance).returns(2)
    
    insufficient_request = LeaveRequest.new(
      employee: @employee,
      leave_type: 'annual',
      start_date: Date.current + 1.week,
      end_date: Date.current + 1.week + 4.days,
      days_requested: 5,  # More than available
      reason: '휴가 신청',
      status: 'pending'
    )
    
    assert_not insufficient_request.valid?
    assert_includes insufficient_request.errors[:days_requested], '잔여 연차가 부족합니다 (잔여: 2일)'
  end

  private

  def teardown
    # Clean up test data
    LeaveRequest.delete_all
    Employee.delete_all  
    User.delete_all
  end
end
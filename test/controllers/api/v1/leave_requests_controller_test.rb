require "test_helper"

class Api::V1::LeaveRequestsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @employee = employees(:kim_doctor)
    @manager = users(:manager_user)
    @admin = users(:admin_user)
    @leave_request = leave_requests(:pending_annual_leave)
    
    # Mock authentication
    @current_user = @admin
  end

  test "should get index" do
    get api_v1_leave_requests_url, headers: auth_headers
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
    assert json_response['data']['leave_requests'].is_a?(Array)
    assert json_response['data']['summary'].is_a?(Hash)
  end

  test "should get index with employee filter" do
    get api_v1_leave_requests_url(employee_id: @employee.id), headers: auth_headers
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
    
    # All returned leave requests should belong to the specified employee
    json_response['data']['leave_requests'].each do |lr|
      assert_equal @employee.id, lr['employee_id']
    end
  end

  test "should get index with status filter" do
    get api_v1_leave_requests_url(status: 'pending'), headers: auth_headers
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
    
    # All returned leave requests should have pending status
    json_response['data']['leave_requests'].each do |lr|
      assert_equal 'pending', lr['status']
    end
  end

  test "should get index with date range filter" do
    start_date = '2025-08-01'
    end_date = '2025-08-31'
    
    get api_v1_leave_requests_url(start_date: start_date, end_date: end_date), headers: auth_headers
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
  end

  test "should show leave request" do
    get api_v1_leave_request_url(@leave_request), headers: auth_headers
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
    assert_equal @leave_request.id, json_response['data']['leave_request']['id']
  end

  test "should create leave request with valid data" do
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
      post api_v1_leave_requests_url, params: valid_params, headers: auth_headers
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
    assert_equal '휴가 신청이 완료되었습니다.', json_response['message']
  end

  test "should not create leave request with invalid data" do
    invalid_params = {
      employee_id: @employee.id,
      leave_request: {
        leave_type: '',  # Invalid: empty leave type
        start_date: Date.current + 1.week,
        end_date: Date.current + 1.week - 1.day,  # Invalid: end before start
        days_requested: -1,  # Invalid: negative days
        reason: ''  # Invalid: empty reason
      }
    }

    assert_no_difference('LeaveRequest.count') do
      post api_v1_leave_requests_url, params: invalid_params, headers: auth_headers
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal 'error', json_response['status']
  end

  test "should not create annual leave request with insufficient balance" do
    # Mock insufficient balance
    @employee.stubs(:annual_leave_balance).returns(1)
    
    insufficient_params = {
      employee_id: @employee.id,
      leave_request: {
        leave_type: 'annual',
        start_date: Date.current + 1.week,
        end_date: Date.current + 1.week + 4.days,
        days_requested: 5,  # More than available balance
        reason: '휴가 신청'
      }
    }

    assert_no_difference('LeaveRequest.count') do
      post api_v1_leave_requests_url, params: insufficient_params, headers: auth_headers
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response['message'], '잔여 연차가 부족합니다'
  end

  test "should update leave request" do
    update_params = {
      leave_request: {
        reason: '수정된 사유'
      }
    }

    patch api_v1_leave_request_url(@leave_request), params: update_params, headers: auth_headers
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
    assert_equal '휴가 신청이 수정되었습니다.', json_response['message']
    
    @leave_request.reload
    assert_equal '수정된 사유', @leave_request.reason
  end

  test "should destroy leave request" do
    assert_difference('LeaveRequest.count', -1) do
      delete api_v1_leave_request_url(@leave_request), headers: auth_headers
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
    assert_equal '휴가 신청이 삭제되었습니다.', json_response['message']
  end

  test "should approve pending leave request" do
    patch approve_api_v1_leave_request_url(@leave_request), headers: auth_headers
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
    assert_equal '휴가 신청이 승인되었습니다.', json_response['message']
    
    @leave_request.reload
    assert_equal 'approved', @leave_request.status
    assert_equal @current_user, @leave_request.approver
    assert_not_nil @leave_request.approved_at
  end

  test "should not approve already processed leave request" do
    @leave_request.update!(status: 'approved')\n    
    patch approve_api_v1_leave_request_url(@leave_request), headers: auth_headers
    assert_response :unprocessable_entity
    
    json_response = JSON.parse(response.body)
    assert_equal 'error', json_response['status']
    assert_equal '이미 처리된 신청입니다.', json_response['message']
  end

  test "should reject pending leave request" do
    rejection_params = {
      rejection_reason: '업무 일정상 불가'
    }
    
    patch reject_api_v1_leave_request_url(@leave_request), params: rejection_params, headers: auth_headers
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
    assert_equal '휴가 신청이 반려되었습니다.', json_response['message']
    
    @leave_request.reload
    assert_equal 'rejected', @leave_request.status
    assert_equal @current_user, @leave_request.approver
    assert_not_nil @leave_request.rejected_at
    assert_equal '업무 일정상 불가', @leave_request.rejection_reason
  end

  test "should cancel own leave request" do
    # Set leave request to be in the future and pending
    @leave_request.update!(start_date: Date.current + 1.week, status: 'pending')
    
    patch cancel_api_v1_leave_request_url(@leave_request), headers: auth_headers
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
    assert_equal '휴가 신청이 취소되었습니다.', json_response['message']
    
    @leave_request.reload
    assert_equal 'cancelled', @leave_request.status
  end

  test "should not cancel leave request that cannot be cancelled" do
    # Set leave request to be in the past or approved
    @leave_request.update!(start_date: Date.current - 1.day, status: 'pending')
    
    patch cancel_api_v1_leave_request_url(@leave_request), headers: auth_headers
    assert_response :unprocessable_entity
    
    json_response = JSON.parse(response.body)
    assert_equal 'error', json_response['status']
    assert_equal '취소할 수 없는 상태입니다.', json_response['message']
  end

  test "should get pending approvals" do
    get pending_approvals_api_v1_leave_requests_url, headers: auth_headers
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
    assert json_response['data']['pending_requests'].is_a?(Array)
    assert json_response['data']['count'].is_a?(Integer)
  end

  test "should get statistics" do
    get statistics_api_v1_leave_requests_url, headers: auth_headers
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
    
    stats = json_response['data']
    assert stats['total_requests'].is_a?(Integer)
    assert stats['approved_requests'].is_a?(Integer)
    assert stats['pending_requests'].is_a?(Integer)
    assert stats['rejected_requests'].is_a?(Integer)
    assert stats['leave_type_breakdown'].is_a?(Array)
    assert stats['monthly_breakdown'].is_a?(Array)
  end

  test "should get statistics with year filter" do
    get statistics_api_v1_leave_requests_url(year: 2025), headers: auth_headers
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
    assert_equal 2025, json_response['data']['year']
  end

  test "should get statistics with employee filter" do
    get statistics_api_v1_leave_requests_url(employee_id: @employee.id), headers: auth_headers
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
  end

  test "should get annual leave status for specific employee" do
    get annual_leave_status_api_v1_leave_requests_url(employee_id: @employee.id), headers: auth_headers
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

  test "should get annual leave status for all employees" do
    get annual_leave_status_api_v1_leave_requests_url, headers: auth_headers
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
    
    data = json_response['data']
    assert data['employees'].is_a?(Array)
    assert data['summary'].is_a?(Hash)
    assert data['summary']['total_employees'].is_a?(Integer)
  end

  private

  def auth_headers
    # Mock authentication headers
    # In a real implementation, this would include JWT tokens or session data
    {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
  end
end
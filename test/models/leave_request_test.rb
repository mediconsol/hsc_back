require "test_helper"

class LeaveRequestTest < ActiveSupport::TestCase
  # Disable fixtures for this test to avoid foreign key issues during development
  # self.use_transactional_tests = true
  fixtures :users, :employees, :leave_requests
  def setup
    @employee = employees(:kim_doctor)
    @approver = users(:manager_user)
    @valid_attributes = {
      employee: @employee,
      leave_type: 'annual',
      start_date: Date.current + 1.week,
      end_date: Date.current + 1.week + 2.days,
      days_requested: 3,
      reason: '가족 여행',
      status: 'pending'
    }
  end

  test "should be valid with valid attributes" do
    leave_request = LeaveRequest.new(@valid_attributes)
    assert leave_request.valid?
  end

  test "should require leave_type" do
    leave_request = LeaveRequest.new(@valid_attributes.except(:leave_type))
    assert_not leave_request.valid?
    assert_includes leave_request.errors[:leave_type], "can't be blank"
  end

  test "should require start_date" do
    leave_request = LeaveRequest.new(@valid_attributes.except(:start_date))
    assert_not leave_request.valid?
    assert_includes leave_request.errors[:start_date], "can't be blank"
  end

  test "should require end_date" do
    leave_request = LeaveRequest.new(@valid_attributes.except(:end_date))
    assert_not leave_request.valid?
    assert_includes leave_request.errors[:end_date], "can't be blank"
  end

  test "should require days_requested" do
    leave_request = LeaveRequest.new(@valid_attributes.except(:days_requested))
    assert_not leave_request.valid?
    assert_includes leave_request.errors[:days_requested], "can't be blank"
  end

  test "should require days_requested to be greater than 0" do
    leave_request = LeaveRequest.new(@valid_attributes.merge(days_requested: 0))
    assert_not leave_request.valid?
    assert_includes leave_request.errors[:days_requested], "must be greater than 0"
  end

  test "should require reason" do
    leave_request = LeaveRequest.new(@valid_attributes.except(:reason))
    assert_not leave_request.valid?
    assert_includes leave_request.errors[:reason], "can't be blank"
  end

  test "should require status" do
    leave_request = LeaveRequest.new(@valid_attributes.except(:status))
    assert_not leave_request.valid?
    assert_includes leave_request.errors[:status], "can't be blank"
  end

  test "should validate end_date after start_date" do
    leave_request = LeaveRequest.new(@valid_attributes.merge(
      start_date: Date.current + 1.week,
      end_date: Date.current + 1.week - 1.day
    ))
    assert_not leave_request.valid?
    assert_includes leave_request.errors[:end_date], "종료일은 시작일보다 늦어야 합니다"
  end

  test "should validate sufficient leave balance for annual leave" do
    # Mock the employee's annual leave balance to be less than requested
    @employee.stubs(:annual_leave_balance).returns(2)
    leave_request = LeaveRequest.new(@valid_attributes.merge(days_requested: 3))
    assert_not leave_request.valid?
    assert_includes leave_request.errors[:days_requested], "잔여 연차가 부족합니다 (잔여: 2일)"
  end

  test "should not validate leave balance for non-annual leave" do
    @employee.stubs(:annual_leave_balance).returns(0)
    leave_request = LeaveRequest.new(@valid_attributes.merge(
      leave_type: 'sick',
      days_requested: 5
    ))
    assert leave_request.valid?
  end

  test "should have correct leave_type_text" do
    leave_request = LeaveRequest.new(leave_type: 'annual')
    assert_equal '연차', leave_request.leave_type_text
    
    leave_request = LeaveRequest.new(leave_type: 'sick')
    assert_equal '병가', leave_request.leave_type_text
  end

  test "should have correct status_text" do
    leave_request = LeaveRequest.new(status: 'pending')
    assert_equal '승인대기', leave_request.status_text
    
    leave_request = LeaveRequest.new(status: 'approved')
    assert_equal '승인', leave_request.status_text
  end

  test "should have correct status_color" do
    leave_request = LeaveRequest.new(status: 'pending')
    assert_equal 'text-yellow-600 bg-yellow-100', leave_request.status_color
    
    leave_request = LeaveRequest.new(status: 'approved')
    assert_equal 'text-green-600 bg-green-100', leave_request.status_color
  end

  test "annual_leave? should return true for annual leave" do
    leave_request = LeaveRequest.new(leave_type: 'annual')
    assert leave_request.annual_leave?
    
    leave_request = LeaveRequest.new(leave_type: 'sick')
    assert_not leave_request.annual_leave?
  end

  test "can_cancel? should return true for pending leave in future" do
    leave_request = LeaveRequest.new(
      status: 'pending',
      start_date: Date.current + 1.day
    )
    assert leave_request.can_cancel?
    
    # Should not be able to cancel approved leave
    leave_request = LeaveRequest.new(
      status: 'approved',
      start_date: Date.current + 1.day
    )
    assert_not leave_request.can_cancel?
    
    # Should not be able to cancel leave that already started
    leave_request = LeaveRequest.new(
      status: 'pending',
      start_date: Date.current - 1.day
    )
    assert_not leave_request.can_cancel?
  end

  test "can_approve? should return true for pending leave by approver or admin" do
    leave_request = LeaveRequest.new(
      status: 'pending',
      approver: @approver
    )
    
    # Approver should be able to approve
    assert leave_request.can_approve?(@approver)
    
    # Admin should be able to approve
    admin = users(:admin_user)
    assert leave_request.can_approve?(admin)
    
    # Other users should not be able to approve
    other_user = users(:staff_user)
    assert_not leave_request.can_approve?(other_user)
    
    # Should not be able to approve non-pending leave
    leave_request.status = 'approved'
    assert_not leave_request.can_approve?(@approver)
  end

  test "scopes should work correctly" do
    # Test by_employee scope
    employee_requests = LeaveRequest.by_employee(@employee)
    assert_includes employee_requests, leave_requests(:pending_annual_leave)
    
    # Test by_status scope
    pending_requests = LeaveRequest.by_status('pending')
    assert_includes pending_requests, leave_requests(:pending_annual_leave)
    
    # Test pending_approval scope
    pending_approvals = LeaveRequest.pending_approval
    assert_includes pending_approvals, leave_requests(:pending_annual_leave)
  end
end

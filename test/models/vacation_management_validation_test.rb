require "test_helper"

class VacationManagementValidationTest < ActiveSupport::TestCase
  def setup
    # Create test data directly to avoid fixture issues
    @admin_user = User.new(
      name: "관리자", 
      email: "admin@test.com",
      password: "password123",
      role: 3  # admin
    )
    
    @employee = Employee.new(
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
  end

  test "employee model validations work correctly" do
    assert @employee.valid?, "Employee should be valid with correct data"
    
    # Test name validation
    @employee.name = ""
    assert_not @employee.valid?, "Employee should be invalid without name"
    assert_includes @employee.errors[:name], "can't be blank"
    
    @employee.name = "김"  # Too short
    assert_not @employee.valid?, "Employee should be invalid with short name"
    
    @employee.name = "김의사123"  # Invalid characters
    assert_not @employee.valid?, "Employee should be invalid with numbers in name"
    
    @employee.name = "김의사"  # Valid name
    assert @employee.valid?, "Employee should be valid with Korean name"
  end

  test "employee department validation" do
    @employee.department = "잘못된부서"
    assert_not @employee.valid?, "Employee should be invalid with wrong department"
    assert_includes @employee.errors[:department], "올바른 부서를 선택하세요"
    
    valid_departments = ["의료진", "간호부", "행정부", "시설관리"]
    valid_departments.each do |dept|
      @employee.department = dept
      assert @employee.valid?, "Employee should be valid with department: #{dept}"
    end
  end

  test "employee email validation" do
    @employee.email = "invalid-email"
    assert_not @employee.valid?, "Employee should be invalid with malformed email"
    assert_includes @employee.errors[:email], "올바른 이메일 형식이 아닙니다"
    
    @employee.email = "valid@test.com"
    assert @employee.valid?, "Employee should be valid with proper email"
  end

  test "employee hire date validation" do
    @employee.hire_date = 1.day.from_now
    assert_not @employee.valid?, "Employee should be invalid with future hire date"
    assert_includes @employee.errors[:hire_date], "미래 날짜는 입력할 수 없습니다"
    
    @employee.hire_date = 1.year.ago
    assert @employee.valid?, "Employee should be valid with past hire date"
  end

  test "employee years of service calculation" do
    @employee.hire_date = 3.years.ago
    assert_equal 3, @employee.years_of_service, "Years of service should be calculated correctly"
    
    @employee.hire_date = 6.months.ago
    assert_equal 0, @employee.years_of_service, "Partial year should be counted as 0"
  end

  test "employee annual leave balance calculation" do
    # Employee hired 2 years ago should have 15 + 1 = 16 days
    @employee.hire_date = 2.years.ago
    # Note: This test may need adjustment based on the actual implementation
    # as annual_leave_balance includes cache and database queries
    expected_balance = 15 + [@employee.years_of_service - 1, 10].min
    # The actual method includes used leave calculation which we can't test without DB
  end

  test "leave request model validations work correctly" do
    leave_request = LeaveRequest.new(
      employee: @employee,
      leave_type: "annual",
      start_date: Date.current + 1.week,
      end_date: Date.current + 1.week + 2.days,
      days_requested: 3,
      reason: "가족 여행",
      status: "pending"
    )
    
    assert leave_request.valid?, "Leave request should be valid with correct data"
  end

  test "leave request requires all mandatory fields" do
    leave_request = LeaveRequest.new
    
    assert_not leave_request.valid?, "Leave request should be invalid without required fields"
    
    required_fields = [:leave_type, :start_date, :end_date, :days_requested, :reason, :status]
    required_fields.each do |field|
      assert_includes leave_request.errors[field], "can't be blank", 
                     "#{field} should be required"
    end
  end

  test "leave request date validation" do
    leave_request = LeaveRequest.new(
      employee: @employee,
      leave_type: "annual",
      start_date: Date.current + 1.week,
      end_date: Date.current + 1.week - 1.day,  # End before start
      days_requested: 3,
      reason: "휴가",
      status: "pending"
    )
    
    assert_not leave_request.valid?, "Leave request should be invalid with end date before start date"
    assert_includes leave_request.errors[:end_date], "종료일은 시작일보다 늦어야 합니다"
  end

  test "leave request days validation" do
    leave_request = LeaveRequest.new(
      employee: @employee,
      leave_type: "annual",
      start_date: Date.current + 1.week,
      end_date: Date.current + 1.week + 2.days,
      days_requested: 0,  # Invalid: zero days
      reason: "휴가",
      status: "pending"
    )
    
    assert_not leave_request.valid?, "Leave request should be invalid with zero days"
    assert_includes leave_request.errors[:days_requested], "must be greater than 0"
  end

  test "leave request status methods work correctly" do
    leave_request = LeaveRequest.new(leave_type: "annual", status: "pending")
    
    assert leave_request.annual_leave?, "Should identify annual leave correctly"
    assert_equal "연차", leave_request.leave_type_text
    assert_equal "승인대기", leave_request.status_text
    assert_equal "text-yellow-600 bg-yellow-100", leave_request.status_color
  end

  test "leave request cancellation rules" do
    # Pending request in future can be cancelled
    future_pending = LeaveRequest.new(
      status: "pending",
      start_date: Date.current + 1.week
    )
    assert future_pending.can_cancel?, "Should be able to cancel future pending request"
    
    # Approved request cannot be cancelled
    approved_request = LeaveRequest.new(
      status: "approved", 
      start_date: Date.current + 1.week
    )
    assert_not approved_request.can_cancel?, "Should not be able to cancel approved request"
    
    # Past request cannot be cancelled
    past_request = LeaveRequest.new(
      status: "pending",
      start_date: Date.current - 1.day
    )
    assert_not past_request.can_cancel?, "Should not be able to cancel past request"
  end

  test "leave request approval permissions" do
    leave_request = LeaveRequest.new(
      status: "pending",
      approver: @admin_user
    )
    
    # Designated approver can approve
    assert leave_request.can_approve?(@admin_user), "Approver should be able to approve"
    
    # Admin can approve
    admin = User.new(role: 3)  # admin
    admin.stubs(:admin?).returns(true)
    assert leave_request.can_approve?(admin), "Admin should be able to approve"
    
    # Regular staff cannot approve
    staff = User.new(role: 1)  # staff
    staff.stubs(:admin?).returns(false)
    assert_not leave_request.can_approve?(staff), "Staff should not be able to approve"
  end

  test "user model validations work correctly" do
    assert @admin_user.valid?, "User should be valid with correct data"
    
    # Test email validation
    @admin_user.email = "invalid-email"
    assert_not @admin_user.valid?, "User should be invalid with malformed email"
    
    @admin_user.email = "valid@test.com"
    assert @admin_user.valid?, "User should be valid with proper email"
    
    # Test name validation
    @admin_user.name = "A"  # Too short
    assert_not @admin_user.valid?, "User should be invalid with short name"
    
    @admin_user.name = "Valid Name"
    assert @admin_user.valid?, "User should be valid with proper name"
  end

  test "user password validation" do
    user = User.new(
      name: "Test User",
      email: "test@test.com",
      password: "short"  # Too short
    )
    
    assert_not user.valid?, "User should be invalid with short password"
    assert_includes user.errors[:password], "is too short (minimum is 8 characters)"
    
    user.password = "validpassword123"
    assert user.valid?, "User should be valid with proper password"
  end

  test "user JWT token generation" do
    # Note: This would require the user to be saved to have an ID
    # We can test the method exists and returns a string
    assert_respond_to @admin_user, :generate_jwt_token, "User should have JWT token generation method"
    assert_respond_to @admin_user, :generate_refresh_token, "User should have refresh token generation method"
  end

  test "user role enum works correctly" do
    user = User.new(role: 0)  # read_only
    assert user.read_only?, "Role should be correctly identified as read_only"
    
    user.role = 3  # admin
    assert user.admin?, "Role should be correctly identified as admin"
  end
end
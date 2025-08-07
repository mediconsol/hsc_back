require "test_helper"

class AttendanceComprehensiveTest < ActiveSupport::TestCase
  def setup
    @employee = create(:employee, :doctor)
    @admin_user = create(:user, :admin)
  end

  test "should create valid attendance with factory" do
    attendance = build(:attendance, employee: @employee)
    assert attendance.valid?, "Attendance should be valid: #{attendance.errors.full_messages}"
  end

  test "should validate required fields" do
    attendance = Attendance.new
    assert_not attendance.valid?
    
    assert_includes attendance.errors[:employee], "must exist"
    assert_includes attendance.errors[:work_date], "can't be blank"
    assert_includes attendance.errors[:status], "can't be blank"
  end

  test "should validate work date not in future" do
    attendance = build(:attendance, employee: @employee, work_date: 1.day.from_now)
    assert_not attendance.valid?
    assert_includes attendance.errors[:work_date], "cannot be in the future"
  end

  test "should validate check times consistency" do
    attendance = build(:attendance, employee: @employee)
    attendance.check_in = Time.current
    attendance.check_out = Time.current - 1.hour
    
    assert_not attendance.valid?
    assert_includes attendance.errors[:check_out], "must be after check in time"
  end

  test "should calculate regular hours correctly" do
    attendance = create(:attendance, :present, employee: @employee)
    attendance.update!(
      check_in: attendance.work_date.beginning_of_day + 9.hours,
      check_out: attendance.work_date.beginning_of_day + 17.hours
    )
    
    assert_equal 8.0, attendance.regular_hours
  end

  test "should calculate overtime hours correctly" do
    attendance = create(:attendance, :with_overtime, employee: @employee)
    attendance.update!(
      check_in: attendance.work_date.beginning_of_day + 9.hours,
      check_out: attendance.work_date.beginning_of_day + 19.hours
    )
    
    assert_equal 8.0, attendance.regular_hours
    assert_equal 2.0, attendance.overtime_hours
  end

  test "should handle absent status correctly" do
    attendance = create(:attendance, :absent, employee: @employee)
    
    assert_equal 'absent', attendance.status
    assert_nil attendance.check_in
    assert_nil attendance.check_out
    assert_equal 0, attendance.regular_hours
    assert_equal 0, attendance.overtime_hours
  end

  test "should validate status inclusion" do
    attendance = build(:attendance, employee: @employee, status: 'invalid_status')
    assert_not attendance.valid?
    assert_includes attendance.errors[:status], "is not included in the list"
  end

  test "should have unique attendance per employee per day" do
    create(:attendance, employee: @employee, work_date: Date.current)
    
    duplicate = build(:attendance, employee: @employee, work_date: Date.current)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:work_date], "has already been taken"
  end

  test "should scope by date range" do
    # Create attendances for different dates
    yesterday = create(:attendance, employee: @employee, work_date: Date.current - 1.day)
    today = create(:attendance, employee: @employee, work_date: Date.current)
    tomorrow = create(:attendance, employee: @employee, work_date: Date.current + 1.day)
    
    week_attendances = Attendance.where(work_date: Date.current.beginning_of_week..Date.current.end_of_week)
    assert_includes week_attendances, yesterday
    assert_includes week_attendances, today
    # tomorrow might not be in this week depending on the day
  end

  test "should scope by employee" do
    other_employee = create(:employee, :nurse)
    
    attendance1 = create(:attendance, employee: @employee)
    attendance2 = create(:attendance, employee: other_employee)
    
    employee_attendances = Attendance.where(employee: @employee)
    assert_includes employee_attendances, attendance1
    assert_not_includes employee_attendances, attendance2
  end

  test "should calculate monthly statistics" do
    # Create 20 working days for current month
    work_days = 20
    work_days.times do |i|
      create(:attendance, :present, 
        employee: @employee,
        work_date: Date.current.beginning_of_month + i.days,
        regular_hours: 8.0,
        overtime_hours: rand(0..4)
      )
    end
    
    monthly_attendances = Attendance.where(
      employee: @employee,
      work_date: Date.current.beginning_of_month..Date.current.end_of_month
    )
    
    assert_equal work_days, monthly_attendances.count
    
    total_regular = monthly_attendances.sum(:regular_hours)
    total_overtime = monthly_attendances.sum(:overtime_hours)
    
    assert_equal 160.0, total_regular # 20 days * 8 hours
    assert total_overtime >= 0
  end

  test "should handle different attendance statuses" do
    present = create(:attendance, :present, employee: @employee)
    absent = create(:attendance, :absent, employee: @employee, work_date: Date.current - 1.day)
    late = create(:attendance, :late, employee: @employee, work_date: Date.current - 2.days)
    early_leave = create(:attendance, :early_leave, employee: @employee, work_date: Date.current - 3.days)
    
    assert_equal 'present', present.status
    assert_equal 'absent', absent.status
    assert_equal 'late', late.status
    assert_equal 'early_leave', early_leave.status
    
    # Verify appropriate hours for each status
    assert present.regular_hours > 0
    assert_equal 0, absent.regular_hours
    assert late.regular_hours > 0
    assert early_leave.regular_hours < 8.0
  end
end
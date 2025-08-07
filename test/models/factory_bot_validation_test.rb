require "test_helper"

class FactoryBotValidationTest < ActiveSupport::TestCase
  test "user factory should be valid" do
    user = build(:user)
    assert user.valid?, "User factory should create valid user: #{user.errors.full_messages}"
  end

  test "user factory with traits should be valid" do
    admin = build(:user, :admin)
    manager = build(:user, :manager)
    staff = build(:user, :staff)
    read_only = build(:user, :read_only)
    
    assert admin.valid?, "Admin user should be valid: #{admin.errors.full_messages}"
    assert manager.valid?, "Manager user should be valid: #{manager.errors.full_messages}"
    assert staff.valid?, "Staff user should be valid: #{staff.errors.full_messages}"
    assert read_only.valid?, "Read only user should be valid: #{read_only.errors.full_messages}"
    
    assert_equal 3, admin.role, "Admin should have role 3"
    assert_equal 2, manager.role, "Manager should have role 2"
    assert_equal 1, staff.role, "Staff should have role 1"
    assert_equal 0, read_only.role, "Read only should have role 0"
  end

  test "employee factory should be valid" do
    employee = build(:employee)
    assert employee.valid?, "Employee factory should create valid employee: #{employee.errors.full_messages}"
  end

  test "employee factory with traits should be valid" do
    doctor = build(:employee, :doctor)
    nurse = build(:employee, :nurse)
    admin_staff = build(:employee, :admin_staff)
    facility_staff = build(:employee, :facility_staff)
    part_time = build(:employee, :part_time)
    
    assert doctor.valid?, "Doctor should be valid: #{doctor.errors.full_messages}"
    assert nurse.valid?, "Nurse should be valid: #{nurse.errors.full_messages}"
    assert admin_staff.valid?, "Admin staff should be valid: #{admin_staff.errors.full_messages}"
    assert facility_staff.valid?, "Facility staff should be valid: #{facility_staff.errors.full_messages}"
    assert part_time.valid?, "Part time should be valid: #{part_time.errors.full_messages}"
    
    assert_equal '의료진', doctor.department, "Doctor should be in medical department"
    assert_equal '간호부', nurse.department, "Nurse should be in nursing department"
    assert_equal 'hourly', part_time.salary_type, "Part time should have hourly salary type"
  end

  test "leave request factory should be valid" do
    employee = create(:employee)
    approver = create(:user, :manager)
    leave_request = build(:leave_request, employee: employee, approver: approver)
    
    assert leave_request.valid?, "Leave request factory should create valid leave request: #{leave_request.errors.full_messages}"
  end

  test "leave request factory with traits should be valid" do
    employee = create(:employee)
    approver = create(:user, :admin)
    
    annual = build(:leave_request, :annual, employee: employee, approver: approver)
    sick = build(:leave_request, :sick, employee: employee, approver: approver)
    approved = build(:leave_request, :approved, employee: employee, approver: approver)
    rejected = build(:leave_request, :rejected, employee: employee, approver: approver)
    
    assert annual.valid?, "Annual leave should be valid: #{annual.errors.full_messages}"
    assert sick.valid?, "Sick leave should be valid: #{sick.errors.full_messages}"
    assert approved.valid?, "Approved leave should be valid: #{approved.errors.full_messages}"
    assert rejected.valid?, "Rejected leave should be valid: #{rejected.errors.full_messages}"
    
    assert_equal 'annual', annual.leave_type, "Annual leave should have correct type"
    assert_equal 'sick', sick.leave_type, "Sick leave should have correct type"
    assert_equal 'approved', approved.status, "Approved leave should have correct status"
    assert_equal 'rejected', rejected.status, "Rejected leave should have correct status"
  end

  test "attendance factory should be valid" do
    employee = create(:employee)
    attendance = build(:attendance, employee: employee)
    
    assert attendance.valid?, "Attendance factory should create valid attendance: #{attendance.errors.full_messages}"
  end

  test "attendance factory with traits should be valid" do
    employee = create(:employee)
    
    present = build(:attendance, :present, employee: employee)
    absent = build(:attendance, :absent, employee: employee)
    late = build(:attendance, :late, employee: employee)
    with_overtime = build(:attendance, :with_overtime, employee: employee)
    
    assert present.valid?, "Present attendance should be valid: #{present.errors.full_messages}"
    assert absent.valid?, "Absent attendance should be valid: #{absent.errors.full_messages}"
    assert late.valid?, "Late attendance should be valid: #{late.errors.full_messages}"
    assert with_overtime.valid?, "Overtime attendance should be valid: #{with_overtime.errors.full_messages}"
    
    assert_equal 'present', present.status, "Present should have correct status"
    assert_equal 'absent', absent.status, "Absent should have correct status"
    assert_equal 'late', late.status, "Late should have correct status"
    assert with_overtime.overtime_hours > 0, "Overtime should have overtime hours"
  end

  test "announcement factory should be valid" do
    announcement = build(:announcement)
    assert announcement.valid?, "Announcement factory should create valid announcement: #{announcement.errors.full_messages}"
  end

  test "announcement factory with traits should be valid" do
    urgent = build(:announcement, :urgent)
    maintenance = build(:announcement, :maintenance)
    draft = build(:announcement, :draft)
    published = build(:announcement, :published)
    
    assert urgent.valid?, "Urgent announcement should be valid: #{urgent.errors.full_messages}"
    assert maintenance.valid?, "Maintenance announcement should be valid: #{maintenance.errors.full_messages}"
    assert draft.valid?, "Draft announcement should be valid: #{draft.errors.full_messages}"
    assert published.valid?, "Published announcement should be valid: #{published.errors.full_messages}"
    
    assert_equal 'urgent', urgent.priority, "Urgent should have correct priority"
    assert_equal 'maintenance', maintenance.category, "Maintenance should have correct category"
    assert_equal false, draft.is_published, "Draft should not be published"
    assert_equal true, published.is_published, "Published should be published"
  end

  test "document factory should be valid" do
    document = build(:document)
    assert document.valid?, "Document factory should create valid document: #{document.errors.full_messages}"
  end

  test "document factory with traits should be valid" do
    policy = build(:document, :policy)
    procedure = build(:document, :procedure)
    form = build(:document, :form)
    manual = build(:document, :manual)
    
    assert policy.valid?, "Policy document should be valid: #{policy.errors.full_messages}"
    assert procedure.valid?, "Procedure document should be valid: #{procedure.errors.full_messages}"
    assert form.valid?, "Form document should be valid: #{form.errors.full_messages}"
    assert manual.valid?, "Manual document should be valid: #{manual.errors.full_messages}"
    
    assert_equal 'policy', policy.category, "Policy should have correct category"
    assert_equal 'procedure', procedure.category, "Procedure should have correct category"
    assert_equal 'form', form.category, "Form should have correct category"
    assert_equal 'manual', manual.category, "Manual should have correct category"
  end

  test "factories should create realistic data" do
    user = create(:user)
    employee = create(:employee)
    leave_request = create(:leave_request, employee: employee, approver: user)
    attendance = create(:attendance, employee: employee)
    announcement = create(:announcement)
    document = create(:document)
    
    # Verify data was persisted
    assert_not_nil User.find(user.id)
    assert_not_nil Employee.find(employee.id)
    assert_not_nil LeaveRequest.find(leave_request.id)
    assert_not_nil Attendance.find(attendance.id)
    assert_not_nil Announcement.find(announcement.id)
    assert_not_nil Document.find(document.id)
    
    # Verify relationships
    assert_equal employee, leave_request.employee
    assert_equal user, leave_request.approver
    assert_equal employee, attendance.employee
    
    # Verify realistic data
    assert user.email.include?("@"), "User email should be realistic"
    assert employee.phone.match?(/^\d{3}-\d{4}-\d{4}$/), "Employee phone should match Korean format"
    assert leave_request.days_requested > 0, "Leave request should have positive days"
    assert attendance.work_date.present?, "Attendance should have work date"
    assert announcement.title.present?, "Announcement should have title"
    assert document.file_size > 0, "Document should have file size"
  end
end
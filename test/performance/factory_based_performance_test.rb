require "test_helper"
require "benchmark"

class FactoryBasedPerformanceTest < ActiveSupport::TestCase
  def setup
    # Clean database before each test
    DatabaseCleaner.clean_with(:truncation)
    
    # Create base test data with Factory Bot
    @admin_user = create(:user, :admin)
    @manager_user = create(:user, :manager)
    @departments = ['의료진', '간호부', '행정부', '시설관리']
    
    # Create realistic test dataset
    create_performance_dataset
  end

  def teardown
    # Clean up after tests
    DatabaseCleaner.clean_with(:truncation)
  end

  test "should perform employee queries efficiently with realistic data" do
    puts "\n=== Factory-Based Employee Query Performance ==="
    
    # Test 1: Simple employee list query
    time = Benchmark.measure do
      Employee.active.limit(100).to_a
    end
    puts "Active employees (100 limit): #{time.real.round(4)}s"
    assert time.real < 0.1, "Active employees query too slow: #{time.real}s"
    
    # Test 2: Employee with associations
    time = Benchmark.measure do
      Employee.includes(:leave_requests, :attendances)
              .by_department('의료진')
              .limit(50).to_a
    end
    puts "Employees with associations (의료진): #{time.real.round(4)}s"
    assert time.real < 0.2, "Complex employee query too slow: #{time.real}s"
    
    # Test 3: Search query
    time = Benchmark.measure do
      Employee.where("name ILIKE ?", "%Doctor%")
              .active
              .limit(20).to_a
    end
    puts "Employee search query: #{time.real.round(4)}s"
    assert time.real < 0.05, "Employee search too slow: #{time.real}s"
  end

  test "should handle leave request queries efficiently" do
    puts "\n=== Leave Request Query Performance ==="
    
    # Test 1: Pending approvals
    time = Benchmark.measure do
      LeaveRequest.includes(:employee, :approver)
                  .where(status: 'pending')
                  .order(:start_date)
                  .limit(100).to_a
    end
    puts "Pending approvals query: #{time.real.round(4)}s"
    assert time.real < 0.15, "Pending approvals too slow: #{time.real}s"
    
    # Test 2: Date range query with statistics
    time = Benchmark.measure do
      LeaveRequest.joins(:employee)
                  .where(start_date: Date.current.beginning_of_year..Date.current.end_of_year)
                  .where(status: 'approved')
                  .group('employees.department')
                  .sum(:days_requested)
    end
    puts "Annual statistics by department: #{time.real.round(4)}s"
    assert time.real < 0.2, "Statistics query too slow: #{time.real}s"
    
    # Test 3: Employee leave history
    employee = Employee.first
    time = Benchmark.measure do
      LeaveRequest.where(employee: employee)
                  .where(start_date: 1.year.ago..Date.current)
                  .includes(:approver)
                  .order(:start_date).to_a
    end
    puts "Employee leave history: #{time.real.round(4)}s"
    assert time.real < 0.05, "Employee history too slow: #{time.real}s"
  end

  test "should calculate annual leave balances efficiently" do
    puts "\n=== Annual Leave Balance Performance ==="
    
    employees = Employee.active.limit(20)
    
    # Test individual calculations
    total_time = Benchmark.measure do
      employees.each do |employee|
        calculate_annual_leave_balance(employee)
      end
    end
    
    avg_time = total_time.real / employees.count
    puts "Balance calculation (20 employees): #{total_time.real.round(4)}s"
    puts "Average per employee: #{avg_time.round(4)}s"
    
    assert avg_time < 0.05, "Balance calculation too slow: #{avg_time}s"
    
    # Test batch calculation
    batch_time = Benchmark.measure do
      calculate_batch_annual_leave_balances(employees)
    end
    
    puts "Batch balance calculation: #{batch_time.real.round(4)}s"
    assert batch_time.real < total_time.real, "Batch calculation should be faster"
  end

  test "should handle concurrent requests efficiently" do
    puts "\n=== Concurrent Request Performance ==="
    
    threads = []
    results = []
    
    total_time = Benchmark.measure do
      10.times do
        threads << Thread.new do
          individual_time = Benchmark.measure do
            # Simulate concurrent API requests
            Employee.active.limit(10).to_a
            LeaveRequest.where(status: 'pending').limit(5).to_a
            Attendance.where(work_date: Date.current).limit(10).to_a
          end
          results << individual_time.real
        end
      end
      
      threads.each(&:join)
    end
    
    avg_response = results.sum / results.size
    max_response = results.max
    throughput = 10 / total_time.real
    
    puts "10 concurrent requests:"
    puts "  Total time: #{total_time.real.round(4)}s"
    puts "  Average response: #{avg_response.round(4)}s"
    puts "  Max response: #{max_response.round(4)}s"
    puts "  Throughput: #{throughput.round(2)} req/s"
    
    assert avg_response < 0.2, "Concurrent requests too slow: #{avg_response}s"
    assert throughput > 10, "Throughput too low: #{throughput} req/s"
  end

  test "should handle bulk operations efficiently" do
    puts "\n=== Bulk Operations Performance ==="
    
    # Test bulk attendance insert
    attendance_data = []
    Employee.active.limit(20).each do |employee|
      (1..30).each do |day|
        attendance_data << attributes_for(:attendance,
          employee: employee,
          work_date: Date.current.beginning_of_month + day.days,
          status: 'present'
        ).except(:employee)
      end
    end
    
    time = Benchmark.measure do
      Attendance.insert_all(attendance_data.first(100))
    end
    
    records_per_second = 100 / time.real
    puts "Bulk insert (100 attendances): #{time.real.round(4)}s"
    puts "Records per second: #{records_per_second.round(0)}"
    
    assert records_per_second > 200, "Bulk insert too slow: #{records_per_second} records/s"
    
    # Test bulk update
    attendance_ids = Attendance.limit(50).pluck(:id)
    time = Benchmark.measure do
      Attendance.where(id: attendance_ids).update_all(status: 'late')
    end
    
    puts "Bulk update (50 records): #{time.real.round(4)}s"
    assert time.real < 0.1, "Bulk update too slow: #{time.real}s"
    
    # Test bulk delete
    time = Benchmark.measure do
      Attendance.where(work_date: Date.current.beginning_of_month..).delete_all
    end
    
    puts "Bulk delete: #{time.real.round(4)}s"
    assert time.real < 0.1, "Bulk delete too slow: #{time.real}s"
  end

  test "should optimize complex dashboard queries" do
    puts "\n=== Dashboard Query Performance ==="
    
    # Simulate dashboard data loading
    time = Benchmark.measure do
      dashboard_data = {
        total_employees: Employee.active.count,
        pending_leaves: LeaveRequest.where(status: 'pending').count,
        today_attendances: Attendance.where(work_date: Date.current).count,
        recent_announcements: Announcement.where(is_published: true)
                                         .order(:published_at)
                                         .limit(5).to_a,
        department_stats: Employee.active.group(:department).count,
        leave_stats: LeaveRequest.where(
                       start_date: Date.current.beginning_of_month..Date.current.end_of_month
                     ).group(:leave_type).count
      }
    end
    
    puts "Dashboard data loading: #{time.real.round(4)}s"
    assert time.real < 0.5, "Dashboard loading too slow: #{time.real}s"
  end

  test "should handle search operations efficiently" do
    puts "\n=== Search Performance ==="
    
    # Test employee search
    time = Benchmark.measure do
      Employee.where("name ILIKE ? OR email ILIKE ?", "%김%", "%김%")
              .limit(20).to_a
    end
    puts "Employee name/email search: #{time.real.round(4)}s"
    assert time.real < 0.05, "Employee search too slow: #{time.real}s"
    
    # Test announcement search
    time = Benchmark.measure do
      Announcement.where("title ILIKE ? OR content ILIKE ?", "%공지%", "%공지%")
                  .where(is_published: true)
                  .limit(20).to_a
    end
    puts "Announcement search: #{time.real.round(4)}s"
    assert time.real < 0.05, "Announcement search too slow: #{time.real}s"
    
    # Test document search
    time = Benchmark.measure do
      Document.where("title ILIKE ? OR content ILIKE ?", "%정책%", "%정책%")
              .where(is_active: true)
              .limit(20).to_a
    end
    puts "Document search: #{time.real.round(4)}s"
    assert time.real < 0.05, "Document search too slow: #{time.real}s"
  end

  private

  def create_performance_dataset
    puts "Creating realistic performance dataset..."
    
    # Create employees for all departments
    @departments.each do |dept|
      case dept
      when '의료진'
        create_list(:employee, 30, :doctor, department: dept)
      when '간호부'
        create_list(:employee, 25, :nurse, department: dept)
      when '행정부'
        create_list(:employee, 15, :admin_staff, department: dept)
      when '시설관리'
        create_list(:employee, 10, :facility_staff, department: dept)
      end
    end
    
    # Create leave requests for employees
    Employee.active.limit(40).each do |employee|
      create_list(:leave_request, rand(2..6), :approved, 
                  employee: employee, approver: @admin_user)
      create_list(:leave_request, rand(0..2), :pending, 
                  employee: employee, approver: @manager_user)
    end
    
    # Create attendance records for last month
    Employee.active.limit(30).each do |employee|
      (1..22).each do |day|  # 22 working days
        work_date = 1.month.ago.beginning_of_month + day.days
        next if work_date.saturday? || work_date.sunday?
        
        create(:attendance, 
               employee: employee,
               work_date: work_date,
               status: ['present', 'present', 'present', 'late'].sample)
      end
    end
    
    # Create announcements
    create_list(:announcement, 20, :published)
    create_list(:announcement, 5, :urgent, :published)
    create_list(:announcement, 3, :draft)
    
    # Create documents
    create_list(:document, 50, :active)
    create_list(:document, 10, :policy, :active)
    create_list(:document, 15, :procedure, :active)
    
    puts "Created realistic dataset: #{Employee.count} employees, #{LeaveRequest.count} leave requests, #{Attendance.count} attendances"
  end

  def calculate_annual_leave_balance(employee)
    # Simplified annual leave calculation
    years_employed = ((Date.current - employee.hire_date) / 365.25).floor
    total_annual_leave = [15 + years_employed, 25].min
    
    used_days = LeaveRequest.where(
      employee: employee,
      leave_type: 'annual',
      status: 'approved',
      start_date: Date.current.beginning_of_year..Date.current.end_of_year
    ).sum(:days_requested)
    
    total_annual_leave - used_days
  end

  def calculate_batch_annual_leave_balances(employees)
    # Batch calculation using SQL
    employee_ids = employees.pluck(:id)
    
    # Get used days for all employees in one query
    used_days = LeaveRequest.where(
      employee_id: employee_ids,
      leave_type: 'annual',
      status: 'approved',
      start_date: Date.current.beginning_of_year..Date.current.end_of_year
    ).group(:employee_id).sum(:days_requested)
    
    # Calculate balances
    employees.map do |employee|
      years_employed = ((Date.current - employee.hire_date) / 365.25).floor
      total_annual_leave = [15 + years_employed, 25].min
      used = used_days[employee.id] || 0
      total_annual_leave - used
    end
  end
end
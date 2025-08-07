require "test_helper"
require "benchmark"

class DatabasePerformanceTest < ActiveSupport::TestCase
  def setup
    # Clean up test data
    cleanup_test_data
    
    # Create test data
    create_performance_test_data
  end

  def teardown
    # Clean up after tests
    cleanup_test_data
  end

  test "employee queries should perform within acceptable limits" do
    puts "\n=== Employee Query Performance Tests ==="
    
    # Test 1: Find all active employees
    time = Benchmark.measure do
      Employee.active.limit(100)
    end
    puts "Find 100 active employees: #{time.real.round(4)}s"
    assert time.real < 0.1, "Employee query took too long: #{time.real}s"
    
    # Test 2: Find employees by department with includes
    time = Benchmark.measure do
      Employee.includes(:leave_requests, :attendances)
              .by_department('의료진')
              .limit(50)
    end
    puts "Find 50 employees with associations: #{time.real.round(4)}s"
    assert time.real < 0.2, "Employee with associations query took too long: #{time.real}s"
    
    # Test 3: Complex employee search
    time = Benchmark.measure do
      Employee.where(status: 'active')
              .where(employment_type: 'full_time')
              .where("hire_date > ?", 1.year.ago)
              .includes(:leave_requests)
              .limit(20)
    end
    puts "Complex employee search: #{time.real.round(4)}s"
    assert time.real < 0.15, "Complex search took too long: #{time.real}s"
  end

  test "leave request queries should perform within acceptable limits" do
    puts "\n=== Leave Request Query Performance Tests ==="
    
    # Test 1: Find pending approvals
    time = Benchmark.measure do
      LeaveRequest.includes(:employee, :approver)
                  .pending_approval
                  .order(:start_date)
                  .limit(50)
    end
    puts "Find 50 pending approvals: #{time.real.round(4)}s"
    assert time.real < 0.1, "Pending approvals query took too long: #{time.real}s"
    
    # Test 2: Leave requests with date range filter
    time = Benchmark.measure do
      LeaveRequest.includes(:employee)
                  .where(start_date: Date.current.beginning_of_year..Date.current.end_of_year)
                  .where(status: 'approved')
                  .limit(100)
    end
    puts "Find 100 approved leaves this year: #{time.real.round(4)}s"
    assert time.real < 0.15, "Date range query took too long: #{time.real}s"
    
    # Test 3: Complex leave statistics query
    time = Benchmark.measure do
      LeaveRequest.joins(:employee)
                  .where(employees: { department: '의료진' })
                  .where(status: 'approved')
                  .where(start_date: Date.current.beginning_of_year..Date.current.end_of_year)
                  .group(:leave_type)
                  .sum(:days_requested)
    end
    puts "Complex leave statistics: #{time.real.round(4)}s"
    assert time.real < 0.2, "Statistics query took too long: #{time.real}s"
  end

  test "annual leave balance calculation should be efficient" do
    puts "\n=== Annual Leave Balance Performance Tests ==="
    
    employees = Employee.active.limit(10)
    
    # Test individual balance calculations
    total_time = Benchmark.measure do
      employees.each do |employee|
        employee.annual_leave_balance
      end
    end
    
    avg_time = total_time.real / employees.count
    puts "Annual leave balance calculation (10 employees): #{total_time.real.round(4)}s"
    puts "Average per employee: #{avg_time.round(4)}s"
    
    assert avg_time < 0.05, "Annual leave balance calculation too slow: #{avg_time}s per employee"
    
    # Test with cache warming
    cache_time = Benchmark.measure do
      employees.each do |employee|
        employee.annual_leave_balance # Second call should use cache
      end
    end
    
    cache_avg_time = cache_time.real / employees.count
    puts "Cached balance calculation (10 employees): #{cache_time.real.round(4)}s"
    puts "Average per employee (cached): #{cache_avg_time.round(4)}s"
    
    assert cache_avg_time < 0.01, "Cached calculation too slow: #{cache_avg_time}s per employee"
  end

  test "database indexes should be effective" do
    puts "\n=== Database Index Effectiveness Tests ==="
    
    # Test employee email index
    time = Benchmark.measure do
      Employee.find_by(email: 'performance.test.1@test.com')
    end
    puts "Employee email lookup: #{time.real.round(4)}s"
    assert time.real < 0.01, "Email lookup too slow (index may be missing): #{time.real}s"
    
    # Test leave request employee_id index
    employee = Employee.first
    time = Benchmark.measure do
      LeaveRequest.where(employee: employee).limit(10)
    end
    puts "Leave requests by employee: #{time.real.round(4)}s"
    assert time.real < 0.01, "Employee leave requests lookup too slow: #{time.real}s"
    
    # Test leave request status index
    time = Benchmark.measure do
      LeaveRequest.where(status: 'pending').limit(10)
    end
    puts "Leave requests by status: #{time.real.round(4)}s"
    assert time.real < 0.01, "Status lookup too slow: #{time.real}s"
    
    # Test composite index (employee_id, status)
    time = Benchmark.measure do
      LeaveRequest.where(employee: employee, status: 'approved').limit(10)
    end
    puts "Leave requests by employee and status: #{time.real.round(4)}s"
    assert time.real < 0.01, "Composite index lookup too slow: #{time.real}s"
  end

  test "bulk operations should be efficient" do
    puts "\n=== Bulk Operations Performance Tests ==="
    
    # Test bulk insert (attendances)
    attendance_data = []
    Employee.active.limit(10).each do |employee|
      (1..30).each do |day|
        attendance_data << {
          employee: employee,
          work_date: Date.current.beginning_of_month + day.days,
          check_in: Time.current.beginning_of_day + 8.hours,
          check_out: Time.current.beginning_of_day + 18.hours,
          regular_hours: 8.0,
          overtime_hours: 2.0,
          status: 'present'
        }
      end
    end
    
    time = Benchmark.measure do
      Attendance.create!(attendance_data)
    end
    
    records_per_second = attendance_data.size / time.real
    puts "Bulk attendance insert (#{attendance_data.size} records): #{time.real.round(4)}s"
    puts "Records per second: #{records_per_second.round(0)}"
    
    assert records_per_second > 100, "Bulk insert too slow: #{records_per_second} records/second"
    
    # Test bulk delete
    time = Benchmark.measure do
      Attendance.where(work_date: Date.current.beginning_of_month..).delete_all
    end
    puts "Bulk attendance delete: #{time.real.round(4)}s"
    assert time.real < 0.1, "Bulk delete too slow: #{time.real}s"
  end

  test "concurrent access should not cause performance degradation" do
    puts "\n=== Concurrent Access Performance Tests ==="
    
    # Simulate concurrent leave request queries
    threads = []
    results = []
    
    time = Benchmark.measure do
      5.times do
        threads << Thread.new do
          result_time = Benchmark.measure do
            LeaveRequest.includes(:employee)
                        .where(status: 'pending')
                        .limit(20)
                        .to_a
          end
          results << result_time.real
        end
      end
      
      threads.each(&:join)
    end
    
    avg_thread_time = results.sum / results.size
    puts "5 concurrent queries total time: #{time.real.round(4)}s"
    puts "Average per thread: #{avg_thread_time.round(4)}s"
    puts "Max thread time: #{results.max.round(4)}s"
    
    assert avg_thread_time < 0.2, "Concurrent query performance degraded: #{avg_thread_time}s"
    assert results.max < 0.5, "Some threads took too long: #{results.max}s"
  end

  private

  def create_performance_test_data
    puts "Creating performance test data..."
    
    # Create test users
    @admin_user = User.create!(
      name: "Performance Admin",
      email: "perf.admin@test.com",
      password: "password123",
      role: 3
    )
    
    @manager_user = User.create!(
      name: "Performance Manager",
      email: "perf.manager@test.com",
      password: "password123",
      role: 2
    )
    
    # Create test employees
    departments = ['의료진', '간호부', '행정부', '시설관리']
    employment_types = ['full_time', 'contract', 'part_time']
    
    100.times do |i|
      Employee.create!(
        name: "Test Employee #{i + 1}",
        department: departments.sample,
        position: "Position #{i % 10 + 1}",
        employment_type: employment_types.sample,
        hire_date: rand(5.years).seconds.ago,
        phone: "010-#{rand(1000..9999)}-#{rand(1000..9999)}",
        email: "performance.test.#{i + 1}@test.com",
        base_salary: rand(2000000..8000000),
        salary_type: 'monthly',
        status: ['active', 'active', 'active', 'on_leave'].sample # 75% active
      )
    end
    
    # Create test leave requests
    Employee.active.limit(50).each do |employee|
      rand(1..5).times do |j|
        start_date = rand(1.year).seconds.ago.to_date
        end_date = start_date + rand(1..7).days
        
        LeaveRequest.create!(
          employee: employee,
          leave_type: ['annual', 'sick', 'personal', 'bereavement'].sample,
          start_date: start_date,
          end_date: end_date,
          days_requested: (end_date - start_date).to_i + 1,
          reason: "Performance Test Leave #{j + 1}",
          status: ['pending', 'approved', 'approved', 'rejected'].sample, # 50% approved
          approver: [@admin_user, @manager_user].sample
        )
      end
    end
    
    puts "Created #{Employee.count} employees and #{LeaveRequest.count} leave requests for testing"
  end

  def cleanup_test_data
    LeaveRequest.where("reason LIKE ?", "%Performance Test%").delete_all
    Employee.where("name LIKE ?", "%Test Employee%").delete_all
    User.where("email LIKE ?", "%perf.%@test.com").delete_all
    Attendance.where("created_at > ?", 1.hour.ago).delete_all
  end
end
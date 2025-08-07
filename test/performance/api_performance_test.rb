require "test_helper"
require "benchmark"
require "net/http"
require "json"

class ApiPerformanceTest < ActionDispatch::IntegrationTest
  def setup
    @admin_user = User.create!(
      name: "API Test Admin",
      email: "api.admin@test.com", 
      password: "password123",
      role: 3
    )
    
    @employee = Employee.create!(
      name: "API Test Employee",
      department: "의료진",
      position: "Doctor",
      employment_type: "full_time",
      hire_date: 2.years.ago,
      phone: "010-1234-5678",
      email: "api.test@test.com",
      base_salary: 5000000,
      salary_type: "monthly",
      status: "active"
    )
    
    create_test_leave_requests
    
    @auth_headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{@admin_user.generate_jwt_token}"
    }
  end

  def teardown
    cleanup_test_data
  end

  test "API endpoints should respond within performance targets" do
    puts "\n=== API Response Time Performance Tests ==="
    
    # Test employee list endpoint
    response_time = measure_api_response_time do
      get '/api/v1/employees', headers: @auth_headers
    end
    
    puts "GET /api/v1/employees: #{response_time.round(4)}s"
    assert_response :success
    assert response_time < 0.2, "Employees API too slow: #{response_time}s"
    
    # Test leave requests list endpoint
    response_time = measure_api_response_time do
      get '/api/v1/leave_requests', headers: @auth_headers
    end
    
    puts "GET /api/v1/leave_requests: #{response_time.round(4)}s"
    assert_response :success
    assert response_time < 0.3, "Leave requests API too slow: #{response_time}s"
    
    # Test leave requests statistics endpoint
    response_time = measure_api_response_time do
      get '/api/v1/leave_requests/statistics', headers: @auth_headers
    end
    
    puts "GET /api/v1/leave_requests/statistics: #{response_time.round(4)}s"
    assert_response :success
    assert response_time < 0.2, "Statistics API too slow: #{response_time}s"
    
    # Test annual leave status endpoint
    response_time = measure_api_response_time do
      get "/api/v1/leave_requests/annual_leave_status?employee_id=#{@employee.id}", headers: @auth_headers
    end
    
    puts "GET /api/v1/leave_requests/annual_leave_status: #{response_time.round(4)}s"
    assert_response :success
    assert response_time < 0.15, "Annual leave status API too slow: #{response_time}s"
  end

  test "API endpoints should handle concurrent requests efficiently" do
    puts "\n=== Concurrent API Request Performance Tests ==="
    
    # Test concurrent leave requests
    threads = []
    response_times = []
    
    total_time = Benchmark.measure do
      10.times do
        threads << Thread.new do
          individual_time = measure_api_response_time do
            get '/api/v1/leave_requests', headers: @auth_headers
          end
          response_times << individual_time
        end
      end
      
      threads.each(&:join)
    end
    
    avg_response_time = response_times.sum / response_times.size
    max_response_time = response_times.max
    
    puts "10 concurrent GET /api/v1/leave_requests:"
    puts "  Total time: #{total_time.real.round(4)}s"
    puts "  Average response time: #{avg_response_time.round(4)}s"
    puts "  Max response time: #{max_response_time.round(4)}s"
    puts "  Requests per second: #{(10 / total_time.real).round(2)}"
    
    assert avg_response_time < 0.5, "Average concurrent response time too slow: #{avg_response_time}s"
    assert max_response_time < 1.0, "Some concurrent requests took too long: #{max_response_time}s"
    assert (10 / total_time.real) > 5, "Concurrent throughput too low: #{(10 / total_time.real).round(2)} req/s"
  end

  test "POST API endpoints should perform efficiently" do
    puts "\n=== POST API Performance Tests ==="
    
    leave_request_data = {
      employee_id: @employee.id,
      leave_request: {
        leave_type: 'annual',
        start_date: Date.current + 1.week,
        end_date: Date.current + 1.week + 2.days,
        days_requested: 3,
        reason: 'Performance Test Leave Request'
      }
    }
    
    # Test leave request creation
    response_time = measure_api_response_time do
      post '/api/v1/leave_requests', 
           params: leave_request_data.to_json, 
           headers: @auth_headers
    end
    
    puts "POST /api/v1/leave_requests: #{response_time.round(4)}s"
    assert_response :success
    assert response_time < 0.3, "Leave request creation too slow: #{response_time}s"
    
    created_request = JSON.parse(response.body)['data']['leave_request']
    
    # Test leave request approval
    response_time = measure_api_response_time do
      patch "/api/v1/leave_requests/#{created_request['id']}/approve",
            headers: @auth_headers
    end
    
    puts "PATCH /api/v1/leave_requests/:id/approve: #{response_time.round(4)}s"
    assert_response :success
    assert response_time < 0.2, "Leave request approval too slow: #{response_time}s"
  end

  test "API response payload sizes should be reasonable" do
    puts "\n=== API Response Size Tests ==="
    
    # Test employees list response size
    get '/api/v1/employees', headers: @auth_headers
    employees_size = response.body.bytesize
    puts "Employees API response size: #{employees_size} bytes"
    assert employees_size < 50000, "Employees response too large: #{employees_size} bytes"
    
    # Test leave requests response size
    get '/api/v1/leave_requests', headers: @auth_headers
    leave_requests_size = response.body.bytesize
    puts "Leave requests API response size: #{leave_requests_size} bytes"
    assert leave_requests_size < 100000, "Leave requests response too large: #{leave_requests_size} bytes"
    
    # Test statistics response size
    get '/api/v1/leave_requests/statistics', headers: @auth_headers
    statistics_size = response.body.bytesize
    puts "Statistics API response size: #{statistics_size} bytes"
    assert statistics_size < 5000, "Statistics response too large: #{statistics_size} bytes"
  end

  test "API should handle large dataset queries efficiently" do
    puts "\n=== Large Dataset Performance Tests ==="
    
    # Create additional test data
    create_large_dataset
    
    # Test with large dataset
    response_time = measure_api_response_time do
      get '/api/v1/leave_requests?year=2025', headers: @auth_headers
    end
    
    puts "GET /api/v1/leave_requests (large dataset): #{response_time.round(4)}s"
    assert_response :success
    assert response_time < 0.5, "Large dataset query too slow: #{response_time}s"
    
    # Test statistics with large dataset
    response_time = measure_api_response_time do
      get '/api/v1/leave_requests/statistics?year=2025', headers: @auth_headers
    end
    
    puts "GET /api/v1/leave_requests/statistics (large dataset): #{response_time.round(4)}s"
    assert_response :success
    assert response_time < 0.4, "Large dataset statistics too slow: #{response_time}s"
    
    # Test with filters
    response_time = measure_api_response_time do
      get '/api/v1/leave_requests?status=approved&leave_type=annual', headers: @auth_headers
    end
    
    puts "GET /api/v1/leave_requests (filtered): #{response_time.round(4)}s"
    assert_response :success
    assert response_time < 0.3, "Filtered query too slow: #{response_time}s"
  end

  test "API error handling should not impact performance" do
    puts "\n=== API Error Handling Performance Tests ==="
    
    # Test 404 error response time
    response_time = measure_api_response_time do
      get '/api/v1/leave_requests/999999', headers: @auth_headers
    end
    
    puts "404 error response time: #{response_time.round(4)}s"
    assert_response :not_found
    assert response_time < 0.1, "404 error response too slow: #{response_time}s"
    
    # Test validation error response time
    response_time = measure_api_response_time do
      post '/api/v1/leave_requests',
           params: { employee_id: @employee.id, leave_request: {} }.to_json,
           headers: @auth_headers
    end
    
    puts "Validation error response time: #{response_time.round(4)}s"
    assert_response :unprocessable_entity
    assert response_time < 0.15, "Validation error response too slow: #{response_time}s"
    
    # Test unauthorized error response time
    response_time = measure_api_response_time do
      get '/api/v1/leave_requests', 
          headers: { 'Content-Type' => 'application/json' } # No auth token
    end
    
    puts "Unauthorized error response time: #{response_time.round(4)}s"
    assert_response :unauthorized
    assert response_time < 0.05, "Unauthorized error response too slow: #{response_time}s"
  end

  private

  def measure_api_response_time
    start_time = Time.current
    yield
    Time.current - start_time
  end

  def create_test_leave_requests
    # Create some test leave requests for performance testing
    5.times do |i|
      LeaveRequest.create!(
        employee: @employee,
        leave_type: ['annual', 'sick', 'personal'].sample,
        start_date: Date.current + (i + 1).weeks,
        end_date: Date.current + (i + 1).weeks + 2.days,
        days_requested: 3,
        reason: "API Test Leave Request #{i + 1}",
        status: ['pending', 'approved', 'rejected'].sample
      )
    end
  end

  def create_large_dataset
    # Create additional employees
    20.times do |i|
      emp = Employee.create!(
        name: "Large Test Employee #{i + 1}",
        department: ['의료진', '간호부', '행정부'].sample,
        position: "Test Position",
        employment_type: "full_time",
        hire_date: rand(3.years).seconds.ago,
        phone: "010-#{rand(1000..9999)}-#{rand(1000..9999)}",
        email: "large.test.#{i + 1}@test.com",
        base_salary: rand(3000000..6000000),
        salary_type: "monthly",
        status: "active"
      )
      
      # Create leave requests for each employee
      rand(3..8).times do |j|
        start_date = Date.current.beginning_of_year + rand(365).days
        end_date = start_date + rand(1..5).days
        
        LeaveRequest.create!(
          employee: emp,
          leave_type: ['annual', 'sick', 'personal', 'bereavement'].sample,
          start_date: start_date,
          end_date: end_date,
          days_requested: (end_date - start_date).to_i + 1,
          reason: "Large Test Leave Request #{j + 1}",
          status: ['pending', 'approved', 'approved', 'rejected'].sample,
          approver: @admin_user
        )
      end
    end
    
    puts "Created large dataset: #{Employee.where('name LIKE ?', '%Large Test%').count} employees, #{LeaveRequest.where('reason LIKE ?', '%Large Test%').count} leave requests"
  end

  def cleanup_test_data
    LeaveRequest.where("reason LIKE ?", "%Test%").delete_all
    Employee.where("name LIKE ? OR email LIKE ?", "%Test%", "%test@test.com").delete_all
    User.where("email LIKE ?", "%api.%@test.com").delete_all
  end
end
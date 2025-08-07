require "test_helper"

class Api::V1::EmployeesControllerComprehensiveTest < ActionDispatch::IntegrationTest
  def setup
    @admin_user = create(:user, :admin)
    @manager_user = create(:user, :manager)
    @staff_user = create(:user, :staff)
    @employees = create_list(:employee, 10, :doctor)
    create_list(:employee, 5, :nurse)
    create_list(:employee, 3, :admin_staff)
  end

  # Index Action Tests
  test "should get employees index with admin auth" do
    mock_current_user(@admin_user)
    get api_v1_employees_path, headers: auth_headers_for(@admin_user)
    
    assert_response :success
    json_response = JSON.parse(response.body)
    
    assert_equal 'success', json_response['status']
    assert json_response['data']['employees'].is_a?(Array)
    assert json_response['data']['employees'].length > 0
    assert json_response['data']['total_count'] >= 18
  end

  test "should get employees index with manager auth" do
    mock_current_user(@manager_user)
    get api_v1_employees_path, headers: auth_headers_for(@manager_user)
    
    assert_response :success
    json_response = JSON.parse(response.body)
    
    assert_equal 'success', json_response['status']
    assert json_response['data']['employees'].is_a?(Array)
  end

  test "should deny employees index for staff user" do
    mock_current_user(@staff_user)
    get api_v1_employees_path, headers: auth_headers_for(@staff_user)
    
    assert_response :forbidden
    json_response = JSON.parse(response.body)
    assert_equal 'error', json_response['status']
  end

  test "should deny employees index without authentication" do
    get api_v1_employees_path
    
    assert_response :unauthorized
  end

  # Filtering Tests
  test "should filter employees by department" do
    mock_current_user(@admin_user)
    get api_v1_employees_path, 
        params: { department: '의료진' },
        headers: auth_headers_for(@admin_user)
    
    assert_response :success
    json_response = JSON.parse(response.body)
    
    medical_employees = json_response['data']['employees']
    assert medical_employees.all? { |emp| emp['department'] == '의료진' }
  end

  test "should filter employees by status" do
    # Create inactive employee
    create(:employee, :inactive)
    
    mock_current_user(@admin_user)
    get api_v1_employees_path,
        params: { status: 'active' },
        headers: auth_headers_for(@admin_user)
    
    assert_response :success
    json_response = JSON.parse(response.body)
    
    active_employees = json_response['data']['employees']
    assert active_employees.all? { |emp| emp['status'] == 'active' }
  end

  test "should filter employees by employment type" do
    create_list(:employee, 3, :contract)
    
    mock_current_user(@admin_user)
    get api_v1_employees_path,
        params: { employment_type: 'contract' },
        headers: auth_headers_for(@admin_user)
    
    assert_response :success
    json_response = JSON.parse(response.body)
    
    contract_employees = json_response['data']['employees']
    assert contract_employees.all? { |emp| emp['employment_type'] == 'contract' }
  end

  # Search Tests
  test "should search employees by name" do
    search_employee = create(:employee, name: 'John Smith Doctor')
    
    mock_current_user(@admin_user)
    get api_v1_employees_path,
        params: { search: 'John Smith' },
        headers: auth_headers_for(@admin_user)
    
    assert_response :success
    json_response = JSON.parse(response.body)
    
    found_employees = json_response['data']['employees']
    assert found_employees.any? { |emp| emp['id'] == search_employee.id }
  end

  test "should search employees by email" do
    search_employee = create(:employee, email: 'searchable@hospital.com')
    
    mock_current_user(@admin_user)
    get api_v1_employees_path,
        params: { search: 'searchable@hospital.com' },
        headers: auth_headers_for(@admin_user)
    
    assert_response :success
    json_response = JSON.parse(response.body)
    
    found_employees = json_response['data']['employees']
    assert found_employees.any? { |emp| emp['id'] == search_employee.id }
  end

  # Pagination Tests
  test "should paginate employees list" do
    mock_current_user(@admin_user)
    get api_v1_employees_path,
        params: { page: 1, per_page: 5 },
        headers: auth_headers_for(@admin_user)
    
    assert_response :success
    json_response = JSON.parse(response.body)
    
    assert json_response['data']['employees'].length <= 5
    assert json_response['data']['pagination'].present?
    assert json_response['data']['pagination']['current_page'] == 1
    assert json_response['data']['pagination']['per_page'] == 5
  end

  # Show Action Tests
  test "should show employee details with admin auth" do
    employee = @employees.first
    mock_current_user(@admin_user)
    
    get api_v1_employee_path(employee), headers: auth_headers_for(@admin_user)
    
    assert_response :success
    json_response = JSON.parse(response.body)
    
    assert_equal 'success', json_response['status']
    assert_equal employee.id, json_response['data']['employee']['id']
    assert_equal employee.name, json_response['data']['employee']['name']
    assert_equal employee.department, json_response['data']['employee']['department']
  end

  test "should show employee details with manager auth" do
    employee = @employees.first
    mock_current_user(@manager_user)
    
    get api_v1_employee_path(employee), headers: auth_headers_for(@manager_user)
    
    assert_response :success
  end

  test "should deny employee details for staff user" do
    employee = @employees.first
    mock_current_user(@staff_user)
    
    get api_v1_employee_path(employee), headers: auth_headers_for(@staff_user)
    
    assert_response :forbidden
  end

  test "should return not found for non-existent employee" do
    mock_current_user(@admin_user)
    
    get api_v1_employee_path(999999), headers: auth_headers_for(@admin_user)
    
    assert_response :not_found
    json_response = JSON.parse(response.body)
    assert_equal 'error', json_response['status']
  end

  # Create Action Tests
  test "should create employee with admin auth" do
    mock_current_user(@admin_user)
    
    employee_params = {
      employee: {
        name: 'New Doctor',
        department: '의료진',
        position: '전문의',
        employment_type: 'full_time',
        hire_date: Date.current,
        phone: '010-1234-5678',
        email: 'newdoctor@hospital.com',
        base_salary: 8000000,
        salary_type: 'monthly',
        status: 'active'
      }
    }
    
    assert_difference('Employee.count') do
      post api_v1_employees_path,
           params: employee_params.to_json,
           headers: auth_headers_for(@admin_user)
    end
    
    assert_response :success
    json_response = JSON.parse(response.body)
    
    assert_equal 'success', json_response['status']
    assert_equal 'New Doctor', json_response['data']['employee']['name']
  end

  test "should not create employee with invalid data" do
    mock_current_user(@admin_user)
    
    invalid_params = {
      employee: {
        name: '',  # Invalid - required field
        department: 'invalid_department',  # Invalid - not in list
        email: 'invalid-email'  # Invalid - format
      }
    }
    
    assert_no_difference('Employee.count') do
      post api_v1_employees_path,
           params: invalid_params.to_json,
           headers: auth_headers_for(@admin_user)
    end
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal 'error', json_response['status']
    assert json_response['errors'].present?
  end

  test "should deny employee creation for non-admin users" do
    mock_current_user(@manager_user)
    
    employee_params = {
      employee: attributes_for(:employee)
    }
    
    assert_no_difference('Employee.count') do
      post api_v1_employees_path,
           params: employee_params.to_json,
           headers: auth_headers_for(@manager_user)
    end
    
    assert_response :forbidden
  end

  # Update Action Tests
  test "should update employee with admin auth" do
    employee = @employees.first
    mock_current_user(@admin_user)
    
    update_params = {
      employee: {
        name: 'Updated Name',
        position: 'Updated Position'
      }
    }
    
    patch api_v1_employee_path(employee),
          params: update_params.to_json,
          headers: auth_headers_for(@admin_user)
    
    assert_response :success
    json_response = JSON.parse(response.body)
    
    assert_equal 'success', json_response['status']
    assert_equal 'Updated Name', json_response['data']['employee']['name']
    assert_equal 'Updated Position', json_response['data']['employee']['position']
    
    employee.reload
    assert_equal 'Updated Name', employee.name
    assert_equal 'Updated Position', employee.position
  end

  test "should not update employee with invalid data" do
    employee = @employees.first
    mock_current_user(@admin_user)
    
    invalid_params = {
      employee: {
        email: 'invalid-email-format'
      }
    }
    
    patch api_v1_employee_path(employee),
          params: invalid_params.to_json,
          headers: auth_headers_for(@admin_user)
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal 'error', json_response['status']
  end

  # Destroy Action Tests
  test "should destroy employee with admin auth" do
    employee = @employees.first
    mock_current_user(@admin_user)
    
    assert_difference('Employee.count', -1) do
      delete api_v1_employee_path(employee), headers: auth_headers_for(@admin_user)
    end
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
  end

  test "should deny employee destruction for non-admin users" do
    employee = @employees.first
    mock_current_user(@manager_user)
    
    assert_no_difference('Employee.count') do
      delete api_v1_employee_path(employee), headers: auth_headers_for(@manager_user)
    end
    
    assert_response :forbidden
  end

  # Statistics Tests
  test "should get employee statistics" do
    mock_current_user(@admin_user)
    get api_v1_employees_path + '/statistics', headers: auth_headers_for(@admin_user)
    
    assert_response :success
    json_response = JSON.parse(response.body)
    
    assert json_response['data']['statistics'].present?
    assert json_response['data']['statistics']['total_employees'].present?
    assert json_response['data']['statistics']['by_department'].present?
    assert json_response['data']['statistics']['by_employment_type'].present?
  end

  # Error Handling Tests
  test "should handle server errors gracefully" do
    mock_current_user(@admin_user)
    
    # Mock an internal server error
    Employee.stub(:all, -> { raise StandardError.new("Database error") }) do
      get api_v1_employees_path, headers: auth_headers_for(@admin_user)
    end
    
    assert_response :internal_server_error
    json_response = JSON.parse(response.body)
    assert_equal 'error', json_response['status']
  end

  test "should validate content type for JSON requests" do
    mock_current_user(@admin_user)
    
    post api_v1_employees_path,
         params: { employee: attributes_for(:employee) },  # Form data instead of JSON
         headers: { 'Authorization' => "Bearer #{generate_test_token(@admin_user)}" }
    
    # Should handle form data or require JSON based on controller implementation
    assert_response :success || :bad_request
  end
end
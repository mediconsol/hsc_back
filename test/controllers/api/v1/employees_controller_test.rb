require "test_helper"

class Api::V1::EmployeesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get api_v1_employees_index_url
    assert_response :success
  end

  test "should get show" do
    get api_v1_employees_show_url
    assert_response :success
  end

  test "should get create" do
    get api_v1_employees_create_url
    assert_response :success
  end

  test "should get update" do
    get api_v1_employees_update_url
    assert_response :success
  end

  test "should get destroy" do
    get api_v1_employees_destroy_url
    assert_response :success
  end
end

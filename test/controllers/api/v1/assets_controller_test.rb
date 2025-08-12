require "test_helper"

class Api::V1::AssetsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get api_v1_assets_index_url
    assert_response :success
  end

  test "should get show" do
    get api_v1_assets_show_url
    assert_response :success
  end

  test "should get create" do
    get api_v1_assets_create_url
    assert_response :success
  end

  test "should get update" do
    get api_v1_assets_update_url
    assert_response :success
  end

  test "should get destroy" do
    get api_v1_assets_destroy_url
    assert_response :success
  end
end

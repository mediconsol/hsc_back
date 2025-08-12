require "test_helper"

class Api::V1::ConversationHistoriesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get api_v1_conversation_histories_index_url
    assert_response :success
  end

  test "should get show" do
    get api_v1_conversation_histories_show_url
    assert_response :success
  end

  test "should get create" do
    get api_v1_conversation_histories_create_url
    assert_response :success
  end

  test "should get destroy" do
    get api_v1_conversation_histories_destroy_url
    assert_response :success
  end
end

require "test_helper"

class BookAssistantControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get book_assistant_index_url
    assert_response :success
  end
end

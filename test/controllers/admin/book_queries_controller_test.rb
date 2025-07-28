require "test_helper"

class Admin::BookQueriesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_book_queries_index_url
    assert_response :success
  end

  test "should get show" do
    get admin_book_queries_show_url
    assert_response :success
  end
end

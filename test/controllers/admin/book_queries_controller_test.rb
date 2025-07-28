require "test_helper"

module Admin
  class BookQueriesControllerTest < ActionDispatch::IntegrationTest
    test "should get index" do
      get admin_book_queries_url

      assert_response :success
    end

    test "should get show" do
      query = BookQuery.create!(query_text: "Test query", success: true)
      get admin_book_query_url(query)

      assert_response :success
    end
  end
end

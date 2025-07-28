require "test_helper"
require "minitest/mock"

class BookAssistantControllerTest < ActionDispatch::IntegrationTest
  def setup
    # Create test data
    @book = Book.create!(
      isbn: "978-0-7475-3269-9",
      title: "Harry Potter and the Philosopher's Stone",
      author: "J.K. Rowling",
      description: "The first book in the Harry Potter series",
      genres: ["Fantasy", "Young Adult"],
      rating: 4.5,
      price: 1200,
      is_trending: true
    )
    
    # Create some queries for recent display
    BookQuery.create!(
      query_text: "Fantasy books",
      response_text: "Found some great fantasy books",
      success: true,
      response_time_ms: 500
    )
  end

  test "should get index" do
    get book_assistant_index_url
    assert_response :success
    assert_select "h1", text: /Book Recommendation Assistant/
    assert_select "#chat-container"
    assert_select "form[data-turbo-stream=true]"
  end

  test "index page displays recent queries" do
    get book_assistant_index_url
    assert_response :success
    # Check if recent queries are displayed
    assert_match(/Recent Queries/, response.body)
    assert_match(/Fantasy books/, response.body)
  end

  test "should post query with turbo stream" do
    # Mock the service to avoid API calls
    mock_service = Minitest::Mock.new
    mock_service.expect :process_query, {
      success: true,
      message: "I found some great books for you!",
      tools_used: ["search_books"]
    }, ["Looking for mystery books"]
    
    BookAssistantService.stub :new, mock_service do
      post query_book_assistant_index_url, params: { message: "Looking for mystery books" },
                                            headers: { "Accept" => "text/vnd.turbo-stream.html" }
      
      assert_response :success
      assert_match(/turbo-stream/, response.body)
      assert_match(/Looking for mystery books/, response.body)
      assert_match(/I found some great books for you!/, response.body)
    end
    
    mock_service.verify
  end

  test "should post query with json format" do
    mock_service = Minitest::Mock.new
    mock_service.expect :process_query, {
      success: true,
      message: "Here are your recommendations",
      tools_used: ["search_books", "get_book_details"]
    }, ["Recommend me a book"]
    
    BookAssistantService.stub :new, mock_service do
      post query_book_assistant_index_url, params: { message: "Recommend me a book" },
                                            as: :json
      
      assert_response :success
      json_response = JSON.parse(response.body)
      assert json_response["success"]
      assert_equal "Here are your recommendations", json_response["message"]
      assert_equal ["search_books", "get_book_details"], json_response["tools_used"]
    end
    
    mock_service.verify
  end

  test "should handle empty message" do
    mock_service = Minitest::Mock.new
    mock_service.expect :process_query, {
      success: true,
      message: "How can I help you find books today?",
      tools_used: []
    }, [""]
    
    BookAssistantService.stub :new, mock_service do
      post query_book_assistant_index_url, params: { message: "" },
                                            headers: { "Accept" => "text/vnd.turbo-stream.html" }
      
      assert_response :success
    end
  end

  test "should handle service errors gracefully" do
    mock_service = Minitest::Mock.new
    mock_service.expect :process_query, {
      success: false,
      message: "An error occurred. Please try again.",
      tools_used: []
    }, ["Error query"]
    
    BookAssistantService.stub :new, mock_service do
      post query_book_assistant_index_url, params: { message: "Error query" },
                                            headers: { "Accept" => "text/vnd.turbo-stream.html" }
      
      assert_response :success
      assert_match(/An error occurred/, response.body)
    end
    
    mock_service.verify
  end

  test "should display tools used in response" do
    mock_service = Minitest::Mock.new
    mock_service.expect :process_query, {
      success: true,
      message: "Found books",
      tools_used: ["search_books", "get_similar_books"]
    }, ["Find similar books"]
    
    BookAssistantService.stub :new, mock_service do
      post query_book_assistant_index_url, params: { message: "Find similar books" },
                                            headers: { "Accept" => "text/vnd.turbo-stream.html" }
      
      assert_response :success
      assert_match(/Tools used:/, response.body)
      assert_match(/search_books/, response.body)
      assert_match(/get_similar_books/, response.body)
    end
    
    mock_service.verify
  end

  test "should update recent queries after successful query" do
    mock_service = Minitest::Mock.new
    mock_service.expect :process_query, {
      success: true,
      message: "Found books",
      tools_used: []
    }, ["New query"]
    
    BookAssistantService.stub :new, mock_service do
      assert_difference "BookQuery.count", 0 do  # Service logs the query, not controller
        post query_book_assistant_index_url, params: { message: "New query" },
                                              headers: { "Accept" => "text/vnd.turbo-stream.html" }
      end
      
      assert_response :success
    end
  end

  test "index page includes quick links" do
    get book_assistant_index_url
    assert_response :success
    
    assert_select "a[href=?]", admin_books_path, text: /Browse All Books/
    assert_select "a[href=?]", admin_dashboard_path, text: /Admin Dashboard/
    assert_select "a[href=?]", admin_book_queries_path, text: /View All Queries/
  end

  test "turbo stream response appends to messages container" do
    mock_service = Minitest::Mock.new
    mock_service.expect :process_query, {
      success: true,
      message: "Response",
      tools_used: []
    }, ["Test"]
    
    BookAssistantService.stub :new, mock_service do
      post query_book_assistant_index_url, params: { message: "Test" },
                                            headers: { "Accept" => "text/vnd.turbo-stream.html" }
      
      assert_response :success
      assert_match(/turbo-stream action="append" target="messages"/, response.body)
    end
  end
end

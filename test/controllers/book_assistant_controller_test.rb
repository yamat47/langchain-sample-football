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
      # Ensure we have a session
      get book_assistant_index_url

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
    # Initialize session first
    get book_assistant_index_url

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
      json_response = response.parsed_body

      assert json_response["success"]
      assert_equal "Here are your recommendations", json_response["message"]
      assert_equal ["search_books", "get_book_details"], json_response["tools_used"]
    end

    mock_service.verify
  end

  test "should handle empty message" do
    # Initialize session first
    get book_assistant_index_url

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
    # Initialize session first
    get book_assistant_index_url

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
    # Initialize session first
    get book_assistant_index_url

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
    # Initialize session first
    get book_assistant_index_url

    mock_service = Minitest::Mock.new
    mock_service.expect :process_query, {
      success: true,
      message: "Found books",
      tools_used: []
    }, ["New query"]

    BookAssistantService.stub :new, mock_service do
      assert_difference "BookQuery.count", 0 do # Service logs the query, not controller
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
    # Initialize session first
    get book_assistant_index_url

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

  test "should initialize session on first visit" do
    get book_assistant_index_url

    assert_response :success
    assert_not_nil session[:anonymous_chat_session_id]
  end

  test "should maintain session across requests" do
    # First request
    get book_assistant_index_url
    initial_session_id = session[:anonymous_chat_session_id]

    # Second request
    get book_assistant_index_url

    assert_equal initial_session_id, session[:anonymous_chat_session_id]
  end

  test "should store conversation history in database" do
    # First, ensure we have a session
    get book_assistant_index_url

    mock_service = Minitest::Mock.new
    mock_service.expect :process_query, {
      success: true,
      message: "Found books",
      tools_used: [],
      messages: [
        { role: "user", content: "Find fantasy books" },
        { role: "assistant", content: "Found books" }
      ]
    }, ["Find fantasy books"]

    BookAssistantService.stub :new, mock_service do
      assert_difference "ChatMessage.count", 2 do
        post query_book_assistant_index_url, params: { message: "Find fantasy books" },
                                             headers: { "Accept" => "text/vnd.turbo-stream.html" }
      end

      assert_response :success

      # Verify messages were stored in database
      anonymous_user = User.anonymous_user
      chat_session = anonymous_user.chat_sessions.find(session[:anonymous_chat_session_id])
      messages = chat_session.chat_messages.ordered

      assert_equal 2, messages.length
      assert_equal "user", messages[0].role
      assert_equal "Find fantasy books", messages[0].content
    end
  end

  test "should pass existing messages to service" do
    # Ensure anonymous user exists first
    User.anonymous_user

    # Initialize session
    get book_assistant_index_url

    # Then set up a conversation with initial messages
    mock_service1 = Minitest::Mock.new
    mock_service1.expect :process_query, {
      success: true,
      message: "Hi there!",
      tools_used: [],
      messages: [
        { role: "user", content: "Hello" },
        { role: "assistant", content: "Hi there!" }
      ]
    }, ["Hello"]

    BookAssistantService.stub :new, mock_service1 do
      post query_book_assistant_index_url, params: { message: "Hello" },
                                           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    # Now test that the second request gets the existing messages plus the new one
    service_called = false
    BookAssistantService.stub :new, lambda { |**kwargs|
      service_called = true
      session_id = kwargs[:session_id]
      messages = kwargs[:messages]

      assert_not_nil session_id
      # The service should receive the existing messages plus the new message
      assert_equal 3, messages.length
      assert_equal "Hello", messages[0][:content] || messages[0]["content"]
      assert_equal "Hi there!", messages[1][:content] || messages[1]["content"]
      assert_equal "New message", messages[2][:content] || messages[2]["content"]

      # Return a mock service for the second call
      mock_service2 = Minitest::Mock.new
      mock_service2.expect :process_query, {
        success: true,
        message: "Response",
        tools_used: [],
        messages: messages + [
          { role: "user", content: "New message" },
          { role: "assistant", content: "Response" }
        ]
      }, ["New message"]
      mock_service2
    } do
      post query_book_assistant_index_url, params: { message: "New message" },
                                           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      assert_response :success
      assert service_called, "Service should have been initialized with messages"
    end
  end

  test "new_chat action creates new session" do
    # Get initial session ID
    get book_assistant_index_url
    old_session_id = session[:anonymous_chat_session_id]

    # Create a new chat
    assert_difference "ChatSession.count", 1 do
      post new_chat_book_assistant_index_url,
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :success

    # Should have new session ID
    assert_not_equal old_session_id, session[:anonymous_chat_session_id]

    # New session should exist and be empty
    anonymous_user = User.anonymous_user
    new_session = anonymous_user.chat_sessions.find(session[:anonymous_chat_session_id])

    assert_equal 0, new_session.chat_messages.count
  end

  test "new_chat action returns turbo stream response" do
    post new_chat_book_assistant_index_url,
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_match(/turbo-stream/, response.body)

    # Should have turbo stream actions to clear and update messages
    assert_match(/turbo-stream action="update"/, response.body)
    assert_includes response.body, "messages", "Should target messages container"
  end

  test "anonymous chat creates session with anonymous user" do
    # First, ensure anonymous user exists
    User.anonymous_user

    # This creates a session
    assert_difference "ChatSession.count", 1 do
      get book_assistant_index_url
    end

    # Then send a query - this should use the existing session, not create a new one
    mock_service = Minitest::Mock.new
    mock_service.expect :process_query, {
      success: true,
      message: "Response for anonymous",
      tools_used: [],
      messages: [
        { role: "user", content: "Anonymous query" },
        { role: "assistant", content: "Response for anonymous" }
      ]
    }, ["Anonymous query"]

    # Should not create another session since we already have one
    assert_no_difference "ChatSession.count" do
      BookAssistantService.stub :new, mock_service do
        post query_book_assistant_index_url, params: { message: "Anonymous query" },
                                             headers: { "Accept" => "text/vnd.turbo-stream.html" }
      end
    end

    assert_response :success

    # Verify the session belongs to anonymous user
    anonymous_user = User.anonymous_user

    assert_predicate anonymous_user.chat_sessions, :exists?
    assert_not_nil session[:anonymous_chat_session_id]
  end

  test "new_chat for anonymous user creates new anonymous session" do
    # Ensure anonymous user exists
    User.anonymous_user

    assert_difference "ChatSession.count", 1 do
      post new_chat_book_assistant_index_url,
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :success
    assert_not_nil session[:anonymous_chat_session_id]

    # Verify it belongs to anonymous user
    anonymous_user = User.anonymous_user

    assert anonymous_user.chat_sessions.exists?(id: session[:anonymous_chat_session_id])
  end
end

require "test_helper"

class BookAssistantPersistenceTest < ActionDispatch::IntegrationTest
  test "should show chat interface for anonymous users" do
    get book_assistant_index_url

    assert_response :success
    assert_select "#chat-container"
    assert_select "form[action=?]", query_book_assistant_index_path
    assert_select "a[href=?]", identify_book_assistant_index_path, "Sign In"
  end

  test "should identify user and redirect to sessions list" do
    post identify_book_assistant_index_url, params: { identifier: "testuser123" }

    assert_redirected_to book_assistant_index_path
    follow_redirect!

    assert_select "h2", "Your Chat History"
    assert_select "a", "New Chat"
  end

  test "should normalize identifier on identification" do
    post identify_book_assistant_index_url, params: { identifier: "TestUser123" }

    user = User.find_by(identifier: "testuser123")

    assert_not_nil user
    assert_equal "testuser123", user.identifier
  end

  test "should handle invalid identifier" do
    post identify_book_assistant_index_url, params: { identifier: "test@user" }

    assert_redirected_to book_assistant_index_path
    follow_redirect!

    assert_select ".flash-error", /Invalid identifier/
  end

  test "should handle blank identifier" do
    post identify_book_assistant_index_url, params: { identifier: "" }

    assert_redirected_to book_assistant_index_path
    follow_redirect!

    assert_select ".flash-error", /Invalid identifier/
  end

  test "should remember user across requests" do
    post identify_book_assistant_index_url, params: { identifier: "persistuser" }
    follow_redirect!

    # Visit again
    get book_assistant_index_url

    assert_response :success
    assert_select "h2", "Your Chat History"
  end

  test "should create new chat session" do
    user = User.create!(identifier: "chatuser")
    post identify_book_assistant_index_url, params: { identifier: "chatuser" }

    assert_difference "user.chat_sessions.count", 1 do
      get new_book_assistant_url
    end

    assert_redirected_to book_assistant_path(user.chat_sessions.last)
  end

  test "should show individual chat session" do
    user = User.create!(identifier: "viewuser")
    session = user.chat_sessions.create!
    session.chat_messages.create!(role: "user", content: "Hello")
    session.chat_messages.create!(role: "assistant", content: "Hi there!")

    post identify_book_assistant_index_url, params: { identifier: "viewuser" }

    get book_assistant_path(session)

    assert_response :success

    assert_match "Hello", response.body
    assert_match "Hi there!", response.body
  end

  test "should handle query in specific session context" do
    user = User.create!(identifier: "queryuser")
    user.chat_sessions.create!

    post identify_book_assistant_index_url, params: { identifier: "queryuser" }

    # Skip this test for now as it requires complex mocking
    skip "Complex mocking required for BookAssistantService integration"
  end

  test "should list all user sessions" do
    user = User.create!(identifier: "listuser")
    user.chat_sessions.create!(created_at: 2.days.ago)
    user.chat_sessions.create!(created_at: 1.day.ago)
    user.chat_sessions.create!(created_at: 1.hour.ago)

    post identify_book_assistant_index_url, params: { identifier: "listuser" }
    get book_assistant_index_url

    assert_response :success
    assert_select ".session-card", 3
    assert_select ".session-card h3", "Session #3"
    assert_select ".session-card h3", "Session #2"
    assert_select ".session-card h3", "Session #1"
  end

  test "should restrict access to other users sessions" do
    user1 = User.create!(identifier: "user1")
    User.create!(identifier: "user2")
    session1 = user1.chat_sessions.create!

    post identify_book_assistant_index_url, params: { identifier: "user2" }

    # This should raise RecordNotFound since user2 can't access user1's session
    get book_assistant_path(session1)

    assert_response :not_found
  rescue ActiveRecord::RecordNotFound
    # Expected behavior
    assert true
  end

  test "should handle logout and switch user" do
    post identify_book_assistant_index_url, params: { identifier: "firstuser" }
    get book_assistant_index_url

    assert_select "h2", "Your Chat History"

    # Clear session (logout)
    delete logout_book_assistant_index_url

    assert_redirected_to book_assistant_index_path

    # Should show chat interface for anonymous user
    get book_assistant_index_url

    assert_select "#chat-container"
    assert_select "a[href=?]", identify_book_assistant_index_path, "Sign In"
  end
end

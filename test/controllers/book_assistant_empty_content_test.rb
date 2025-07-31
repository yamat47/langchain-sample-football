# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class BookAssistantEmptyContentTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(identifier: "testuser123")
    @chat_session = @user.chat_sessions.create!

    # Set session to authenticate the user
    post identify_book_assistant_index_path, params: { identifier: @user.identifier }
  end

  test "should handle blocks response without text content" do
    # Mock the BookAssistantService to return blocks without text
    mock_service = Minitest::Mock.new
    mock_service.expect :process_query, {
      success: true,
      blocks: [
        {
          "type" => "book_card",
          "content" => {
            "isbn" => "978-0-12345-678-9",
            "title" => "Test Book",
            "author" => "Test Author",
            "rating" => 4.5
          }
        }
      ],
      message: "", # Empty message
      tools_used: [],
      timestamp: Time.current,
      messages: []
    }, ["Find a book"]

    BookAssistantService.stub :new, mock_service do
      post query_book_assistant_index_path, params: {
        message: "Find a book"
      }, headers: {
        "Accept" => "text/vnd.turbo-stream.html"
      }, as: :turbo_stream

      assert_response :success

      # Verify the message was saved with fallback content
      last_message = @chat_session.chat_messages.last

      assert_equal "assistant", last_message.role
      assert_equal "I've found some book recommendations for you.", last_message.content
    end

    mock_service.verify
  end

  test "should handle blocks response with extracted text content" do
    # Mock the BookAssistantService to return blocks with text
    mock_service = Minitest::Mock.new
    mock_service.expect :process_query, {
      success: true,
      blocks: [
        {
          "type" => "text",
          "content" => {
            "markdown" => "Here are your recommendations:"
          }
        },
        {
          "type" => "book_card",
          "content" => {
            "isbn" => "978-0-12345-678-9",
            "title" => "Test Book",
            "author" => "Test Author",
            "rating" => 4.5
          }
        }
      ],
      message: "Here are your recommendations:", # Extracted text
      tools_used: [],
      timestamp: Time.current,
      messages: []
    }, ["Find a book"]

    BookAssistantService.stub :new, mock_service do
      post query_book_assistant_index_path, params: {
        message: "Find a book"
      }, headers: {
        "Accept" => "text/vnd.turbo-stream.html"
      }, as: :turbo_stream

      assert_response :success

      # Verify the message was saved with extracted content
      last_message = @chat_session.chat_messages.last

      assert_equal "assistant", last_message.role
      assert_equal "Here are your recommendations:", last_message.content
    end

    mock_service.verify
  end
end

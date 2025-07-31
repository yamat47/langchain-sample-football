# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class MixedBlocksDisplayTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(identifier: "testuser456")
    post identify_book_assistant_index_path, params: { identifier: @user.identifier }
    @chat_session = @user.chat_sessions.create!
  end

  test "displays alternating text and book blocks correctly" do
    # Mock service to return mixed blocks
    mock_service = Minitest::Mock.new
    mock_service.expect :process_query, {
      success: true,
      blocks: [
        {
          "type" => "text",
          "content" => { "markdown" => "Here's a great book for you:" }
        },
        {
          "type" => "book_card",
          "content" => {
            "isbn" => "978-test-12345",
            "title" => "Test Book Title",
            "author" => "Test Author",
            "rating" => 4.5,
            "genres" => ["Fiction", "Adventure"],
            "price" => 24.99,
            "image_url" => "https://example.com/test-book.jpg",
            "description" => "An amazing adventure story"
          }
        },
        {
          "type" => "text",
          "content" => { "markdown" => "This book has won multiple awards. You might also enjoy:" }
        },
        {
          "type" => "book_list",
          "content" => {
            "title" => "Similar Books",
            "books" => [
              {
                "isbn" => "978-similar-1",
                "title" => "Similar Book 1",
                "author" => "Author 1",
                "rating" => 4.3,
                "genres" => ["Fiction"],
                "image_url" => "https://example.com/similar1.jpg"
              },
              {
                "isbn" => "978-similar-2",
                "title" => "Similar Book 2",
                "author" => "Author 2",
                "rating" => 4.6,
                "genres" => ["Adventure"],
                "image_url" => "https://example.com/similar2.jpg"
              }
            ]
          }
        },
        {
          "type" => "text",
          "content" => { "markdown" => "Happy reading!" }
        }
      ],
      message: "Here's a great book for you:",
      tools_used: [],
      timestamp: Time.current,
      messages: []
    }, ["Show me a book recommendation"]

    BookAssistantService.stub :new, mock_service do
      post query_book_assistant_index_path, params: {
        message: "Show me a book recommendation"
      }, headers: {
        "Accept" => "text/vnd.turbo-stream.html"
      }, as: :turbo_stream

      assert_response :success
      
      # Check that response contains expected structure
      assert_match(/text-block/, response.body)
      assert_match(/book-card/, response.body)
      assert_match(/book-list/, response.body)
      
      # Check specific content
      assert_match(/Test Book Title/, response.body)
      assert_match(/Test Author/, response.body)
      assert_match(/multiple awards/, response.body)
      assert_match(/Similar Books/, response.body)
      assert_match(/Happy reading!/, response.body)
    end

    mock_service.verify
  end

  test "displays book card first pattern correctly" do
    mock_service = Minitest::Mock.new
    mock_service.expect :process_query, {
      success: true,
      blocks: [
        {
          "type" => "book_card",
          "content" => {
            "isbn" => "978-quick-answer",
            "title" => "The Quick Answer",
            "author" => "Direct Author",
            "rating" => 5.0,
            "genres" => ["Reference"],
            "price" => 19.99,
            "image_url" => "https://example.com/quick.jpg"
          }
        },
        {
          "type" => "text",
          "content" => { "markdown" => "This is exactly what you were looking for!" }
        }
      ],
      message: "The Quick Answer",
      tools_used: [],
      timestamp: Time.current,
      messages: []
    }, ["That book we discussed"]

    BookAssistantService.stub :new, mock_service do
      post query_book_assistant_index_path, params: {
        message: "That book we discussed"
      }, headers: {
        "Accept" => "text/vnd.turbo-stream.html"
      }, as: :turbo_stream

      assert_response :success
      
      # Verify book card appears before text
      body = response.body
      book_card_index = body.index('book-card')
      text_block_index = body.index('exactly what you were looking for')
      
      assert_not_nil book_card_index
      assert_not_nil text_block_index
      assert book_card_index < text_block_index, "Book card should appear before explanatory text"
    end

    mock_service.verify
  end
end
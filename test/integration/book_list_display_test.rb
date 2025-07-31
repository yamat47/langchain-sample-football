# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class BookListDisplayTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(identifier: "testuser456")
    post identify_book_assistant_index_path, params: { identifier: @user.identifier }
    @chat_session = @user.chat_sessions.create!
  end

  test "displays book_list block correctly" do
    mock_service = Minitest::Mock.new
    mock_service.expect :process_query, {
      success: true,
      blocks: [
        {
          "type" => "text",
          "content" => { "markdown" => "Here are some great mystery novels I recommend:" }
        },
        {
          "type" => "book_list",
          "content" => {
            "title" => "Top Mystery Picks",
            "books" => [
              {
                "isbn" => "978-0-00-752773-7",
                "title" => "The Girl on the Train",
                "author" => "Paula Hawkins",
                "rating" => 4.0,
                "genres" => ["Mystery", "Thriller"],
                "price" => 14.99,
                "image_url" => "https://example.com/book1.jpg",
                "description" => "A psychological thriller about obsession and memory"
              },
              {
                "isbn" => "978-0-385-53978-1",
                "title" => "Gone Girl",
                "author" => "Gillian Flynn",
                "rating" => 4.2,
                "genres" => ["Mystery", "Thriller"],
                "price" => 16.99,
                "image_url" => "https://example.com/book2.jpg",
                "description" => "A twisted tale of a marriage gone terribly wrong"
              },
              {
                "isbn" => "978-0-307-58837-1",
                "title" => "The Girl with the Dragon Tattoo",
                "author" => "Stieg Larsson",
                "rating" => 4.3,
                "genres" => ["Mystery", "Crime"],
                "price" => 15.99,
                "image_url" => "https://example.com/book3.jpg",
                "description" => "A gripping Nordic noir mystery"
              }
            ]
          }
        },
        {
          "type" => "text",
          "content" => { "markdown" => "Would you like more recommendations or details about any of these books?" }
        }
      ],
      message: "Here are some great mystery novels I recommend:",
      tools_used: [],
      timestamp: Time.current,
      messages: []
    }, ["Recommend me some mystery books"]

    BookAssistantService.stub :new, mock_service do
      post query_book_assistant_index_path, params: {
        message: "Recommend me some mystery books"
      }, headers: {
        "Accept" => "text/vnd.turbo-stream.html"
      }, as: :turbo_stream

      assert_response :success

      # Check book_list structure
      assert_match(/book-list/, response.body)
      assert_match(/Top Mystery Picks/, response.body)

      # Check all books are displayed
      assert_match(/The Girl on the Train/, response.body)
      assert_match(/Paula Hawkins/, response.body)
      assert_match(/Gone Girl/, response.body)
      assert_match(/Gillian Flynn/, response.body)
      assert_match(/The Girl with the Dragon Tattoo/, response.body)
      assert_match(/Stieg Larsson/, response.body)

      # Check book cards within list
      assert_match(/book-card/, response.body)
      assert_match(/\$14\.99/, response.body)
      assert_match(/\$16\.99/, response.body)
      assert_match(/\$15\.99/, response.body)
    end

    mock_service.verify
  end

  test "displays book_list without title" do
    mock_service = Minitest::Mock.new
    mock_service.expect :process_query, {
      success: true,
      blocks: [
        {
          "type" => "book_list",
          "content" => {
            "title" => nil,
            "books" => [
              {
                "isbn" => "978-simple",
                "title" => "Simple Book",
                "author" => "Test Author",
                "rating" => 4.0,
                "genres" => ["Fiction"],
                "price" => 9.99,
                "image_url" => nil,
                "description" => "A test book"
              }
            ]
          }
        }
      ],
      message: "Simple Book",
      tools_used: [],
      timestamp: Time.current,
      messages: []
    }, ["Simple book list"]

    BookAssistantService.stub :new, mock_service do
      post query_book_assistant_index_path, params: {
        message: "Simple book list"
      }, headers: {
        "Accept" => "text/vnd.turbo-stream.html"
      }, as: :turbo_stream

      assert_response :success

      # Should show book list without title
      assert_match(/book-list/, response.body)
      assert_match(/Simple Book/, response.body)

      # Should not have h3 title
      assert_no_match(%r{<h3></h3>}, response.body)
    end

    mock_service.verify
  end
end

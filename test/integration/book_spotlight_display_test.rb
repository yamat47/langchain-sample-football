# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class BookSpotlightDisplayTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(identifier: "testuser789")
    post identify_book_assistant_index_path, params: { identifier: @user.identifier }
    @chat_session = @user.chat_sessions.create!
  end

  test "displays book spotlight block correctly" do
    mock_service = Minitest::Mock.new
    mock_service.expect :process_query, {
      success: true,
      blocks: [
        {
          "type" => "text",
          "content" => { "markdown" => "I have an exceptional recommendation for you:" }
        },
        {
          "type" => "book_spotlight",
          "content" => {
            "isbn" => "978-0-545-01022-1",
            "title" => "The Hunger Games",
            "author" => "Suzanne Collins",
            "rating" => 4.5,
            "genres" => ["Young Adult", "Dystopian", "Adventure"],
            "price" => 17.99,
            "image_url" => "https://example.com/hunger-games.jpg",
            "description" => "A thrilling dystopian novel",
            "extended_description" => "In the ruins of a place once known as North America lies the nation of Panem, a shining Capitol surrounded by twelve outlying districts. The Capitol keeps the districts in line by forcing them all to send one boy and one girl between the ages of twelve and eighteen to participate in the annual Hunger Games, a fight to the death on live TV.",
            "key_themes" => ["Survival", "Government control", "Media manipulation", "Sacrifice", "Coming of age"],
            "why_recommended" => "This groundbreaking series redefined young adult fiction with its compelling protagonist, intense action, and thought-provoking themes about society, media, and power. Perfect for readers who enjoy fast-paced narratives with deeper meaning.",
            "similar_books" => ["Divergent", "The Maze Runner", "Red Queen", "The Giver"]
          }
        },
        {
          "type" => "text",
          "content" => { "markdown" => "The series has sold over 100 million copies worldwide and spawned a successful film franchise." }
        }
      ],
      message: "I have an exceptional recommendation for you:",
      tools_used: [],
      timestamp: Time.current,
      messages: []
    }, ["Tell me about The Hunger Games"]

    BookAssistantService.stub :new, mock_service do
      post query_book_assistant_index_path, params: {
        message: "Tell me about The Hunger Games"
      }, headers: {
        "Accept" => "text/vnd.turbo-stream.html"
      }, as: :turbo_stream

      assert_response :success
      
      # Check spotlight-specific elements
      assert_match(/book-spotlight/, response.body)
      assert_match(/The Hunger Games/, response.body)
      assert_match(/Suzanne Collins/, response.body)
      
      # Check extended content sections
      assert_match(/Overview/, response.body)
      assert_match(/Synopsis/, response.body)
      assert_match(/Key Themes/, response.body)
      assert_match(/Why This Book\?/, response.body)
      assert_match(/If You Like This, Try:/, response.body)
      
      # Check specific content
      assert_match(/nation of Panem/, response.body)
      assert_match(/Survival/, response.body)
      assert_match(/Government control/, response.body)
      assert_match(/Divergent/, response.body)
      assert_match(/100 million copies/, response.body)
    end

    mock_service.verify
  end

  test "displays book spotlight without optional fields" do
    mock_service = Minitest::Mock.new
    mock_service.expect :process_query, {
      success: true,
      blocks: [
        {
          "type" => "book_spotlight",
          "content" => {
            "isbn" => "978-simple-book",
            "title" => "Simple Book",
            "author" => "Basic Author",
            "rating" => 4.0,
            "genres" => ["Fiction"],
            "price" => 15.99,
            "image_url" => nil,
            "description" => "A simple book",
            "extended_description" => nil,
            "key_themes" => [],
            "why_recommended" => nil,
            "similar_books" => []
          }
        }
      ],
      message: "Simple Book",
      tools_used: [],
      timestamp: Time.current,
      messages: []
    }, ["Simple book"]

    BookAssistantService.stub :new, mock_service do
      post query_book_assistant_index_path, params: {
        message: "Simple book"
      }, headers: {
        "Accept" => "text/vnd.turbo-stream.html"
      }, as: :turbo_stream

      assert_response :success
      
      # Should show basic info
      assert_match(/Simple Book/, response.body)
      assert_match(/Basic Author/, response.body)
      assert_match(/No cover available/, response.body)
      
      # Should not show optional sections
      assert_no_match(/Key Themes/, response.body)
      assert_no_match(/Why This Book\?/, response.body)
      assert_no_match(/If You Like This, Try:/, response.body)
    end

    mock_service.verify
  end
end
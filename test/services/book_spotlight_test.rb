# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class BookSpotlightTest < ActiveSupport::TestCase
  def setup
    @book = Book.create!(
      isbn: "978-spotlight-test",
      title: "The Spotlight Book",
      author: "Featured Author",
      genres: ["Mystery", "Thriller"],
      rating: 4.8,
      price: 24.99,
      image_url: "https://example.com/spotlight.jpg",
      description: "A gripping mystery that keeps you guessing"
    )

    # Create some reviews for the book
    5.times do |i|
      @book.reviews.create!(
        reviewer_name: "Reviewer #{i + 1}",
        content: "Great book!",
        rating: 5
      )
    end
  end

  test "book_to_spotlight creates complete spotlight block" do
    spotlight = BookRecommendationParser.book_to_spotlight(@book)

    assert_equal "book_spotlight", spotlight[:type]

    content = spotlight[:content]

    assert_equal @book.isbn, content[:isbn]
    assert_equal @book.title, content[:title]
    assert_equal @book.author, content[:author]
    assert_equal @book.rating, content[:rating]
    assert_equal 5, content[:review_count] # We created 5 reviews
    assert_equal ["Mystery", "Thriller"], content[:genres]
    assert_equal @book.price, content[:price]
    assert_equal @book.image_url, content[:image_url]

    # Check auto-generated fields
    assert_not_nil content[:extended_description]
    assert_includes content[:extended_description], "The Spotlight Book"

    assert_not_nil content[:key_themes]
    assert_includes content[:key_themes], "Suspense and intrigue"

    assert_not_nil content[:why_recommended]
    assert_includes content[:why_recommended], "5.0 star rating" # Book's rating is 5.0 in DB due to validation
  end

  test "book_to_spotlight accepts custom values" do
    custom_description = "An extended tale of mystery and suspense..."
    custom_themes = ["Psychological depth", "Unreliable narrator", "Time loops"]
    custom_reason = "This book redefined the mystery genre"
    custom_similar = ["Book A", "Book B", "Book C"]

    spotlight = BookRecommendationParser.book_to_spotlight(
      @book,
      extended_description: custom_description,
      key_themes: custom_themes,
      why_recommended: custom_reason,
      similar_books: custom_similar
    )

    content = spotlight[:content]

    assert_equal custom_description, content[:extended_description]
    assert_equal custom_themes, content[:key_themes]
    assert_equal custom_reason, content[:why_recommended]
    assert_equal custom_similar, content[:similar_books]
  end

  test "service can process book_spotlight blocks" do
    service = BookAssistantService.new

    mock_assistant = Minitest::Mock.new
    def mock_assistant.add_message_and_run(content:, auto_tool_execution: true)
      response_json = {
        blocks: [
          {
            type: "text",
            content: { markdown: "I have the perfect book recommendation for you:" }
          },
          {
            type: "book_spotlight",
            content: {
              isbn: "978-spotlight-test",
              title: "The Spotlight Book",
              author: "Featured Author",
              rating: 4.8,
              genres: ["Mystery", "Thriller"],
              price: 24.99,
              image_url: "https://example.com/spotlight.jpg",
              description: "A gripping mystery",
              extended_description: "This psychological thriller follows detective Sarah Chen...",
              key_themes: ["Identity", "Justice", "Redemption", "Trust"],
              why_recommended: "Perfect for readers who enjoyed Gone Girl and The Girl on the Train",
              similar_books: ["Gone Girl", "The Girl on the Train", "The Silent Patient"]
            }
          },
          {
            type: "text",
            content: { markdown: "This book has won multiple awards and is being adapted for film." }
          }
        ]
      }.to_json

      [OpenStruct.new(content: response_json, tool_calls: nil)]
    end

    service.stub :build_assistant_with_blocks_instructions, mock_assistant do
      result = service.process_query("Tell me about The Spotlight Book in detail")

      assert result[:success]
      assert_not_nil result[:blocks]
      assert_equal 3, result[:blocks].size

      # Check spotlight block
      spotlight_block = result[:blocks][1]

      assert_equal "book_spotlight", spotlight_block["type"]
      assert_equal "The Spotlight Book", spotlight_block["content"]["title"]
      assert_equal 4, spotlight_block["content"]["key_themes"].size
      assert_equal 3, spotlight_block["content"]["similar_books"].size
    end
  end

  test "extract_themes_from_book returns appropriate themes by genre" do
    # Test different genres
    genres_and_themes = {
      ["Mystery", "Thriller"] => "Suspense and intrigue",
      ["Fantasy"] => "Magic and wonder",
      ["Science Fiction"] => "Future technology",
      ["Romance"] => "Love and relationships"
    }

    genres_and_themes.each do |genres, expected_theme|
      book = Book.new(genres: genres)
      themes = BookRecommendationParser.extract_themes_from_book(book)

      assert_includes themes.first, expected_theme
    end
  end
end

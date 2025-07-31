# frozen_string_literal: true

require "test_helper"

class BookRecommendationParserTest < ActiveSupport::TestCase
  def setup
    @parser = BookRecommendationParser.new
  end

  test "returns schema for block-based responses" do
    schema = BookRecommendationParser.schema

    assert_equal "object", schema[:type]
    assert_includes schema[:properties], :blocks
    assert_equal "array", schema[:properties][:blocks][:type]
    assert_includes schema[:required], "blocks"
  end

  test "block schema includes all required types" do
    schema = BookRecommendationParser.schema
    block_schema = schema[:properties][:blocks][:items]

    assert_equal "object", block_schema[:type]
    assert_includes block_schema[:properties], :type
    assert_includes block_schema[:properties], :content
    assert_equal ["text", "book_card", "book_list", "image"], block_schema[:properties][:type][:enum]
  end

  test "creates structured output parser instance" do
    parser = BookRecommendationParser.create_parser

    assert_instance_of Langchain::OutputParsers::StructuredOutputParser, parser
    assert_match(/blocks/, parser.get_format_instructions)
  end

  test "provides format instructions" do
    instructions = BookRecommendationParser.format_instructions

    assert_includes instructions, "You MUST respond with a JSON object"
    assert_includes instructions, "blocks"
    assert_includes instructions, "text"
    assert_includes instructions, "book_card"
    assert_includes instructions, "book_list"
  end

  test "parses valid block response" do
    response = {
      blocks: [
        {
          type: "text",
          content: {
            markdown: "Here are some book recommendations:"
          }
        },
        {
          type: "book_card",
          content: {
            isbn: "978-1234567890",
            title: "Test Book",
            author: "Test Author",
            rating: 4.5,
            review_count: 100,
            genres: ["Fiction"],
            price: 19.99,
            image_url: "https://example.com/book.jpg",
            description: "A great book"
          }
        }
      ]
    }

    parsed = @parser.parse_response(response.to_json)

    assert_equal 2, parsed[:blocks].size
    assert_equal "text", parsed[:blocks][0][:type]
    assert_equal "book_card", parsed[:blocks][1][:type]
    assert_equal "Test Book", parsed[:blocks][1][:content][:title]
  end

  test "validates block types" do
    response = {
      blocks: [
        {
          type: "invalid_type",
          content: {}
        }
      ]
    }

    assert_raises(BookRecommendationParser::InvalidBlockTypeError) do
      @parser.parse_response(response.to_json)
    end
  end

  test "handles missing required fields gracefully" do
    response = {
      blocks: [
        {
          type: "book_card",
          content: {
            title: "Test Book"
            # Missing required fields
          }
        }
      ]
    }

    parsed = @parser.parse_response(response.to_json, validate: false)

    assert_equal "Test Book", parsed[:blocks][0][:content][:title]
    assert_nil parsed[:blocks][0][:content][:author]
  end

  test "extracts text content from blocks" do
    blocks = [
      {
        type: "text",
        content: { markdown: "First text" }
      },
      {
        type: "book_card",
        content: { title: "Book" }
      },
      {
        type: "text",
        content: { markdown: "Second text" }
      }
    ]

    text = BookRecommendationParser.extract_text_content(blocks)

    assert_equal "First text\n\nSecond text", text
  end

  test "converts book data to block format" do
    book = Book.create!(
      isbn: "978-1234567890",
      title: "Test Book",
      author: "Test Author",
      image_url: "https://example.com/book.jpg",
      rating: 4.5,
      genres: ["Fiction", "Adventure"],
      price: 19.99,
      description: "An exciting adventure"
    )

    block = BookRecommendationParser.book_to_block(book)

    assert_equal "book_card", block[:type]
    assert_equal book.isbn, block[:content][:isbn]
    assert_equal book.title, block[:content][:title]
    assert_equal book.author, block[:content][:author]
    assert_equal book.rating, block[:content][:rating]
    assert_equal book.image_url, block[:content][:image_url]
    assert_equal book.review_count, block[:content][:review_count]
  end

  test "creates book list block from multiple books" do
    book1 = Book.create!(
      isbn: "978-1111111111",
      title: "First Book",
      author: "First Author"
    )
    book2 = Book.create!(
      isbn: "978-2222222222",
      title: "Second Book",
      author: "Second Author"
    )

    block = BookRecommendationParser.books_to_list_block([book1, book2], title: "Recommended Books")

    assert_equal "book_list", block[:type]
    assert_equal "Recommended Books", block[:content][:title]
    assert_equal 2, block[:content][:books].size
    assert_equal book1.title, block[:content][:books][0][:title]
    assert_equal book2.title, block[:content][:books][1][:title]
  end
end

# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class BookMixedBlocksTest < ActiveSupport::TestCase
  class MockMessage
    attr_accessor :content, :role

    def initialize(content, role = "assistant")
      @content = content
      @role = role
    end
  end

  def setup
    @service = BookAssistantService.new
  end

  test "should handle alternating text and book_card blocks" do
    # Mock response with alternating blocks
    mock_blocks_assistant = Minitest::Mock.new
    def mock_blocks_assistant.add_message_and_run(content:, auto_tool_execution: true)
      response_json = {
        blocks: [
          {
            type: "text",
            content: { markdown: "I found the perfect book for you:" }
          },
          {
            type: "book_card",
            content: {
              isbn: "978-0-12345-678-9",
              title: "The Mystery of Testing",
              author: "Test Author",
              rating: 4.8,
              genres: ["Mystery", "Thriller"],
              price: 24.99,
              image_url: "https://example.com/book1.jpg",
              description: "A thrilling tale of software testing"
            }
          },
          {
            type: "text",
            content: { markdown: "This book has received rave reviews. Additionally, you might enjoy:" }
          },
          {
            type: "book_card",
            content: {
              isbn: "978-0-98765-432-1",
              title: "Debugging in the Dark",
              author: "Another Author",
              rating: 4.5,
              genres: ["Mystery", "Technology"],
              price: 19.99,
              image_url: "https://example.com/book2.jpg",
              description: "A developer's journey through mysterious bugs"
            }
          },
          {
            type: "text",
            content: { markdown: "Both books explore themes of problem-solving and discovery." }
          }
        ]
      }.to_json

      [BookMixedBlocksTest::MockMessage.new(response_json)]
    end

    @service.stub :build_assistant_with_blocks_instructions, mock_blocks_assistant do
      result = @service.process_query("Show me some mystery books with explanations")

      assert result[:success]
      assert_not_nil result[:blocks]
      assert_equal 5, result[:blocks].size

      # Verify alternating pattern
      assert_equal "text", result[:blocks][0]["type"]
      assert_equal "book_card", result[:blocks][1]["type"]
      assert_equal "text", result[:blocks][2]["type"]
      assert_equal "book_card", result[:blocks][3]["type"]
      assert_equal "text", result[:blocks][4]["type"]

      # Verify content
      assert_match(/perfect book/, result[:blocks][0]["content"]["markdown"])
      assert_equal "The Mystery of Testing", result[:blocks][1]["content"]["title"]
      assert_match(/rave reviews/, result[:blocks][2]["content"]["markdown"])
      assert_equal "Debugging in the Dark", result[:blocks][3]["content"]["title"]
      assert_match(/problem-solving/, result[:blocks][4]["content"]["markdown"])
    end
  end

  test "should handle complex mixed pattern with book_list" do
    mock_blocks_assistant = Minitest::Mock.new
    def mock_blocks_assistant.add_message_and_run(content:, auto_tool_execution: true)
      response_json = {
        blocks: [
          {
            type: "text",
            content: { markdown: "## Your Personalized Reading List\n\nBased on your preferences, here's what I recommend:" }
          },
          {
            type: "book_card",
            content: {
              isbn: "978-1-11111-111-1",
              title: "The Highlighted Pick",
              author: "Featured Author",
              rating: 4.9,
              genres: ["Fiction"],
              price: 29.99,
              image_url: "https://example.com/featured.jpg",
              description: "This month's top recommendation"
            }
          },
          {
            type: "text",
            content: { markdown: "### Why this book?\nIt perfectly matches your interest in character-driven narratives.\n\n### Similar titles you might enjoy:" }
          },
          {
            type: "book_list",
            content: {
              title: "Related Recommendations",
              books: [
                {
                  isbn: "978-2-22222-222-2",
                  title: "Similar Book 1",
                  author: "Author A",
                  rating: 4.3,
                  genres: ["Fiction"],
                  image_url: "https://example.com/similar1.jpg"
                },
                {
                  isbn: "978-3-33333-333-3",
                  title: "Similar Book 2",
                  author: "Author B",
                  rating: 4.6,
                  genres: ["Fiction", "Drama"],
                  image_url: "https://example.com/similar2.jpg"
                }
              ]
            }
          },
          {
            type: "text",
            content: { markdown: "### Reading Order\nI suggest starting with 'The Highlighted Pick' as it provides the best introduction to this genre." }
          }
        ]
      }.to_json

      [BookMixedBlocksTest::MockMessage.new(response_json)]
    end

    @service.stub :build_assistant_with_blocks_instructions, mock_blocks_assistant do
      result = @service.process_query("Give me personalized recommendations")

      assert result[:success]
      assert_not_nil result[:blocks]
      assert_equal 5, result[:blocks].size

      # Verify complex pattern
      assert_equal "text", result[:blocks][0]["type"]
      assert_equal "book_card", result[:blocks][1]["type"]
      assert_equal "text", result[:blocks][2]["type"]
      assert_equal "book_list", result[:blocks][3]["type"]
      assert_equal "text", result[:blocks][4]["type"]

      # Verify markdown formatting in text blocks
      assert_match(/## Your Personalized Reading List/, result[:blocks][0]["content"]["markdown"])
      assert_match(/### Why this book\?/, result[:blocks][2]["content"]["markdown"])
      assert_match(/### Reading Order/, result[:blocks][4]["content"]["markdown"])

      # Verify book_list contains multiple books
      assert_equal 2, result[:blocks][3]["content"]["books"].size
    end
  end

  test "should handle response starting with book_card" do
    mock_blocks_assistant = Minitest::Mock.new
    def mock_blocks_assistant.add_message_and_run(content:, auto_tool_execution: true)
      response_json = {
        blocks: [
          {
            type: "book_card",
            content: {
              isbn: "978-quick-12345",
              title: "Quick Answer Book",
              author: "Direct Author",
              rating: 5.0,
              genres: ["Reference"],
              price: 15.99,
              image_url: "https://example.com/quick.jpg"
            }
          },
          {
            type: "text",
            content: { markdown: "This is exactly what you're looking for!" }
          }
        ]
      }.to_json

      [BookMixedBlocksTest::MockMessage.new(response_json)]
    end

    @service.stub :build_assistant_with_blocks_instructions, mock_blocks_assistant do
      result = @service.process_query("Show me that book we discussed")

      assert result[:success]
      assert_not_nil result[:blocks]
      assert_equal 2, result[:blocks].size

      # Can start with book_card
      assert_equal "book_card", result[:blocks][0]["type"]
      assert_equal "text", result[:blocks][1]["type"]
    end
  end
end

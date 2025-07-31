# frozen_string_literal: true

require "test_helper"

class BookAssistantConversationTest < ActiveSupport::TestCase
  test "conversation history properly extracts text from assistant blocks" do
    service = BookAssistantService.new

    # Add a message with blocks format
    blocks_message = {
      role: "assistant",
      content: {
        blocks: [
          {
            type: "text",
            content: { markdown: "Here are some book recommendations:" }
          },
          {
            type: "book_list",
            content: {
              title: "Mystery Books",
              books: [
                {
                  isbn: "978-test",
                  title: "Test Mystery",
                  author: "Test Author"
                }
              ]
            }
          }
        ]
      }.to_json
    }

    # Test extract_message_content method
    extracted = service.send(:extract_message_content, "assistant", blocks_message[:content])

    assert_equal "Here are some book recommendations:", extracted
  end

  test "conversation history creates summary when no text blocks exist" do
    service = BookAssistantService.new

    # Message with only book_list, no text blocks
    blocks_message = {
      blocks: [
        {
          type: "book_list",
          content: {
            title: "Mystery Books",
            books: [
              { title: "Book 1", author: "Author 1" },
              { title: "Book 2", author: "Author 2" }
            ]
          }
        }
      ]
    }.to_json

    extracted = service.send(:extract_message_content, "assistant", blocks_message)

    assert_equal "I showed you 2 book recommendations.", extracted
  end

  test "conversation history handles non-JSON assistant messages" do
    service = BookAssistantService.new

    # Plain text message
    plain_message = "This is a plain text response"

    extracted = service.send(:extract_message_content, "assistant", plain_message)

    assert_equal plain_message, extracted
  end

  test "conversation history preserves user messages as-is" do
    service = BookAssistantService.new

    user_message = "Show me mystery books"

    extracted = service.send(:extract_message_content, "user", user_message)

    assert_equal user_message, extracted
  end
end

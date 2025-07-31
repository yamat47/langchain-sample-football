require "test_helper"
require "minitest/mock"

class BookAssistantServiceTest < ActiveSupport::TestCase
  class MockMessage
    attr_accessor :content, :role

    def initialize(content, role = "assistant")
      @content = content
      @role = role
    end
  end

  def setup
    # Mock the OpenAI API key to avoid actual API calls
    ENV["OPENAI_API_KEY"] = "test-api-key"

    @service = BookAssistantService.new

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
  end

  test "should initialize with assistant" do
    assert_not_nil @service.instance_variable_get(:@assistant)
    assert_kind_of Langchain::Assistant, @service.instance_variable_get(:@assistant)
  end

  test "should have book_info_tool in available tools" do
    tools = @service.send(:available_tools)
    book_tool = tools.find { |tool| tool.is_a?(BookInfoTool) }

    assert_not_nil book_tool
  end

  test "should conditionally include news_retriever in available tools" do
    # Without NEWS_API_KEY, should only have BookInfoTool
    ENV["NEWS_API_KEY"] = nil
    tools = @service.send(:available_tools)

    assert_equal 1, tools.length
    assert_kind_of BookInfoTool, tools.first

    # With NEWS_API_KEY, should have both tools
    ENV["NEWS_API_KEY"] = "test-news-key"
    tools = @service.send(:available_tools)

    assert_equal 2, tools.length
    assert(tools.any? { |t| t.is_a?(Langchain::Tool::NewsRetriever) })
  end

  test "should have correct assistant instructions" do
    instructions = @service.send(:assistant_instructions)

    assert_includes instructions, "book recommendation assistant"
    assert_includes instructions, "BookInfoTool"
    assert_includes instructions, "NewsRetriever"
  end

  test "process_query returns success response for valid query" do
    skip "Requires valid OpenAI API key for integration test"
  end

  test "process_query logs query to database" do
    mock_response = OpenStruct.new(content: "Response", tool_calls: nil)

    mock_assistant = Minitest::Mock.new
    mock_assistant.expect :add_message_and_run, mock_response, [
      { content: "Test query", auto_tool_execution: true }
    ]

    @service.instance_variable_set(:@assistant, mock_assistant)

    assert_difference "BookQuery.count", 1 do
      @service.process_query("Test query")
    end
  end

  test "process_query handles errors gracefully" do
    # Create a mock assistant that raises an error
    mock_blocks_assistant = Object.new
    
    mock_blocks_assistant.define_singleton_method(:add_message_and_run) do |content:, auto_tool_execution: true|
      raise StandardError, "API Error"
    end
    
    mock_blocks_assistant.define_singleton_method(:add_message) do |role:, content:|
      # No-op for message tracking
    end

    # Stub the build method to return our mock assistant
    @service.stub :build_assistant_with_blocks_instructions, mock_blocks_assistant do
      result = @service.process_query("Test query")

      assert_not result[:success]
      assert_includes result[:message], "encountered an error"
      assert_equal "API Error", result[:error]
    end
  end

  test "process_query tracks response time" do
    mock_response = OpenStruct.new(content: "Response", tool_calls: nil)

    mock_assistant = Minitest::Mock.new
    mock_assistant.expect :add_message_and_run, mock_response, [
      { content: "Test query", auto_tool_execution: true }
    ]

    @service.instance_variable_set(:@assistant, mock_assistant)

    @service.process_query("Test query")

    last_query = BookQuery.last

    assert_not_nil last_query.response_time_ms
    assert_operator last_query.response_time_ms, :>=, 0
  end

  test "build_assistant creates Langchain Assistant" do
    assistant = @service.send(:build_assistant)

    assert_kind_of Langchain::Assistant, assistant
    assert_equal @service.instance_variable_get(:@llm_client), assistant.llm
    assert_not_empty assistant.tools
  end

  test "process_query handles empty query" do
    skip "Requires valid OpenAI API key for integration test"
  end

  test "process_query handles nil query" do
    # BookQuery validation prevents empty query_text
    # So we expect an error to be caught and handled
    result = @service.process_query(nil)

    assert_not_nil result
    assert_not result[:success]
    assert_includes result[:message], "error"
  end

  test "extract_tools_used extracts tool names from response" do
    response = OpenStruct.new(
      content: "Found books",
      tool_calls: [
        { "function" => { "name" => "search_books" } },
        { "function" => { "name" => "get_book_details" } },
        { "function" => { "name" => "search_books" } }
      ]
    )

    result = @service.send(:extract_tools_used, response)

    assert_equal ["search_books", "get_book_details"], result
  end

  test "extract_tools_used handles response without tool_calls" do
    response = OpenStruct.new(content: "Response")
    result = @service.send(:extract_tools_used, response)

    assert_empty result
  end

  test "extract_tools_used handles nil tool_calls" do
    response = OpenStruct.new(content: "Response", tool_calls: nil)
    result = @service.send(:extract_tools_used, response)

    assert_empty result
  end

  test "available_tools returns array of tools" do
    # Create a new service instance to test the method directly
    service = BookAssistantService.new
    tools = service.send(:available_tools)

    assert_kind_of Array, tools
    assert_operator tools.length, :>=, 1
    assert(tools.any? { |t| t.is_a?(BookInfoTool) })
  end

  test "chat method delegates to process_query" do
    skip "Requires valid OpenAI API key for integration test"
  end

  test "should accept session_id and messages in constructor" do
    session_id = "test-session-123"
    messages = [
      { role: "user", content: "Hello" },
      { role: "assistant", content: "Hi there!" }
    ]

    service = BookAssistantService.new(session_id: session_id, messages: messages)

    assert_equal session_id, service.instance_variable_get(:@session_id)
    assert_equal messages, service.instance_variable_get(:@messages)
  end

  test "should initialize with empty messages if not provided" do
    service = BookAssistantService.new

    assert_nil service.instance_variable_get(:@session_id)
    assert_empty service.instance_variable_get(:@messages)
  end

  test "should restore conversation history when building assistant" do
    messages = [
      { role: "user", content: "What books do you recommend?" },
      { role: "assistant", content: "I recommend Harry Potter series." }
    ]

    service = BookAssistantService.new(messages: messages)

    # Mock assistant to verify add_message is called
    mock_assistant = Minitest::Mock.new
    # Define expectations for add_message with keyword arguments
    def mock_assistant.add_message(role:, content:)
      # Track calls for verification
      @calls ||= []
      @calls << { role: role, content: content }
    end

    def mock_assistant.verify_calls
      expected = [
        { role: "user", content: "What books do you recommend?" },
        { role: "assistant", content: "I recommend Harry Potter series." }
      ]
      @calls == expected
    end

    # Replace build_assistant to return our mock
    service.stub :build_assistant, mock_assistant do
      service.send(:build_assistant_with_history)
    end

    assert mock_assistant.verify_calls
  end

  test "process_query should update messages array with user and assistant messages" do
    service = BookAssistantService.new

    # Create mock for book-related queries (structured response)
    mock_blocks_assistant = Object.new

    # Define add_message_and_run to return structured JSON response
    mock_blocks_assistant.define_singleton_method(:add_message_and_run) do |content:, auto_tool_execution: true|
      response_json = {
        blocks: [
          {
            type: "text",
            content: { markdown: "Here are some book recommendations" }
          }
        ]
      }.to_json

      [OpenStruct.new(content: response_json, tool_calls: nil)]
    end

    # Define add_message for history tracking
    mock_blocks_assistant.define_singleton_method(:add_message) do |role:, content:|
      # No-op
    end

    # Mock build_assistant_with_blocks_instructions to return our mock
    service.stub :build_assistant_with_blocks_instructions, mock_blocks_assistant do
      # Verify initial state
      assert_empty service.instance_variable_get(:@messages)

      result = service.process_query("Recommend fantasy books")

      # Check result structure
      assert_not_nil result
      assert result[:success], "Query should succeed: #{result[:error]}"

      messages = result[:messages]

      assert_not_nil messages, "Messages should not be nil"
      assert_equal 2, messages.length, "Should have user and assistant messages"
      assert_equal({ role: "user", content: "Recommend fantasy books" }, messages[0])
      # The assistant message content will be the JSON response
      assert_equal "assistant", messages[1][:role]
      assert_includes messages[1][:content], "blocks"
    end
  end

  test "process_query should maintain conversation history across multiple calls" do
    service = BookAssistantService.new

    # Mock assistant that remembers calls
    call_count = 0
    responses = [
      {
        blocks: [
          {
            type: "text",
            content: { markdown: "I can help with that" }
          }
        ]
      }.to_json,
      {
        blocks: [
          {
            type: "text",
            content: { markdown: "Here are fantasy books" }
          }
        ]
      }.to_json
    ]

    mock_blocks_assistant = Object.new
    mock_blocks_assistant.define_singleton_method(:add_message_and_run) do |content:, auto_tool_execution: true|
      response = responses[call_count]
      call_count += 1
      [OpenStruct.new(content: response, tool_calls: nil)]
    end

    mock_blocks_assistant.define_singleton_method(:add_message) do |role:, content:|
      # No-op for history tracking
    end

    # Mock build_assistant_with_blocks_instructions only
    service.stub :build_assistant_with_blocks_instructions, mock_blocks_assistant do
      # First query - "Hello" now also uses blocks processing
      result1 = service.process_query("Hello")

      assert_equal 2, result1[:messages].length

      # Second query - "Show me fantasy books"
      result2 = service.process_query("Show me fantasy books")

      messages = result2[:messages]

      assert_equal 4, messages.length
      assert_equal "Hello", messages[0][:content]
      # Both messages will now contain JSON blocks
      assert_includes messages[1][:content], "blocks"
      assert_equal "Show me fantasy books", messages[2][:content]
      assert_includes messages[3][:content], "blocks"
    end
  end

  test "should limit message history to prevent token overflow" do
    # Create 25 messages (over the 20 limit)
    messages = []
    25.times do |i|
      messages << { role: "user", content: "Question #{i}" }
      messages << { role: "assistant", content: "Answer #{i}" }
    end

    service = BookAssistantService.new(messages: messages)
    service.send(:limit_message_history!)

    # Should keep only the last 20 messages
    assert_equal 20, service.instance_variable_get(:@messages).length
    # First message should be from question 15 (30 messages removed)
    assert_equal "Question 15", service.instance_variable_get(:@messages).first[:content]
  end

  test "should process book queries with blocks format" do
    service = BookAssistantService.new

    # Create test books
    Book.create!(
      isbn: "978-0-12345-678-9",
      title: "Test Book 1",
      author: "Test Author",
      genres: ["Fiction"],
      rating: 4.5,
      price: 19.99,
      image_url: "https://example.com/book1.jpg"
    )

    # Mock the assistant for blocks processing
    mock_blocks_assistant = Minitest::Mock.new
    def mock_blocks_assistant.add_message_and_run(content:, auto_tool_execution: true)
      # Return a mock message with structured content
      [BookAssistantServiceTest::MockMessage.new('{"blocks":[{"type":"text","content":{"markdown":"Here are some book recommendations:"}},{"type":"book_card","content":{"isbn":"978-0-12345-678-9","title":"Test Book 1","author":"Test Author","rating":4.5,"genres":["Fiction"],"price":19.99,"image_url":"https://example.com/book1.jpg"}}]}')]
    end

    # Stub the method that creates the blocks assistant
    service.stub :build_assistant_with_blocks_instructions, mock_blocks_assistant do
      result = service.process_query("Recommend me some books")

      assert result[:success], "Query should succeed"
      assert_not_nil result[:blocks], "Blocks should not be nil"
      assert_equal 2, result[:blocks].size
      assert_equal "text", result[:blocks][0]["type"]
      assert_equal "book_card", result[:blocks][1]["type"]
      assert_equal "Test Book 1", result[:blocks][1]["content"]["title"]
    end
  end

  test "should fall back to text-only blocks when parsing fails" do
    service = BookAssistantService.new

    # Create a custom mock class for blocks assistant (will fail)
    mock_blocks_assistant = Object.new

    mock_blocks_assistant.define_singleton_method(:add_message_and_run) do |content:, auto_tool_execution: true|
      # Return invalid JSON (will fail parsing)
      [BookAssistantServiceTest::MockMessage.new("{ invalid json }")]
    end

    mock_blocks_assistant.define_singleton_method(:add_message) do |role:, content:|
      # No-op for message tracking
    end

    # Mock the build methods to return our mock assistants
    service.stub :build_assistant_with_blocks_instructions, mock_blocks_assistant do
      result = service.process_query("Tell me about books")

      assert result[:success]
      # The fallback response now has text blocks
      assert_not_nil result[:blocks]
      assert_equal 1, result[:blocks].size
      assert_equal "text", result[:blocks][0]["type"]
      assert_equal "{ invalid json }", result[:blocks][0]["content"]["markdown"]
      assert_equal "{ invalid json }", result[:message]
    end
  end

  test "should handle mixed content responses" do
    service = BookAssistantService.new

    # Mock the assistant for blocks processing
    mock_blocks_assistant = Minitest::Mock.new
    def mock_blocks_assistant.add_message_and_run(content:, auto_tool_execution: true)
      [BookAssistantServiceTest::MockMessage.new('{"blocks":[{"type":"text","content":{"markdown":"I found these mystery books for you:"}},{"type":"book_list","content":{"title":"Top Mystery Novels","books":[{"isbn":"978-1111111111","title":"Mystery Book 1","author":"Author 1","rating":4.2,"genres":["Mystery"],"image_url":"https://example.com/mystery1.jpg"},{"isbn":"978-2222222222","title":"Mystery Book 2","author":"Author 2","rating":4.7,"genres":["Mystery","Thriller"],"image_url":"https://example.com/mystery2.jpg"}]}},{"type":"text","content":{"markdown":"Would you like more recommendations?"}}]}')]
    end

    # Stub the method that creates the blocks assistant
    service.stub :build_assistant_with_blocks_instructions, mock_blocks_assistant do
      result = service.process_query("Show me mystery books")

      assert result[:success]
      assert_not_nil result[:blocks]
      assert_equal 3, result[:blocks].size

      # Check first text block
      assert_equal "text", result[:blocks][0]["type"]
      assert_match(/mystery books/, result[:blocks][0]["content"]["markdown"])

      # Check book list block
      assert_equal "book_list", result[:blocks][1]["type"]
      assert_equal "Top Mystery Novels", result[:blocks][1]["content"]["title"]
      assert_equal 2, result[:blocks][1]["content"]["books"].size

      # Check final text block
      assert_equal "text", result[:blocks][2]["type"]
      assert_match(/more recommendations/, result[:blocks][2]["content"]["markdown"])
    end
  end

  test "should handle blocks response without text content" do
    service = BookAssistantService.new

    # Mock the assistant for blocks processing with no text blocks
    mock_blocks_assistant = Minitest::Mock.new
    def mock_blocks_assistant.add_message_and_run(content:, auto_tool_execution: true)
      [BookAssistantServiceTest::MockMessage.new('{"blocks":[{"type":"book_card","content":{"isbn":"978-0-12345-678-9","title":"Test Book","author":"Test Author","rating":4.5}}]}')]
    end

    # Stub the method that creates the blocks assistant
    service.stub :build_assistant_with_blocks_instructions, mock_blocks_assistant do
      result = service.process_query("Show me a book")

      assert result[:success]
      assert_not_nil result[:blocks]
      assert_equal 1, result[:blocks].size
      assert_equal "book_card", result[:blocks][0]["type"]
      # Should have a default message when no text content
      assert_equal "I've found some book recommendations for you.", result[:message]
    end
  end

  test "should extract JSON from response with surrounding text" do
    service = BookAssistantService.new

    # Mock the assistant that returns JSON with surrounding text
    mock_blocks_assistant = Minitest::Mock.new
    def mock_blocks_assistant.add_message_and_run(content:, auto_tool_execution: true)
      response_with_text = 'Here are some books for you:\n\n{"blocks":[{"type":"text","content":{"markdown":"I found these great books:"}},{"type":"book_list","content":{"title":"Mystery Books","books":[{"isbn":"978-1234567890","title":"Mystery Book","author":"Mystery Author","rating":4.5,"genres":["Mystery"],"price":19.99,"image_url":"https://example.com/book.jpg"}]}}]}\n\nEnjoy reading!'
      [BookAssistantServiceTest::MockMessage.new(response_with_text)]
    end

    # Stub the method that creates the blocks assistant
    service.stub :build_assistant_with_blocks_instructions, mock_blocks_assistant do
      result = service.process_query("Show me mystery books")

      assert result[:success]
      assert_not_nil result[:blocks]
      assert_equal 2, result[:blocks].size
      assert_equal "text", result[:blocks][0]["type"]
      assert_equal "book_list", result[:blocks][1]["type"]
      assert_equal "I found these great books:", result[:blocks][0]["content"]["markdown"]
      assert_equal "Mystery Books", result[:blocks][1]["content"]["title"]
    end
  end
end

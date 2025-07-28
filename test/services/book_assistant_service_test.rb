require "test_helper"
require "minitest/mock"

class BookAssistantServiceTest < ActiveSupport::TestCase
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
    mock_assistant = Minitest::Mock.new
    mock_assistant.expect :add_message_and_run, nil do |_args|
      raise StandardError, "API Error"
    end

    @service.instance_variable_set(:@assistant, mock_assistant)

    result = @service.process_query("Test query")

    assert_not result[:success]
    assert_includes result[:message], "encountered an error"
    assert_equal "API Error", result[:error]
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
end

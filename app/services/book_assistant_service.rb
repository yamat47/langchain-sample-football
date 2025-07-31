# frozen_string_literal: true

class BookAssistantService
  MESSAGE_HISTORY_LIMIT = 20

  def initialize(session_id: nil, messages: [])
    @session_id = session_id
    @messages = messages || []
    @assistant = build_assistant_with_history
  end

  def process_query(message)
    start_time = Time.current

    begin
      # Add user message to conversation history
      @messages << { role: "user", content: message }
      limit_message_history!

      # Always use blocks processing for consistent formatting
      process_with_blocks(message, start_time)
    rescue StandardError => e
      handle_error(e, message, start_time)
    end
  end

  def chat(message:)
    process_query(message)
  end

  private

  def process_with_blocks(message, start_time)
    # Create parser for structured output
    parser = BookRecommendationParser.create_parser

    # Build assistant with enhanced instructions
    assistant = build_assistant_with_blocks_instructions

    # Log the full conversation context
    Rails.logger.info "=== BLOCKS PROCESSING START ==="
    Rails.logger.info "Current message: #{message}"
    Rails.logger.info "Message history count: #{@messages.size}"
    Rails.logger.info "Last 3 messages in history:"
    @messages.last(3).each_with_index do |msg, idx|
      Rails.logger.info "  [#{idx}] Role: #{msg[:role]}, Content preview: #{msg[:content].to_s[0..200]}..."
    end

    # Get response
    messages = assistant.add_message_and_run(
      content: message,
      auto_tool_execution: true
    )

    response = messages.last

    # Log the raw response for debugging
    Rails.logger.info "Book Assistant Raw Response: #{response.content}"
    Rails.logger.info "Book Assistant Message History Count: #{@messages.size}"

    # Try to parse as structured response
    begin
      # First try to parse the response as-is
      structured_response = parser.parse(response.content)
      Rails.logger.info "Book Assistant Parsed Blocks: #{structured_response['blocks']&.size || 0} blocks"
      @messages << { role: "assistant", content: response.content }

      response_time_ms = ((Time.current - start_time) * 1000).round

      # Log the query
      blocks = structured_response["blocks"] || structured_response[:blocks]
      text_content = BookRecommendationParser.extract_text_content(blocks)
      # Ensure we always have some content for the message
      text_content = "I've found some book recommendations for you." if text_content.blank?

      BookQuery.log_query(message, text_content, true, response_time_ms)

      # Return formatted response with blocks
      {
        message: text_content,
        blocks: structured_response["blocks"] || structured_response[:blocks],
        success: true,
        timestamp: Time.current,
        tools_used: extract_tools_used(response),
        messages: @messages
      }
    rescue Langchain::OutputParsers::OutputParserException => e
      Rails.logger.error "Failed to parse structured response: #{e.message}"
      Rails.logger.error "Response was: #{response.content}"
      
      # Try to extract JSON from the response if it contains JSON
      json_match = response.content.match(/\{[\s\S]*"blocks"[\s\S]*\}/m)
      if json_match
        begin
          Rails.logger.info "Attempting to extract JSON from response..."
          structured_response = JSON.parse(json_match[0])
          
          # Save the properly formatted JSON
          @messages << { role: "assistant", content: json_match[0] }
          
          response_time_ms = ((Time.current - start_time) * 1000).round
          
          # Log the query
          blocks = structured_response["blocks"] || structured_response[:blocks]
          text_content = BookRecommendationParser.extract_text_content(blocks)
          text_content = "I've found some book recommendations for you." if text_content.blank?
          
          BookQuery.log_query(message, text_content, true, response_time_ms)
          
          # Return formatted response with blocks
          return {
            message: text_content,
            blocks: structured_response["blocks"] || structured_response[:blocks],
            success: true,
            timestamp: Time.current,
            tools_used: extract_tools_used(response),
            messages: @messages
          }
        rescue JSON::ParserError => json_error
          Rails.logger.error "Failed to extract JSON: #{json_error.message}"
        end
      end
      
      # Still save the response and return a text-only block
      @messages << { role: "assistant", content: response.content }
      
      response_time_ms = ((Time.current - start_time) * 1000).round
      BookQuery.log_query(message, response.content, false, response_time_ms)
      
      # Return a text block even on parse failure
      {
        message: response.content,
        blocks: [
          {
            "type" => "text",
            "content" => { "markdown" => response.content }
          }
        ],
        success: true,
        timestamp: Time.current,
        tools_used: extract_tools_used(response),
        messages: @messages
      }
    end
  end


  def build_assistant_with_blocks_instructions
    assistant = Langchain::Assistant.new(
      llm: llm_client,
      instructions: assistant_instructions_with_blocks,
      tools: available_tools
    )

    # Restore conversation history to the assistant
    @messages.each do |msg|
      # Ensure role is a string and valid
      role = msg[:role].to_s
      next unless ["system", "assistant", "user", "tool"].include?(role)

      # For assistant messages, extract text content from blocks if present
      content = extract_message_content(role, msg[:content])
      
      Rails.logger.info "Adding message to blocks assistant - Role: #{role}, Original content length: #{msg[:content].to_s.length}, Extracted content: #{content[0..100]}..."
      
      assistant.add_message(role: role, content: content)
    end

    assistant
  end

  def assistant_instructions_with_blocks
    base_instructions = assistant_instructions
    format_instructions = BookRecommendationParser.format_instructions

    <<~INSTRUCTIONS
      #{base_instructions}

      #{format_instructions}
    INSTRUCTIONS
  end

  def build_assistant_with_history
    assistant = build_assistant

    # Restore conversation history to the assistant
    @messages.each do |msg|
      # Ensure role is a string and valid
      role = msg[:role].to_s
      next unless ["system", "assistant", "user", "tool"].include?(role)

      # For assistant messages, extract text content from blocks if present
      content = extract_message_content(role, msg[:content])
      assistant.add_message(role: role, content: content)
    end

    assistant
  end

  def limit_message_history!
    # Keep only the last MESSAGE_HISTORY_LIMIT messages
    return unless @messages.length > MESSAGE_HISTORY_LIMIT

    @messages = @messages.last(MESSAGE_HISTORY_LIMIT)
  end

  def build_assistant
    Langchain::Assistant.new(
      llm: llm_client,
      instructions: assistant_instructions,
      tools: available_tools
    )
  end

  def llm_client
    @llm_client ||= Langchain::LLM::OpenAI.new(
      api_key: ENV["OPENAI_API_KEY"] || Rails.application.credentials.openai_api_key,
      default_options: {
        model: "gpt-4o-mini",
        temperature: 0.7
      }
    )
  end

  def assistant_instructions
    <<~INSTRUCTIONS
      You are a knowledgeable book recommendation assistant that helps users discover books.
      You have access to:
      1. A database of books (via BookInfoTool) for searching and getting book details
      2. NewsRetriever for finding recent book-related news and trends

      When users ask about books:
      1. Search for relevant books using the BookInfoTool functions
      2. If relevant, check recent news for trending topics using NewsRetriever
      3. Provide personalized recommendations based on their interests
      4. Include details like ratings, genres, and similar books
      5. Be specific and mention book titles, authors, and key details

      For news searches, use queries like:
      - "new book releases [genre]" for new releases
      - "[author name] new book" for author-specific news
      - "book award winner" for literary awards
      - "bestseller list" for trending books

      Always format your responses clearly with book titles, authors, and relevant details.
      Be friendly, informative, and enthusiastic about books!

      If you cannot find specific information, acknowledge this and suggest alternatives.

      IMPORTANT: You MUST ALWAYS respond in JSON blocks format, even for follow-up questions.
      NEVER include any text before or after the JSON object.
      Your response MUST start with { and end with }
    INSTRUCTIONS
  end

  def available_tools
    tools = [BookInfoTool.new]

    # Add NewsRetriever if API key is available
    news_api_key = ENV["NEWS_API_KEY"] || Rails.application.credentials.news_api_key
    tools << Langchain::Tool::NewsRetriever.new(api_key: news_api_key) if news_api_key.present?

    tools
  end

  def format_response(response)
    {
      message: response.content,
      success: true,
      timestamp: Time.current,
      tools_used: extract_tools_used(response)
    }
  end

  def handle_error(error, message, start_time)
    Rails.logger.error "BookAssistantService Error: #{error.class} - #{error.message}"
    Rails.logger.error error.backtrace.join("\n")

    response_time_ms = ((Time.current - start_time) * 1000).round

    # Log the failed query only if message is present
    if message.present?
      BookQuery.log_query(
        message,
        error.message,
        false,
        response_time_ms
      )
    end

    error_message = case error
                    when Langchain::LLM::ApiError
                      "I'm having trouble connecting to the AI service. Please try again later."
                    when ActiveRecord::RecordNotFound
                      "I couldn't find the book you're looking for."
                    else
                      "I encountered an error while processing your request. Please try again."
                    end

    {
      message: error_message,
      success: false,
      error: error.message,
      timestamp: Time.current,
      messages: @messages
    }
  end

  def extract_tools_used(response)
    # Extract which tools were used from the response
    # This is a simplified implementation
    tools_used = []

    if response.respond_to?(:tool_calls) && response.tool_calls.present?
      tools_used = response.tool_calls.map { |call| call["function"]["name"] }.uniq
    end

    tools_used
  end

  def extract_message_content(role, content)
    # For assistant messages, extract text content from blocks if present
    if role == "assistant" && content.include?("{") && content.include?("blocks")
      begin
        parsed = JSON.parse(content)
        if parsed["blocks"]
          text_content = BookRecommendationParser.extract_text_content(parsed["blocks"])
          # If no text content, create a summary from other blocks
          text_content = summarize_blocks(parsed["blocks"]) if text_content.blank?
          text_content
        else
          content
        end
      rescue JSON::ParserError
        content
      end
    else
      content
    end
  end

  def summarize_blocks(blocks)
    summaries = []

    blocks.each do |block|
      case block["type"]
      when "book_card"
        summaries << "I recommended #{block['content']['title']} by #{block['content']['author']}"
      when "book_list"
        count = block["content"]["books"]&.size || 0
        summaries << "I showed you #{count} book recommendations"
      when "book_spotlight"
        summaries << "I provided detailed information about #{block['content']['title']}"
      end
    end

    return "" if summaries.empty?

    summaries.join(". ") + "."
  end
end

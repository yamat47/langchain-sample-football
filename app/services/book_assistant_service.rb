# frozen_string_literal: true

class BookAssistantService
  def initialize
    @assistant = build_assistant
  end

  def process_query(message)
    start_time = Time.current
    
    begin
      # Add message and run the assistant
      messages = @assistant.add_message_and_run(
        content: message,
        auto_tool_execution: true
      )
      
      # Get the last message which contains the response
      response = messages.last
      
      # Calculate response time
      response_time_ms = ((Time.current - start_time) * 1000).round
      
      # Log the query
      BookQuery.log_query(
        message,
        response.content,
        true,
        response_time_ms
      )
      
      format_response(response)
    rescue StandardError => e
      handle_error(e, message, start_time)
    end
  end

  def chat(message:)
    process_query(message)
  end

  private

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
    INSTRUCTIONS
  end

  def available_tools
    tools = [BookInfoTool.new]
    
    # Add NewsRetriever if API key is available
    news_api_key = ENV["NEWS_API_KEY"] || Rails.application.credentials.news_api_key
    if news_api_key.present?
      tools << Langchain::Tool::NewsRetriever.new(api_key: news_api_key)
    end
    
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
      timestamp: Time.current
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
end
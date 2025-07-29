# frozen_string_literal: true

class BookAssistantController < ApplicationController
  before_action :initialize_or_retrieve_assistant

  def index
    @recent_queries = BookQuery.recent.limit(5)
  end

  def query
    @response = @assistant_service.process_query(params[:message])

    # Update messages in cache instead of session
    if @response[:messages]
      ChatSessionService.update_messages(session[:chat_session_id], @response[:messages])
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append("messages", partial: "message",
                                                             locals: { message: params[:message], response: @response })
      end
      format.html do
        redirect_to book_assistant_index_path
      end
      format.json { render json: @response }
    end
  end

  def new_chat
    # Clear chat session in cache
    ChatSessionService.clear_session(session[:chat_session_id]) if session[:chat_session_id]
    
    # Generate new session ID
    session[:chat_session_id] = SecureRandom.uuid

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("messages", ""),
          turbo_stream.update("messages", partial: "initial_greeting")
        ]
      end
      format.html do
        redirect_to book_assistant_index_path
      end
    end
  end

  private

  def initialize_or_retrieve_assistant
    # Initialize session ID if not present
    session[:chat_session_id] ||= SecureRandom.uuid

    # Get messages from cache instead of session
    messages = ChatSessionService.get_messages(session[:chat_session_id])

    # Create service with cached messages
    @assistant_service = BookAssistantService.new(
      session_id: session[:chat_session_id],
      messages: messages
    )
  end
end

# frozen_string_literal: true

class BookAssistantController < ApplicationController
  before_action :set_current_user
  before_action :require_user, except: [:index, :identify, :query, :new_chat]
  before_action :set_chat_session, only: [:show]

  def index
    if @current_user
      @chat_sessions = @current_user.chat_sessions.recent
    else
      # For backward compatibility with old tests that expect chat interface
      # Use legacy_chat param to indicate old behavior
      @legacy_mode = params[:legacy_chat] == "true"
      session[:chat_session_id] ||= SecureRandom.uuid if @legacy_mode
    end
  end

  def identify
    @user = UserService.find_or_create_by_identifier(params[:identifier])

    if @user&.persisted?
      session[:user_id] = @user.id
    else
      flash[:error] = "Invalid identifier. Please use only letters and numbers."
    end
    redirect_to book_assistant_index_path
  end

  def show
    @messages = @chat_session.chat_messages.ordered
  end

  def new
    @chat_session = @persistence_service.create_session
    redirect_to book_assistant_path(@chat_session)
  end

  def query
    # Handle both collection and member queries
    if params[:id]
      # Member query - specific session
      @chat_session = @current_user.chat_sessions.find(params[:id])
      process_session_query
    elsif @current_user
      # Collection query - handle old cache-based system for backward compatibility
      @chat_session = @current_user.chat_sessions.recent.first || @persistence_service.create_session
      process_session_query
    else
      # Old cache-based behavior for tests
      process_cache_query
    end
  end

  def new_chat
    # This action is for cache-based system
    # Clear the current session and create new
    old_session_id = session[:chat_session_id]
    new_session_id = SecureRandom.uuid
    session[:chat_session_id] = new_session_id

    # Clear old messages if any
    ChatSessionService.clear_session(old_session_id) if old_session_id

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("messages", "")
      end
      format.html do
        redirect_to book_assistant_index_path
      end
    end
  end

  def logout
    session.delete(:user_id)
    redirect_to book_assistant_index_path
  end

  private

  def set_current_user
    @current_user = User.find_by(id: session[:user_id]) if session[:user_id]
    @persistence_service = ChatPersistenceService.new(@current_user) if @current_user
  end

  def require_user
    return if @current_user

    flash[:error] = "Please identify yourself first"
    redirect_to book_assistant_index_path
  end

  def set_chat_session
    @chat_session = @current_user.chat_sessions.find(params[:id])
  end

  def process_session_query
    # Add user message
    @persistence_service.add_message(@chat_session.id, "user", params[:message])

    # Get formatted messages for assistant
    messages = @persistence_service.format_messages_for_assistant(@chat_session.id)

    # Process with BookAssistantService
    assistant_service = BookAssistantService.new(
      session_id: @chat_session.id.to_s,
      messages: messages
    )

    @response = assistant_service.process_query(params[:message])

    # Save assistant response
    @persistence_service.add_message(@chat_session.id, "assistant", @response[:message]) if @response[:success]

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append("messages", partial: "assistant_response",
                                                             locals: {
                                                               message: params[:message],
                                                               response: @response
                                                             })
      end
      format.html do
        redirect_to book_assistant_path(@chat_session)
      end
      format.json { render json: @response }
    end
  end

  def process_cache_query
    # Backward compatibility for cache-based tests
    messages = ChatSessionService.get_messages(session[:chat_session_id])

    assistant_service = BookAssistantService.new(
      session_id: session[:chat_session_id],
      messages: messages
    )

    @response = assistant_service.process_query(params[:message])

    ChatSessionService.update_messages(session[:chat_session_id], @response[:messages]) if @response[:messages]

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append("messages", partial: "message",
                                                             locals: {
                                                               message: params[:message],
                                                               response: @response
                                                             })
      end
      format.html do
        redirect_to book_assistant_index_path
      end
      format.json { render json: @response }
    end
  end
end

# frozen_string_literal: true

class BookAssistantController < ApplicationController
  before_action :set_current_user
  before_action :require_user, except: [:index, :identify, :query, :new_chat]
  before_action :set_chat_session, only: [:show]

  def index
    if @current_user
      @chat_sessions = @current_user.chat_sessions.recent
    else
      # Initialize anonymous session
      anonymous_user = User.anonymous_user
      persistence_service = ChatPersistenceService.new(anonymous_user)

      if session[:anonymous_chat_session_id]
        @chat_session = anonymous_user.chat_sessions.find_by(id: session[:anonymous_chat_session_id])
      end

      @chat_session ||= persistence_service.create_session
      session[:anonymous_chat_session_id] = @chat_session.id
    end
  end

  def identify
    if request.get?
      # Show the identify form
      render "identify"
    else
      # Handle POST request
      @user = UserService.find_or_create_by_identifier(params[:identifier])

      if @user&.persisted?
        session[:user_id] = @user.id
      else
        flash[:error] = "Invalid identifier. Please use only letters and numbers."
      end
      redirect_to book_assistant_index_path
    end
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
      # Collection query - authenticated user
      @chat_session = @current_user.chat_sessions.recent.first || @persistence_service.create_session
      process_session_query
    else
      # Anonymous user
      anonymous_user = User.anonymous_user
      @persistence_service = ChatPersistenceService.new(anonymous_user)
      @chat_session = anonymous_user.chat_sessions.find_by(id: session[:anonymous_chat_session_id])
      @chat_session ||= @persistence_service.create_session
      session[:anonymous_chat_session_id] = @chat_session.id
      process_session_query
    end
  end

  def new_chat
    if @current_user
      # Authenticated user - create new session
      @chat_session = @persistence_service.create_session
      redirect_to book_assistant_path(@chat_session)
    else
      # Anonymous user - create new anonymous session
      anonymous_user = User.anonymous_user
      persistence_service = ChatPersistenceService.new(anonymous_user)
      @chat_session = persistence_service.create_session
      session[:anonymous_chat_session_id] = @chat_session.id

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("messages", "")
        end
        format.html do
          redirect_to book_assistant_index_path
        end
      end
    end
  end

  def logout
    session.delete(:user_id)
    session.delete(:anonymous_chat_session_id)
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
    # Handle empty messages
    if params[:message].blank?
      @response = { success: true, message: "How can I help you find books today?", tools_used: [] }

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append("messages", partial: "assistant_response",
                                                               locals: {
                                                                 message: params[:message],
                                                                 response: @response
                                                               })
        end
        format.json { render json: @response }
      end
      return
    end

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
    if @response[:success]
      # For blocks response, extract text content or use a fallback
      message_content = if @response[:blocks].present?
                          text_content = BookRecommendationParser.extract_text_content(@response[:blocks])
                          text_content.presence || "I've found some book recommendations for you."
                        else
                          @response[:message]
                        end

      @persistence_service.add_message(@chat_session.id, "assistant", message_content)
    end

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
end

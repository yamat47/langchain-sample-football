# frozen_string_literal: true

class ChatPersistenceService
  def initialize(user)
    @user = user
  end

  def create_session
    @user.chat_sessions.create!
  end

  def get_session(session_id)
    @user.chat_sessions.find(session_id)
  end

  def get_or_create_session(session_id)
    if session_id.present?
      get_session(session_id)
    else
      create_session
    end
  end

  def get_messages(session_id)
    session = get_session(session_id)
    session.chat_messages.ordered
  end

  def add_message(session_id, role, content)
    session = get_session(session_id)
    session.chat_messages.create!(role: role.to_s, content: content)
  end

  def list_sessions
    @user.chat_sessions.recent.includes(:chat_messages)
  end

  def format_messages_for_assistant(session_id)
    messages = get_messages(session_id)
    messages.map do |message|
      {
        role: message.role,
        content: message.content
      }
    end
  end
end

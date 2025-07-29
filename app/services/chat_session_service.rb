# frozen_string_literal: true

class ChatSessionService
  # Use Rails cache to store chat sessions
  # In production, this would use Redis or Memcached

  EXPIRATION_TIME = 30.minutes
  MAX_MESSAGES = 20

  class << self
    def get_messages(session_id)
      Rails.cache.fetch(cache_key(session_id), expires_in: EXPIRATION_TIME) do
        []
      end
    end

    def add_message(session_id, role, content)
      messages = get_messages(session_id).dup # dup to avoid modifying cached object
      messages << { role: role.to_s, content: content }

      # Limit message history
      messages = messages.last(MAX_MESSAGES) if messages.length > MAX_MESSAGES

      Rails.cache.write(cache_key(session_id), messages, expires_in: EXPIRATION_TIME)
      messages
    end

    def update_messages(session_id, messages)
      return if session_id.blank?

      # Ensure we don't exceed the limit
      messages = messages.last(MAX_MESSAGES) if messages.length > MAX_MESSAGES
      Rails.cache.write(cache_key(session_id), messages, expires_in: EXPIRATION_TIME)
    end

    def clear_session(session_id)
      Rails.cache.delete(cache_key(session_id))
    end

    private

    def cache_key(session_id)
      "chat_session:#{session_id}"
    end
  end
end

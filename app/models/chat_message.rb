# frozen_string_literal: true

class ChatMessage < ApplicationRecord
  belongs_to :chat_session, counter_cache: :messages_count

  validates :role, presence: true, inclusion: { in: ["user", "assistant", "system"] }
  validates :content, presence: true
  validates :position, presence: true, uniqueness: { scope: :chat_session_id }

  before_validation :set_position
  after_create :update_session_activity

  scope :ordered, -> { order(:position) }

  private

  def set_position
    return if position.present?
    return unless chat_session

    self.position = (chat_session.chat_messages.maximum(:position) || 0) + 1
  end

  def update_session_activity
    chat_session.update(last_activity_at: Time.current)
  end
end

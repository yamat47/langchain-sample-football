# frozen_string_literal: true

class ChatSession < ApplicationRecord
  belongs_to :user
  has_many :chat_messages, dependent: :destroy

  validates :last_activity_at, presence: true
  validates :session_number, presence: true, uniqueness: { scope: :user_id }

  before_validation :set_last_activity
  before_validation :set_session_number, on: :create

  scope :recent, -> { order(last_activity_at: :desc) }
  scope :ordered, -> { order(session_number: :desc) }

  def display_name
    "Session ##{session_number}"
  end

  private

  def set_last_activity
    self.last_activity_at ||= Time.current
  end

  def set_session_number
    return if session_number.present?
    return unless user

    max_number = user.chat_sessions.maximum(:session_number) || 0
    self.session_number = max_number + 1
  end
end

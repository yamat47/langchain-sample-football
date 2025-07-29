# frozen_string_literal: true

class User < ApplicationRecord
  has_many :chat_sessions, dependent: :destroy

  validates :identifier, presence: true,
                         uniqueness: { case_sensitive: false },
                         format: { with: /\A[a-zA-Z0-9]+\z/ }

  before_validation :normalize_identifier

  private

  def normalize_identifier
    self.identifier = identifier&.downcase
  end
end

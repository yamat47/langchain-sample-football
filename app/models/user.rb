# frozen_string_literal: true

class User < ApplicationRecord
  has_many :chat_sessions, dependent: :destroy

  validates :identifier, presence: true,
                         uniqueness: { case_sensitive: false }
  validates :identifier, format: { with: /\A[a-zA-Z0-9]+\z/ },
                         unless: :anonymous?

  before_validation :normalize_identifier

  scope :anonymous, -> { where(anonymous: true) }
  scope :registered, -> { where(anonymous: false) }

  def self.anonymous_user
    anonymous.first || create_anonymous_user
  end

  class << self
    private

    def create_anonymous_user
      # Use build to set attributes before validation
      user = new(identifier: "anonymous", anonymous: true)
      user.save!
      user
    rescue ActiveRecord::RecordInvalid
      # If creation fails due to uniqueness, find the existing one
      find_by!(identifier: "anonymous")
    end
  end

  private

  def normalize_identifier
    self.identifier = identifier&.downcase
  end
end

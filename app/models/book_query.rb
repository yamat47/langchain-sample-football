# frozen_string_literal: true

class BookQuery < ApplicationRecord
  # Validations
  validates :query_text, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :successful, -> { where(success: true) }

  # Class methods
  def self.log_query(query, response, success, response_time = nil)
    create!(
      query_text: query,
      response_text: response,
      success: success,
      response_time_ms: response_time,
      error_message: success ? nil : response
    )
  end
end

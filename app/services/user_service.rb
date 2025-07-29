# frozen_string_literal: true

class UserService
  def self.find_or_create_by_identifier(identifier)
    return nil if identifier.blank?

    normalized = identifier.strip.downcase
    return nil if normalized.blank?

    User.find_or_create_by(identifier: normalized)
  rescue ActiveRecord::RecordNotUnique
    # Handle race condition in concurrent requests
    User.find_by(identifier: normalized)
  end
end

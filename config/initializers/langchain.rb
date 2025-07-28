# frozen_string_literal: true

# Langchain configuration
Langchain.configure do |config|
  config.logger = Rails.logger
  config.timeout = 30 # seconds
end
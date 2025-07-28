# frozen_string_literal: true

module Admin
  class BookQueriesController < ApplicationController
    before_action :set_book_query, only: [:show]

    def index
      @book_queries = BookQuery.order(created_at: :desc)
      @successful_queries = BookQuery.successful.count
      @failed_queries = BookQuery.where(success: false).count
      @avg_response_time = BookQuery.where.not(response_time_ms: nil).average(:response_time_ms)&.round || 0
    end

    def show; end

    private

    def set_book_query
      @book_query = BookQuery.find(params[:id])
    end
  end
end

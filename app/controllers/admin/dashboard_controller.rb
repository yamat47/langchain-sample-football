# frozen_string_literal: true

module Admin
  class DashboardController < ApplicationController
    def index
      @total_books = Book.count
      @total_reviews = Review.count
      @total_queries = BookQuery.count
      @trending_books = Book.trending.limit(5)
      @recent_queries = BookQuery.recent.limit(5)
      @top_rated_books = Book.highly_rated.order(rating: :desc).limit(5)
      @recent_reviews = Review.recent.includes(:book).limit(5)
    end
  end
end

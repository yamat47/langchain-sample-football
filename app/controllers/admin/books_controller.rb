# frozen_string_literal: true

module Admin
  class BooksController < ApplicationController
    before_action :set_book, only: [:show, :similar]

    def index
      @books = Book.includes(:reviews).order(:title)
      @trending_books = Book.trending.limit(5)
      @recent_books = Book.recent.limit(5)
    end

    def show
      @reviews = @book.reviews.includes(:book).order(created_at: :desc)
      @similar_books = @book.find_similar(limit: 10)
    end

    def similar
      @similar_books = @book.book_similarities
                            .includes(:similar_book)
                            .order(similarity_score: :desc)
    end

    private

    def set_book
      @book = Book.find(params[:id])
    end
  end
end

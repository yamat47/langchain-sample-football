# frozen_string_literal: true

require 'ostruct'

class BookInfoTool
  extend Langchain::ToolDefinition
  
  def name
    "book_info"
  end
  
  def description
    "Tool that provides information about books, including search, details, reviews, and recommendations"
  end
  
  def functions
    # Get function schemas from Langchain::ToolDefinition
    if self.class.respond_to?(:function_schemas)
      schemas = self.class.function_schemas
      if schemas.respond_to?(:values)
        schemas.values
      elsif schemas.respond_to?(:to_a)
        schemas.to_a
      else
        # Fallback: manually list the functions
        [:search_books, :get_book_details, :get_similar_books, :get_book_reviews,
         :get_trending_books, :get_books_by_genre, :get_highly_rated_books, :get_recent_books].map do |name|
          OpenStruct.new(name: name)
        end
      end
    else
      []
    end
  end

  define_function :search_books,
                  description: "Search for books by title, author, or ISBN" do
    property :query, type: "string", description: "The search query", required: true
    property :search_type, type: "string", description: "Type of search",
             enum: ["title", "author", "isbn"]
  end

  def search_books(query:, search_type: "title")
    return { success: false, error: "Query cannot be nil" } if query.nil?
    return { success: false, error: "Invalid search type" } unless ["title", "author", "isbn"].include?(search_type)
    
    begin
      books = case search_type
              when "title"
                query.empty? ? Book.none : Book.search_by_title(query)
              when "author"
                query.empty? ? Book.none : Book.search_by_author(query)
              when "isbn"
                query.empty? ? Book.none : Book.where(isbn: query)
              end

      { success: true, books: books.limit(10).map(&:to_api_response) }
    rescue => e
      { success: false, error: e.message }
    end
  end

  define_function :get_book_details,
                  description: "Get detailed information about a specific book" do
    property :isbn, type: "string", description: "The ISBN of the book", required: true
  end

  def get_book_details(isbn:)
    begin
      book = Book.find_by(isbn: isbn)
      return { success: false, error: "Book not found" } unless book

      { success: true, book: book.to_detailed_api_response }
    rescue => e
      { success: false, error: e.message }
    end
  end

  define_function :get_similar_books,
                  description: "Find books similar to a given book" do
    property :isbn, type: "string", description: "The ISBN of the book", required: true
    property :limit, type: "integer", description: "Maximum number of similar books to return"
  end

  def get_similar_books(isbn:, limit: 5)
    begin
      book = Book.find_by(isbn: isbn)
      return { success: false, error: "Book not found" } unless book

      similar_books = book.book_similarities
                          .order(similarity_score: :desc)
                          .limit(limit)
                          .includes(:similar_book)
                          .map { |bs| bs.similar_book.to_api_response }
      
      { success: true, similar_books: similar_books }
    rescue => e
      { success: false, error: e.message }
    end
  end

  define_function :get_trending_books,
                  description: "Get currently trending or popular books" do
    property :limit, type: "integer", description: "Maximum number of books to return"
  end

  def get_trending_books(limit: 10)
    begin
      books = Book.trending.limit(limit).map do |book|
        book.to_api_response.merge(trending_score: book.trending_score)
      end
      { success: true, books: books }
    rescue => e
      { success: false, error: e.message }
    end
  end

  define_function :get_books_by_genre,
                  description: "Get books by specific genre" do
    property :genre, type: "string", description: "The genre to search for", required: true
    property :limit, type: "integer", description: "Maximum number of books to return"
  end

  def get_books_by_genre(genre:, limit: 10)
    begin
      books = Book.by_genre(genre).limit(limit).map(&:to_api_response)
      { success: true, books: books }
    rescue => e
      { success: false, error: e.message }
    end
  end

  define_function :get_highly_rated_books,
                  description: "Get books with high ratings (4.0 or above)" do
    property :limit, type: "integer", description: "Maximum number of books to return"
    property :min_rating, type: "number", description: "Minimum rating threshold"
  end

  def get_highly_rated_books(limit: 10, min_rating: 4.0)
    begin
      books = Book.where("rating >= ?", min_rating)
                  .order(rating: :desc)
                  .limit(limit)
                  .map(&:to_api_response)
      { success: true, books: books }
    rescue => e
      { success: false, error: e.message }
    end
  end

  define_function :get_recent_books,
                  description: "Get recently published books" do
    property :limit, type: "integer", description: "Maximum number of books to return"
    property :months_ago, type: "integer", description: "How many months back to search"
  end

  def get_recent_books(limit: 10, months_ago: 12)
    begin
      books = Book.where("published_at >= ?", months_ago.months.ago)
                  .order(published_at: :desc)
                  .limit(limit)
                  .map(&:to_api_response)
      { success: true, books: books }
    rescue => e
      { success: false, error: e.message }
    end
  end
  
  define_function :get_book_reviews,
                  description: "Get reviews for a specific book" do
    property :isbn, type: "string", description: "The ISBN of the book", required: true
    property :limit, type: "integer", description: "Maximum number of reviews to return"
  end
  
  def get_book_reviews(isbn:, limit: 10)
    begin
      book = Book.find_by(isbn: isbn)
      return { success: false, error: "Book not found" } unless book
      
      reviews = book.reviews.recent.limit(limit).map do |review|
        {
          rating: review.rating,
          content: review.content,
          reviewer_name: review.reviewer_name,
          created_at: review.created_at
        }
      end
      
      { success: true, reviews: reviews }
    rescue => e
      { success: false, error: e.message }
    end
  end
end
# frozen_string_literal: true

class BookInfoTool
  extend Langchain::ToolDefinition

  define_function :search_books,
                  description: "Search for books by title, author, or ISBN" do
    property :query, type: "string", description: "The search query", required: true
    property :search_type, type: "string", description: "Type of search",
             enum: ["title", "author", "isbn"], default: "title"
  end

  def search_books(query:, search_type: "title")
    books = case search_type
            when "title"
              Book.search_by_title(query)
            when "author"
              Book.search_by_author(query)
            when "isbn"
              Book.where(isbn: query)
            end

    books.limit(10).map(&:to_api_response)
  end

  define_function :get_book_details,
                  description: "Get detailed information about a specific book" do
    property :isbn, type: "string", description: "The ISBN of the book", required: true
  end

  def get_book_details(isbn:)
    book = Book.find_by(isbn: isbn)
    return { error: "Book not found" } unless book

    book.to_detailed_api_response
  end

  define_function :get_similar_books,
                  description: "Find books similar to a given book" do
    property :isbn, type: "string", description: "The ISBN of the book", required: true
    property :limit, type: "integer", description: "Maximum number of similar books to return",
             default: 5
  end

  def get_similar_books(isbn:, limit: 5)
    book = Book.find_by(isbn: isbn)
    return { error: "Book not found" } unless book

    book.find_similar(limit: limit).map(&:to_api_response)
  end

  define_function :get_trending_books,
                  description: "Get currently trending or popular books" do
    property :limit, type: "integer", description: "Maximum number of books to return",
             default: 10
  end

  def get_trending_books(limit: 10)
    Book.trending.limit(limit).map(&:to_api_response)
  end

  define_function :get_books_by_genre,
                  description: "Get books by specific genre" do
    property :genre, type: "string", description: "The genre to search for", required: true
    property :limit, type: "integer", description: "Maximum number of books to return",
             default: 10
  end

  def get_books_by_genre(genre:, limit: 10)
    Book.by_genre(genre).limit(limit).map(&:to_api_response)
  end

  define_function :get_highly_rated_books,
                  description: "Get books with high ratings (4.0 or above)" do
    property :limit, type: "integer", description: "Maximum number of books to return",
             default: 10
    property :min_rating, type: "number", description: "Minimum rating threshold",
             default: 4.0
  end

  def get_highly_rated_books(limit: 10, min_rating: 4.0)
    Book.where("rating >= ?", min_rating)
        .order(rating: :desc)
        .limit(limit)
        .map(&:to_api_response)
  end

  define_function :get_recent_books,
                  description: "Get recently published books" do
    property :limit, type: "integer", description: "Maximum number of books to return",
             default: 10
    property :months_ago, type: "integer", description: "How many months back to search",
             default: 12
  end

  def get_recent_books(limit: 10, months_ago: 12)
    Book.where("published_at >= ?", months_ago.months.ago)
        .order(published_at: :desc)
        .limit(limit)
        .map(&:to_api_response)
  end
end
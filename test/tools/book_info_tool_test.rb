require "test_helper"

class BookInfoToolTest < ActiveSupport::TestCase
  def setup
    @tool = BookInfoTool.new
    
    # Create test data
    @book1 = Book.create!(
      isbn: "978-0-7475-3269-9",
      title: "Harry Potter and the Philosopher's Stone",
      author: "J.K. Rowling",
      description: "The first book in the Harry Potter series",
      genres: ["Fantasy", "Young Adult"],
      rating: 4.5,
      price: 1200,
      publisher: "Bloomsbury",
      page_count: 223,
      published_at: Date.new(1997, 6, 26),
      is_trending: true,
      trending_score: 95
    )
    
    @book2 = Book.create!(
      isbn: "978-0-06-112008-4",
      title: "To Kill a Mockingbird",
      author: "Harper Lee",
      description: "A classic of modern American literature",
      genres: ["Classic", "Fiction"],
      rating: 4.3,
      price: 1000,
      publisher: "J. B. Lippincott & Co.",
      page_count: 281,
      published_at: Date.new(1960, 7, 11)
    )
    
    @review = Review.create!(
      book: @book1,
      rating: 5,
      content: "Amazing book!",
      reviewer_name: "John Doe"
    )
    
    BookSimilarity.create!(
      book: @book1,
      similar_book: @book2,
      similarity_score: 0.7
    )
  end

  test "should have correct name" do
    assert_equal "book_info", @tool.name
  end

  test "should have correct description" do
    assert_includes @tool.description, "provides information about books"
  end

  test "should define all required functions" do
    function_names = @tool.functions.map(&:name).map(&:to_s)
    expected_functions = [
      "search_books",
      "get_book_details",
      "get_similar_books",
      "get_book_reviews",
      "get_trending_books",
      "get_books_by_genre",
      "get_highly_rated_books"
    ]
    
    expected_functions.each do |func|
      assert_includes function_names, func
    end
  end

  test "search_books by title returns matching books" do
    result = @tool.search_books(query: "Harry Potter", search_type: "title")
    
    assert result[:success]
    assert_equal 1, result[:books].length
    assert_equal @book1.isbn, result[:books].first[:isbn]
  end

  test "search_books by author returns matching books" do
    result = @tool.search_books(query: "Harper", search_type: "author")
    
    assert result[:success]
    assert_equal 1, result[:books].length
    assert_equal @book2.isbn, result[:books].first[:isbn]
  end

  test "search_books by isbn returns exact match" do
    result = @tool.search_books(query: "978-0-7475-3269-9", search_type: "isbn")
    
    assert result[:success]
    assert_equal 1, result[:books].length
    assert_equal @book1.isbn, result[:books].first[:isbn]
  end

  test "search_books returns error for invalid search type" do
    result = @tool.search_books(query: "test", search_type: "invalid")
    
    assert_not result[:success]
    assert_includes result[:error], "Invalid search type"
  end

  test "get_book_details returns book information" do
    result = @tool.get_book_details(isbn: @book1.isbn)
    
    assert result[:success]
    assert_not_nil result[:book]
    assert_equal @book1.title, result[:book][:title]
    assert_equal @book1.author, result[:book][:author]
  end

  test "get_book_details returns error for non-existent book" do
    result = @tool.get_book_details(isbn: "999-999")
    
    assert_not result[:success]
    assert_includes result[:error], "Book not found"
  end

  test "get_similar_books returns similar books" do
    result = @tool.get_similar_books(isbn: @book1.isbn, limit: 5)
    
    assert result[:success]
    assert_equal 1, result[:similar_books].length
    assert_equal @book2.isbn, result[:similar_books].first[:isbn]
  end

  test "get_similar_books respects limit parameter" do
    # Create more similar books
    3.times do |i|
      book = Book.create!(
        isbn: "test-#{i}",
        title: "Test Book #{i}",
        author: "Test Author",
        genres: ["Fantasy"]
      )
      BookSimilarity.create!(
        book: @book1,
        similar_book: book,
        similarity_score: 0.8 - (i * 0.1)
      )
    end
    
    result = @tool.get_similar_books(isbn: @book1.isbn, limit: 2)
    
    assert result[:success]
    assert_equal 2, result[:similar_books].length
  end

  test "get_book_reviews returns reviews" do
    result = @tool.get_book_reviews(isbn: @book1.isbn, limit: 10)
    
    assert result[:success]
    assert_equal 1, result[:reviews].length
    assert_equal 5, result[:reviews].first[:rating]
    assert_equal "Amazing book!", result[:reviews].first[:content]
  end

  test "get_book_reviews respects limit parameter" do
    # Create more reviews
    5.times do |i|
      Review.create!(
        book: @book1,
        rating: 4,
        content: "Review #{i}",
        reviewer_name: "Reviewer #{i}"
      )
    end
    
    result = @tool.get_book_reviews(isbn: @book1.isbn, limit: 3)
    
    assert result[:success]
    assert_equal 3, result[:reviews].length
  end

  test "get_trending_books returns trending books" do
    result = @tool.get_trending_books(limit: 10)
    
    assert result[:success]
    assert_equal 1, result[:books].length
    assert_equal @book1.isbn, result[:books].first[:isbn]
    assert_equal 95, result[:books].first[:trending_score]
  end

  test "get_books_by_genre returns books matching genre" do
    result = @tool.get_books_by_genre(genre: "Fantasy", limit: 10)
    
    assert result[:success]
    assert_equal 1, result[:books].length
    assert_equal @book1.isbn, result[:books].first[:isbn]
  end

  test "get_books_by_genre is case insensitive" do
    result = @tool.get_books_by_genre(genre: "fantasy", limit: 10)
    
    assert result[:success]
    assert_equal 1, result[:books].length
  end

  test "get_highly_rated_books returns books with rating >= 4.0" do
    result = @tool.get_highly_rated_books(limit: 10)
    
    assert result[:success]
    assert_equal 2, result[:books].length
    
    result[:books].each do |book|
      assert book[:rating] >= 4.0
    end
  end

  test "should handle errors gracefully" do
    # Test with nil parameter
    result = @tool.search_books(query: nil, search_type: "title")
    assert_not result[:success]
    
    # Test with empty query
    result = @tool.search_books(query: "", search_type: "title")
    assert result[:success]
    assert_equal 0, result[:books].length
  end

  test "should return consistent API response format" do
    # Test all methods return consistent structure
    methods_to_test = [
      [:search_books, { query: "test", search_type: "title" }],
      [:get_book_details, { isbn: @book1.isbn }],
      [:get_similar_books, { isbn: @book1.isbn }],
      [:get_book_reviews, { isbn: @book1.isbn }],
      [:get_trending_books, {}],
      [:get_books_by_genre, { genre: "Fantasy" }],
      [:get_highly_rated_books, {}]
    ]
    
    methods_to_test.each do |method, params|
      result = @tool.send(method, **params)
      assert_includes result.keys, :success
      assert [true, false].include?(result[:success])
    end
  end
end
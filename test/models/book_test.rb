require "test_helper"

class BookTest < ActiveSupport::TestCase
  def setup
    @book = Book.new(
      title: "Test Book",
      author: "Test Author",
      isbn: "978-0-12345-678-9",
      description: "This is a test book description",
      published_at: Date.new(2024, 1, 1),
      genres: ["Fiction", "Mystery"],
      rating: 4.5,
      price: 29.99,
      language: "English",
      page_count: 350,
      publisher: "Test Publisher"
    )
  end

  test "should be valid with valid attributes" do
    assert @book.valid?
  end

  test "should require title" do
    @book.title = nil
    assert_not @book.valid?
    assert_includes @book.errors[:title], "can't be blank"
  end

  test "should require author" do
    @book.author = nil
    assert_not @book.valid?
    assert_includes @book.errors[:author], "can't be blank"
  end

  test "should require isbn" do
    @book.isbn = nil
    assert_not @book.valid?
    assert_includes @book.errors[:isbn], "can't be blank"
  end

  test "should have unique isbn" do
    @book.save!
    duplicate_book = @book.dup
    duplicate_book.title = "Different Title"
    assert_not duplicate_book.valid?
    assert_includes duplicate_book.errors[:isbn], "has already been taken"
  end

  test "should allow any rating value" do
    # Model doesn't validate rating range
    @book.rating = -1
    assert @book.valid?

    @book.rating = 6
    assert @book.valid?

    @book.rating = 3.5
    assert @book.valid?
  end

  test "should allow any price value" do
    # Model doesn't validate price
    @book.price = -1
    assert @book.valid?

    @book.price = 0
    assert @book.valid?
  end

  test "should allow any page_count value" do
    # Model doesn't validate page_count
    @book.page_count = 0
    assert @book.valid?

    @book.page_count = -1
    assert @book.valid?

    @book.page_count = 100
    assert @book.valid?
  end

  test "should serialize genres as JSON" do
    @book.save!
    reloaded_book = Book.find(@book.id)
    assert_equal ["Fiction", "Mystery"], reloaded_book.genres
  end

  test "search_by_title scope returns books matching title" do
    @book.save!
    Book.create!(title: "Another Book", author: "Author", isbn: "123-456")
    
    results = Book.search_by_title("Test")
    assert_equal 1, results.count
    assert_equal @book, results.first
  end

  test "search_by_author scope returns books matching author" do
    @book.save!
    Book.create!(title: "Another Book", author: "Different Author", isbn: "123-456")
    
    results = Book.search_by_author("Test")
    assert_equal 1, results.count
    assert_equal @book, results.first
  end

  test "trending scope returns trending books" do
    @book.is_trending = true
    @book.trending_score = 90
    @book.save!
    Book.create!(title: "Not Trending", author: "Author", isbn: "123-456", is_trending: false)
    
    results = Book.trending
    assert_equal 1, results.count
    assert_equal @book, results.first
  end

  test "by_genre scope returns books containing genre" do
    @book.save!
    Book.create!(title: "Another Book", author: "Author", isbn: "123-456", genres: ["Romance"])
    
    results = Book.by_genre("Mystery")
    assert_equal 1, results.count
    assert_equal @book, results.first
  end

  test "recent scope returns books published within last year" do
    @book.published_at = 6.months.ago
    @book.save!
    old_book = Book.create!(title: "Old", author: "Author", isbn: "111", published_at: 2.years.ago)
    
    results = Book.recent
    assert_equal 1, results.count
    assert_equal @book, results.first
  end

  test "highly_rated scope returns books with rating >= 4.0" do
    @book.rating = 4.5
    @book.save!
    low_rated = Book.create!(title: "Low", author: "Author", isbn: "333", rating: 3.5)
    
    results = Book.highly_rated
    assert_equal 1, results.count
    assert_equal @book, results.first
  end

  test "calculate_rating returns average of reviews" do
    @book.save!
    Review.create!(book: @book, rating: 5, content: "Great!")
    Review.create!(book: @book, rating: 3, content: "OK")
    
    assert_equal 4.0, @book.calculate_rating
  end

  test "review_count returns number of reviews" do
    @book.save!
    Review.create!(book: @book, rating: 5, content: "Great!")
    Review.create!(book: @book, rating: 3, content: "OK")
    
    assert_equal 2, @book.review_count
  end

  test "find_similar returns similar books" do
    @book.save!
    similar = Book.create!(title: "Similar", author: "Author", isbn: "999", genres: ["Fiction"])
    BookSimilarity.create!(book: @book, similar_book: similar, similarity_score: 0.9)
    
    results = @book.find_similar(limit: 5)
    assert_includes results, similar
  end

  test "to_api_response returns correct hash structure" do
    @book.save!
    response = @book.to_api_response
    
    assert_equal @book.isbn, response[:isbn]
    assert_equal @book.title, response[:title]
    assert_equal @book.author, response[:author]
    assert_equal @book.genres, response[:genres]
    assert_equal @book.rating, response[:rating]
    assert_equal @book.review_count, response[:review_count]
    assert_equal @book.price, response[:price]
    assert_equal @book.published_at.strftime("%Y-%m-%d"), response[:published_at]
  end

  test "to_detailed_api_response includes all fields" do
    @book.save!
    response = @book.to_detailed_api_response
    
    # Check all fields from to_api_response
    assert_includes response.keys, :isbn
    assert_includes response.keys, :title
    assert_includes response.keys, :author
    assert_includes response.keys, :genres
    assert_includes response.keys, :rating
    assert_includes response.keys, :review_count
    assert_includes response.keys, :price
    assert_includes response.keys, :published_at
    
    # Check additional detailed fields
    assert_includes response.keys, :description
    assert_includes response.keys, :publisher
    assert_includes response.keys, :page_count
    assert_includes response.keys, :language
    assert_includes response.keys, :availability_status
    assert_includes response.keys, :similar_books_count
    assert_includes response.keys, :reviews
  end

  test "should handle empty genres array" do
    @book.genres = []
    assert @book.valid?
    @book.save!
    assert_equal [], @book.reload.genres
  end

  test "should handle nil genres" do
    @book.genres = nil
    assert @book.valid?
    @book.save!
    assert_nil @book.reload.genres
  end

  test "should create sample data" do
    assert_difference "Book.count", 5 do
      Book.create_sample_data!
    end
  end
end
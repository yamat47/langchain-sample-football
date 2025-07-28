require "test_helper"

class BookSampleDataTest < ActiveSupport::TestCase
  def setup
    # Clear existing data in proper order to avoid foreign key constraints
    BookQuery.destroy_all
    Review.destroy_all
    BookSimilarity.destroy_all
    Book.destroy_all
  end

  test "should create at least 1000 sample books" do
    assert_difference "Book.count", 1000 do
      Book.create_sample_data!
    end
  end

  test "sample books should have diverse genres" do
    Book.create_sample_data!
    
    genres = Book.pluck(:genres).flatten.uniq
    assert genres.count >= 10, "Should have at least 10 different genres"
  end

  test "sample books should have various authors" do
    Book.create_sample_data!
    
    authors = Book.pluck(:author).uniq
    assert authors.count >= 20, "Should have at least 20 different authors"
  end

  test "sample books should have realistic ratings distribution" do
    Book.create_sample_data!
    
    ratings = Book.pluck(:rating)
    assert ratings.min >= 3.0, "Minimum rating should be at least 3.0"
    assert ratings.max <= 5.0, "Maximum rating should not exceed 5.0"
    
    # Check distribution
    low_rated = Book.where("rating < ?", 3.5).count
    mid_rated = Book.where("rating >= ? AND rating < ?", 3.5, 4.0).count
    high_rated = Book.where("rating >= ?", 4.0).count
    
    assert low_rated > 0, "Should have some low-rated books"
    assert mid_rated > 0, "Should have some mid-rated books"
    assert high_rated > 0, "Should have some high-rated books"
  end

  test "sample books should have various publication dates" do
    Book.create_sample_data!
    
    dates = Book.pluck(:published_at)
    oldest = dates.min
    newest = dates.max
    
    assert oldest < 20.years.ago, "Should have books older than 20 years"
    assert newest > 1.year.ago, "Should have recent books"
  end

  test "sample books should have different price ranges" do
    Book.create_sample_data!
    
    prices = Book.pluck(:price).compact
    assert prices.min < 1000, "Should have affordable books"
    assert prices.max > 2000, "Should have premium books"
  end

  test "sample books should include trending books" do
    Book.create_sample_data!
    
    trending_count = Book.where(is_trending: true).count
    assert trending_count >= 5, "Should have at least 5 trending books"
    assert trending_count <= 15, "Should not have too many trending books"
  end

  test "sample books should have various languages" do
    Book.create_sample_data!
    
    # At least some books in different languages
    english_books = Book.where(language: "en").count
    japanese_books = Book.where(language: "ja").count
    
    assert english_books > 0, "Should have English books"
    assert japanese_books > 0, "Should have Japanese books"
  end

  test "sample books should not duplicate ISBNs" do
    Book.create_sample_data!
    first_count = Book.count
    
    # Running again should not create duplicates
    Book.create_sample_data!
    assert_equal first_count, Book.count, "Should not create duplicate books"
  end
end
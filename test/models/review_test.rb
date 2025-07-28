require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  def setup
    @book = Book.create!(
      title: "Test Book",
      author: "Test Author",
      isbn: "123-456"
    )
    
    @review = Review.new(
      book: @book,
      reviewer_name: "John Doe",
      rating: 4,
      content: "Great book! Really enjoyed reading it."
    )
  end

  test "should be valid with valid attributes" do
    assert @review.valid?
  end

  test "should require book" do
    @review.book = nil
    assert_not @review.valid?
    assert_includes @review.errors[:book], "must exist"
  end

  test "should not require reviewer_name" do
    @review.reviewer_name = nil
    assert @review.valid?
  end

  test "should require rating" do
    @review.rating = nil
    assert_not @review.valid?
    assert_includes @review.errors[:rating], "can't be blank"
  end

  test "should validate rating between 1 and 5" do
    @review.rating = 0
    assert_not @review.valid?
    assert_includes @review.errors[:rating], "must be greater than or equal to 1"

    @review.rating = 6
    assert_not @review.valid?
    assert_includes @review.errors[:rating], "must be less than or equal to 5"

    @review.rating = 3
    assert @review.valid?
  end

  test "should require content" do
    @review.content = nil
    assert_not @review.valid?
    assert_includes @review.errors[:content], "can't be blank"
  end

  test "should belong to book" do
    assert_respond_to @review, :book
    assert_equal @book, @review.book
  end

  test "recent scope returns reviews ordered by created_at desc" do
    older_review = Review.create!(
      book: @book,
      reviewer_name: "Older",
      rating: 3,
      content: "Older review",
      created_at: 2.days.ago
    )
    
    newer_review = Review.create!(
      book: @book,
      reviewer_name: "Newer",
      rating: 4,
      content: "Newer review",
      created_at: 1.day.ago
    )
    
    results = Review.recent
    assert_equal newer_review, results.first
    assert_equal older_review, results.second
  end

  test "should update book rating after save" do
    @book.rating = 0.0
    @book.save!
    
    @review.save!
    @book.reload
    
    assert_equal 4.0, @book.rating
  end

  test "should update book rating with multiple reviews" do
    @book.rating = 0.0
    @book.save!
    
    @review.save!
    Review.create!(book: @book, rating: 2, content: "Not great")
    
    @book.reload
    assert_equal 3.0, @book.rating
  end

  test "should update book rating after destroy" do
    @book.rating = 0.0
    @book.save!
    
    @review.save!
    Review.create!(book: @book, rating: 2, content: "Not great")
    @book.reload
    assert_equal 3.0, @book.rating
    
    @review.destroy
    @book.reload
    assert_equal 2.0, @book.rating
  end

  test "should not allow blank content" do
    @review.content = nil
    assert_not @review.valid?
    
    @review.content = ""
    assert_not @review.valid?
  end

  test "should handle very long content" do
    @review.content = "A" * 5000
    assert @review.valid?
  end
end
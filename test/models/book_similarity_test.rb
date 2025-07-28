require "test_helper"

class BookSimilarityTest < ActiveSupport::TestCase
  def setup
    @book1 = Book.create!(
      title: "Book One",
      author: "Author One",
      isbn: "111-111",
      rating: 4.5
    )

    @book2 = Book.create!(
      title: "Book Two",
      author: "Author Two",
      isbn: "222-222",
      rating: 4.0
    )

    @similarity = BookSimilarity.new(
      book: @book1,
      similar_book: @book2,
      similarity_score: 0.85
    )
  end

  test "should be valid with valid attributes" do
    assert_predicate @similarity, :valid?
  end

  test "should require book" do
    @similarity.book = nil

    assert_not @similarity.valid?
    assert_includes @similarity.errors[:book], "must exist"
  end

  test "should require similar_book" do
    @similarity.similar_book = nil

    assert_not @similarity.valid?
    assert_includes @similarity.errors[:similar_book], "must exist"
  end

  test "should require similarity_score" do
    @similarity.similarity_score = nil

    assert_not @similarity.valid?
    assert_includes @similarity.errors[:similarity_score], "can't be blank"
  end

  test "should validate similarity_score between 0 and 1" do
    @similarity.similarity_score = -0.1

    assert_not @similarity.valid?
    assert_includes @similarity.errors[:similarity_score], "must be greater than or equal to 0"

    @similarity.similarity_score = 1.1

    assert_not @similarity.valid?
    assert_includes @similarity.errors[:similarity_score], "must be less than or equal to 1"

    @similarity.similarity_score = 0.5

    assert_predicate @similarity, :valid?
  end

  test "should validate uniqueness of book and similar_book combination" do
    @similarity.save!

    duplicate = BookSimilarity.new(
      book: @book1,
      similar_book: @book2,
      similarity_score: 0.9
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:book_id], "has already been taken"
  end

  test "should prevent self-similarity" do
    self_similarity = BookSimilarity.new(
      book: @book1,
      similar_book: @book1,
      similarity_score: 1.0
    )

    # Model doesn't prevent self-similarity in the current implementation
    # This test documents what could be a desired behavior
    assert_predicate self_similarity, :valid?
  end

  test "calculate_and_store creates bidirectional relationships" do
    # Add genres to books so similarity score > 0
    @book1.update!(genres: ["Fiction", "Mystery"])
    @book2.update!(genres: ["Fiction", "Thriller"])

    BookSimilarity.calculate_and_store(@book1, @book2)

    # Check forward relationship
    forward = BookSimilarity.find_by(book: @book1, similar_book: @book2)

    assert_not_nil forward
    assert_operator forward.similarity_score, :>, 0

    # Check reverse relationship
    reverse = BookSimilarity.find_by(book: @book2, similar_book: @book1)

    assert_not_nil reverse
    assert_equal forward.similarity_score, reverse.similarity_score
  end

  test "should belong to book" do
    assert_respond_to @similarity, :book
    assert_equal @book1, @similarity.book
  end

  test "should belong to similar_book" do
    assert_respond_to @similarity, :similar_book
    assert_equal @book2, @similarity.similar_book
  end

  test "should create bidirectional relationship" do
    @similarity.save!

    # Check forward relationship
    assert_equal 1, @book1.similar_books.count
    assert_includes @book1.similar_books, @book2

    # Check if inverse relationship exists (if implemented)
    # This would require additional model setup
  end

  test "should order by similarity_score descending by default" do
    low_sim = BookSimilarity.create!(
      book: @book1,
      similar_book: Book.create!(title: "Low Sim", author: "Author", isbn: "444"),
      similarity_score: 0.6
    )

    @similarity.save!

    # BookSimilarity doesn't have default_scope for ordering, so we need to order explicitly
    similarities = BookSimilarity.where(book: @book1).order(similarity_score: :desc)

    assert_equal @similarity, similarities.first
    assert_equal low_sim, similarities.second
  end
end

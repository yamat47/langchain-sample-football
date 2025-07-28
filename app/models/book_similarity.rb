# frozen_string_literal: true

class BookSimilarity < ApplicationRecord
  # Associations
  belongs_to :book
  belongs_to :similar_book, class_name: "Book"

  # Validations
  validates :similarity_score, presence: true,
                               numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
  validates :book_id, uniqueness: { scope: :similar_book_id }

  # Class methods
  def self.calculate_and_store(book1, book2)
    score = calculate_similarity_score(book1, book2)

    # Store bidirectionally
    create_or_update_similarity(book1, book2, score)
    create_or_update_similarity(book2, book1, score)
  end

  private_class_method def self.calculate_similarity_score(book1, book2)
    # Simple similarity calculation based on genres
    genres1 = book1.genres || []
    genres2 = book2.genres || []

    return 0.0 if genres1.empty? || genres2.empty?

    common_genres = genres1 & genres2
    total_genres = (genres1 | genres2).length

    # Add author similarity bonus
    author_bonus = book1.author == book2.author ? 0.2 : 0.0

    genre_score = (common_genres.length.to_f / total_genres)
    (genre_score + author_bonus).clamp(0.0, 1.0).round(2)
  end

  private_class_method def self.create_or_update_similarity(book, similar_book, score)
    similarity = find_or_initialize_by(
      book: book,
      similar_book: similar_book
    )
    similarity.update!(similarity_score: score)
  end
end
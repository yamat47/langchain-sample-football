# frozen_string_literal: true

class Book < ApplicationRecord
  # Associations
  has_many :book_similarities, dependent: :destroy
  has_many :similar_books, through: :book_similarities
  has_many :reviews, dependent: :destroy

  # Validations
  validates :isbn, presence: true, uniqueness: true
  validates :title, presence: true
  validates :author, presence: true

  # Scopes
  scope :highly_rated, -> { where("books.rating >= ?", 4.0) }
  scope :recent, -> { where("books.published_at >= ?", 1.year.ago) }
  scope :trending, -> { where(is_trending: true).order(trending_score: :desc) }

  # Search scopes
  scope :search_by_title, ->(query) {
    where("LOWER(title) LIKE ?", "%#{query.downcase}%")
  }

  scope :search_by_author, ->(query) {
    where("LOWER(author) LIKE ?", "%#{query.downcase}%")
  }

  # SQLite doesn't support array columns, so we'll use JSON serialization
  serialize :genres, coder: JSON

  # Custom scope for genre search
  scope :by_genre, ->(genre) {
    where("genres LIKE ?", "%#{genre}%")
  }

  # Instance methods
  def calculate_rating
    reviews.average(:rating) || 0.0
  end

  def review_count
    reviews.count
  end

  def find_similar(limit: 5)
    # Find similar books based on similarity scores
    similar_ids = book_similarities
      .order(similarity_score: :desc)
      .limit(limit)
      .pluck(:similar_book_id)

    if similar_ids.empty?
      # Fallback: find by matching genres
      Book.where.not(id: id)
          .where("genres LIKE ?", "%#{genres&.first}%")
          .limit(limit)
    else
      Book.where(id: similar_ids)
    end
  end

  def to_api_response
    {
      isbn: isbn,
      title: title,
      author: author,
      genres: genres || [],
      rating: rating,
      review_count: review_count,
      price: price,
      published_at: published_at&.strftime("%Y-%m-%d")
    }
  end

  def to_detailed_api_response
    to_api_response.merge(
      description: description,
      publisher: publisher,
      page_count: page_count,
      language: language,
      availability_status: availability_status,
      similar_books_count: similar_books.count,
      reviews: reviews.limit(3).map { |r|
        { rating: r.rating, content: r.content }
      }
    )
  end

  # Class methods for data seeding
  def self.create_sample_data!
    require 'book_data_generator'
    
    sample_books = BookDataGenerator.generate_books(1000)

    sample_books.each do |book_data|
      Book.find_or_create_by!(isbn: book_data[:isbn]) do |book|
        book.assign_attributes(book_data)
      end
    end
  end
end
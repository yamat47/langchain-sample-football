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
    sample_books = [
      {
        isbn: "978-0-7475-3269-9",
        title: "Harry Potter and the Philosopher's Stone",
        author: "J.K. Rowling",
        description: "The first book in the Harry Potter series...",
        genres: ["Fantasy", "Young Adult"],
        rating: 4.47,
        price: 1200,
        publisher: "Bloomsbury",
        page_count: 223,
        published_at: Date.new(1997, 6, 26),
        is_trending: true,
        trending_score: 95
      },
      {
        isbn: "978-0-06-112008-4",
        title: "To Kill a Mockingbird",
        author: "Harper Lee",
        description: "A classic of modern American literature...",
        genres: ["Classic", "Fiction"],
        rating: 4.28,
        price: 1000,
        publisher: "J. B. Lippincott & Co.",
        page_count: 281,
        published_at: Date.new(1960, 7, 11)
      },
      {
        isbn: "978-1-4088-5565-2",
        title: "The Midnight Library",
        author: "Matt Haig",
        description: "Between life and death there is a library...",
        genres: ["Fiction", "Philosophy"],
        rating: 4.02,
        price: 1500,
        publisher: "Canongate Books",
        page_count: 288,
        published_at: Date.new(2020, 8, 13),
        is_trending: true,
        trending_score: 88
      },
      {
        isbn: "978-0-385-53785-8",
        title: "Where the Crawdads Sing",
        author: "Delia Owens",
        description: "A coming-of-age murder mystery...",
        genres: ["Mystery", "Fiction"],
        rating: 4.46,
        price: 1400,
        publisher: "G.P. Putnam's Sons",
        page_count: 368,
        published_at: Date.new(2018, 8, 14)
      },
      {
        isbn: "978-1-250-31869-4",
        title: "The Silent Patient",
        author: "Alex Michaelides",
        description: "A shocking psychological thriller...",
        genres: ["Thriller", "Mystery"],
        rating: 4.08,
        price: 1600,
        publisher: "Celadon Books",
        page_count: 336,
        published_at: Date.new(2019, 2, 5),
        is_trending: true,
        trending_score: 82
      }
    ]

    sample_books.each do |book_data|
      Book.find_or_create_by!(isbn: book_data[:isbn]) do |book|
        book.assign_attributes(book_data)
      end
    end
  end
end
# frozen_string_literal: true

class Review < ApplicationRecord
  # Associations
  belongs_to :book

  # Validations
  validates :rating, presence: true,
                     numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
  validates :content, presence: true

  after_destroy :update_book_rating
  # Callbacks
  after_save :update_book_rating

  # Scopes
  scope :recent, -> { order(created_at: :desc) }

  private

  def update_book_rating
    book.update!(rating: book.calculate_rating)
  end
end

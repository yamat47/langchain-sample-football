# frozen_string_literal: true

namespace :book_data do
  desc "Generate sample book data"
  task generate: :environment do
    puts "Creating sample books..."
    Book.create_sample_data!

    puts "Creating sample reviews..."
    Book.find_each do |book|
      # Create 2-5 reviews per book
      rand(2..5).times do
        Review.create!(
          book: book,
          rating: rand(3..5),
          content: ["Great book!", "Highly recommended!", "Enjoyed reading this.", "Worth the read.", "Fantastic story!"].sample,
          reviewer_name: ["Alice", "Bob", "Charlie", "Diana", "Eve", "Frank"].sample
        )
      end
    end

    puts "Calculating book similarities..."
    Book.find_each do |book|
      # Find and create similarities with other books
      similar_books = Book.where.not(id: book.id)
                          .where("genres LIKE ?", "%#{book.genres&.first}%")
                          .limit(5)

      similar_books.each do |similar_book|
        BookSimilarity.calculate_and_store(book, similar_book)
      end
    end

    puts "Sample data generation complete!"
    puts "Created #{Book.count} books"
    puts "Created #{Review.count} reviews"
    puts "Created #{BookSimilarity.count} similarity relationships"
  end

  desc "Update trending scores"
  task update_trending: :environment do
    # Simple trending algorithm
    Book.update_all(is_trending: false, trending_score: 0)

    # Mark recent highly-rated books as trending
    trending_books = Book.recent
                         .highly_rated
                         .joins(:reviews)
                         .group("books.id")
                         .having("COUNT(reviews.id) > ?", 3)
                         .limit(10)

    trending_books.each_with_index do |book, index|
      book.update!(
        is_trending: true,
        trending_score: 100 - (index * 10)
      )
    end

    puts "Updated #{trending_books.size} trending books"
  end

  desc "Clear all book data"
  task clear: :environment do
    puts "Clearing all book data..."
    BookQuery.destroy_all
    Review.destroy_all
    BookSimilarity.destroy_all
    Book.destroy_all
    puts "All book data cleared!"
  end
end
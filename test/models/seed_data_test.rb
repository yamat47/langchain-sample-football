# frozen_string_literal: true

require "test_helper"

class SeedDataTest < ActiveSupport::TestCase
  test "seeds file should run without errors" do
    # Clear existing data
    Review.destroy_all
    Book.destroy_all
    
    # Load the seeds file
    assert_nothing_raised do
      load Rails.root.join("db/seeds.rb")
    end
    
    # Verify data was created
    assert Book.count > 0, "Books should be created"
    assert Review.count > 0, "Reviews should be created"
  end
  
  test "all books should have required attributes" do
    # Clear and reload seed data
    Review.destroy_all
    Book.destroy_all
    load Rails.root.join("db/seeds.rb")
    
    Book.all.each do |book|
      assert book.title.present?, "Book should have a title"
      assert book.author.present?, "Book should have an author"
      assert book.isbn.present?, "Book should have an ISBN"
      assert book.genres.present?, "Book should have genres"
      assert book.genres.is_a?(Array), "Genres should be an array"
    end
  end
  
  test "all reviews should have required attributes" do
    # Clear and reload seed data
    Review.destroy_all
    Book.destroy_all
    load Rails.root.join("db/seeds.rb")
    
    Review.all.each do |review|
      assert review.content.present?, "Review should have content"
      assert review.rating.present?, "Review should have a rating"
      assert (1..5).include?(review.rating), "Rating should be between 1 and 5"
      assert review.reviewer_name.present?, "Review should have a reviewer name"
      assert review.book.present?, "Review should belong to a book"
    end
  end
  
  test "seed data should be idempotent" do
    # Clear existing data
    Review.destroy_all
    Book.destroy_all
    
    # Run seeds twice
    2.times { load Rails.root.join("db/seeds.rb") }
    
    # Count should be the same as running once
    book_count = Book.count
    review_count = Review.count
    
    # Run seeds again
    load Rails.root.join("db/seeds.rb")
    
    # Counts should remain the same
    assert_equal book_count, Book.count, "Book count should not change on repeated seed runs"
    assert_equal review_count, Review.count, "Review count should not change on repeated seed runs"
  end
  
  test "all seed data should use English text" do
    # Clear and reload seed data
    Review.destroy_all
    Book.destroy_all
    load Rails.root.join("db/seeds.rb")
    
    # Check review content is in English (simple check for non-ASCII characters)
    Review.all.each do |review|
      # Most English text should be ASCII, with occasional accented characters
      non_ascii_count = review.content.chars.count { |c| c.ord > 127 }
      ascii_count = review.content.chars.count { |c| c.ord <= 127 }
      
      # English text should be mostly ASCII
      assert ascii_count > non_ascii_count * 10, 
             "Review content should be primarily in English: #{review.content[0..50]}..."
    end
    
    # Check reviewer names are in English format
    Review.all.each do |review|
      assert review.reviewer_name.match?(/\A[A-Za-z0-9_]+\z/), 
             "Reviewer name should be in English format: #{review.reviewer_name}"
    end
  end
end
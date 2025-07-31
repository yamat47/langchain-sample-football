# frozen_string_literal: true

require "test_helper"

class AddImageUrlsToBooksTest < ActiveSupport::TestCase
  test "image_url and thumbnail_url columns should exist on books table" do
    # Verify columns exist (they were added by migration)
    assert_includes Book.column_names, "image_url", "image_url column should exist"
    assert_includes Book.column_names, "thumbnail_url", "thumbnail_url column should exist"

    # Verify column types
    image_url_column = Book.columns.find { |c| c.name == "image_url" }
    thumbnail_url_column = Book.columns.find { |c| c.name == "thumbnail_url" }

    assert_equal :string, image_url_column.type
    assert_equal :string, thumbnail_url_column.type
  end

  test "should allow storing URLs in new columns" do
    # Create a book with image URLs
    book = Book.create!(
      isbn: "test-#{SecureRandom.hex(4)}",
      title: "Test Book with Images",
      author: "Test Author",
      image_url: "https://example.com/book-cover.jpg",
      thumbnail_url: "https://example.com/book-thumb.jpg"
    )

    # Verify data persistence
    book.reload

    assert_equal "https://example.com/book-cover.jpg", book.image_url
    assert_equal "https://example.com/book-thumb.jpg", book.thumbnail_url
  end

  test "should allow nil values for image URLs" do
    # Create a book without image URLs
    book = Book.create!(
      isbn: "test-#{SecureRandom.hex(4)}",
      title: "Test Book without Images",
      author: "Test Author"
    )

    # Verify nil values are allowed
    assert_nil book.image_url
    assert_nil book.thumbnail_url
  end
end

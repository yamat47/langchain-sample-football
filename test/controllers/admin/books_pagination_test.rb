require "test_helper"

module Admin
  class BooksPaginationTest < ActionDispatch::IntegrationTest
    def setup
      # Clear existing data to have predictable counts
      BookQuery.destroy_all
      Review.destroy_all
      BookSimilarity.destroy_all
      Book.destroy_all

      # Create 35 books to test pagination (more than one page)
      35.times do |i|
        Book.create!(
          isbn: "978-0-#{1000 + i}-00000-#{i}",
          title: "Test Book #{i + 1}",
          author: "Test Author #{i + 1}",
          rating: 4.0,
          price: 1000
        )
      end
    end

    test "should paginate books with 25 per page by default" do
      get admin_books_url

      assert_response :success

      # Should show 25 books on first page
      assert_select "tr.book-row", 25

      # Should have pagination controls
      assert_select "nav.pagination"
      assert_select "a", text: "2"
    end

    test "should show second page of books" do
      get admin_books_url, params: { page: 2 }

      assert_response :success

      # Should show remaining 10 books on second page
      assert_select "tr.book-row", 10
    end

    test "should handle per_page parameter" do
      get admin_books_url, params: { per_page: 10 }

      assert_response :success

      # Should show 10 books per page
      assert_select "tr.book-row", 10

      # Should have 4 pages total
      assert_select "a", text: "4"
    end

    test "should show book count information" do
      get admin_books_url

      assert_response :success

      # Should display total count
      assert_select ".book-count", text: /Showing 1-25 of 35 books/
    end

    test "should maintain search params across pages" do
      # Create a book with specific title
      Book.create!(
        isbn: "978-0-9999-99999-9",
        title: "Special Search Book",
        author: "Special Author",
        rating: 5.0,
        price: 2000
      )

      get admin_books_url, params: { search: "Special", page: 1 }

      assert_response :success

      # Should include search param in pagination links
      assert_select "a[href*='search=Special']"
    end
  end
end

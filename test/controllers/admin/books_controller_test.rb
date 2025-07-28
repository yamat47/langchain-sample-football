require "test_helper"

class Admin::BooksControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_books_url
    assert_response :success
  end

  test "should get show" do
    book = Book.create!(title: "Test Book", author: "Test Author", isbn: "123-456")
    get admin_book_url(book)
    assert_response :success
  end
end

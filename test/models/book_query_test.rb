require "test_helper"

class BookQueryTest < ActiveSupport::TestCase
  def setup
    @query = BookQuery.new(
      query_text: "Find me mystery books",
      response_text: "Here are some great mystery books...",
      success: true,
      response_time_ms: 1500,
      error_message: nil
    )
  end

  test "should be valid with valid attributes" do
    assert_predicate @query, :valid?
  end

  test "should require query_text" do
    @query.query_text = nil

    assert_not @query.valid?
    assert_includes @query.errors[:query_text], "can't be blank"
  end

  test "should allow any response_time_ms value" do
    # Model doesn't validate response_time_ms
    @query.response_time_ms = -1

    assert_predicate @query, :valid?

    @query.response_time_ms = 0

    assert_predicate @query, :valid?
  end

  test "recent scope returns queries ordered by created_at desc" do
    older_query = BookQuery.create!(
      query_text: "Old query",
      created_at: 2.hours.ago
    )

    newer_query = BookQuery.create!(
      query_text: "New query",
      created_at: 1.hour.ago
    )

    results = BookQuery.recent

    assert_equal newer_query, results.first
    assert_equal older_query, results.second
  end

  test "successful scope returns only successful queries" do
    @query.save!

    BookQuery.create!(
      query_text: "Failed query",
      success: false,
      error_message: "Something went wrong"
    )

    results = BookQuery.successful

    assert_equal 1, results.count
    assert_equal @query, results.first
  end

  test "successful scope filters by success status" do
    # Create one successful and one failed query
    successful = BookQuery.create!(
      query_text: "Successful query",
      success: true
    )

    BookQuery.create!(
      query_text: "Failed query",
      success: false
    )

    results = BookQuery.successful

    assert_equal 1, results.count
    assert_equal successful, results.first
  end

  test "log_query creates new record" do
    assert_difference "BookQuery.count", 1 do
      BookQuery.log_query(
        "Test query",
        "Test response",
        true,
        1500
      )
    end

    query = BookQuery.last

    assert_equal "Test query", query.query_text
    assert_equal "Test response", query.response_text
    assert query.success
    assert_equal 1500, query.response_time_ms
  end

  test "log_query creates record with full_response" do
    full_response_json = { blocks: [{ type: "text", content: { markdown: "Test" } }] }.to_json

    assert_difference "BookQuery.count", 1 do
      BookQuery.log_query(
        "Test query with full response",
        "Test response",
        true,
        1500,
        full_response_json
      )
    end

    query = BookQuery.last

    assert_equal "Test query with full response", query.query_text
    assert_equal "Test response", query.response_text
    assert query.success
    assert_equal 1500, query.response_time_ms
    assert_equal full_response_json, query.full_response
  end

  test "should allow blank response_text" do
    @query.response_text = nil

    assert_predicate @query, :valid?

    @query.response_text = ""

    assert_predicate @query, :valid?
  end

  test "should allow blank error_message" do
    @query.error_message = nil

    assert_predicate @query, :valid?

    @query.error_message = ""

    assert_predicate @query, :valid?
  end

  test "should default success to false" do
    query = BookQuery.new(query_text: "Test")

    assert_not query.success
  end

  test "should track failed queries with error messages" do
    failed_query = BookQuery.create!(
      query_text: "This will fail",
      success: false,
      error_message: "OpenAI API rate limit exceeded",
      response_time_ms: 100
    )

    assert_predicate failed_query, :persisted?
    assert_not failed_query.success
    assert_equal "OpenAI API rate limit exceeded", failed_query.error_message
  end

  test "should calculate average response time" do
    BookQuery.create!(query_text: "Query 1", response_time_ms: 1000)
    BookQuery.create!(query_text: "Query 2", response_time_ms: 2000)
    BookQuery.create!(query_text: "Query 3", response_time_ms: 3000)

    average = BookQuery.average(:response_time_ms)

    assert_in_delta(2000.0, average)
  end

  test "should handle very long query texts" do
    @query.query_text = "A" * 1000

    assert_predicate @query, :valid?
  end

  test "should handle very long response texts" do
    @query.response_text = "B" * 10_000

    assert_predicate @query, :valid?
  end
end

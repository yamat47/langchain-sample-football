require "test_helper"

class ChatSessionTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(identifier: "testuser")
  end

  # Validation tests
  test "should be valid with valid attributes" do
    chat_session = @user.chat_sessions.build

    assert_predicate chat_session, :valid?
  end

  test "should belong to a user" do
    chat_session = ChatSession.new

    assert_not chat_session.valid?
    assert_includes chat_session.errors[:user], "must exist"
  end

  test "should set last_activity_at before validation if not present" do
    chat_session = @user.chat_sessions.build

    assert_nil chat_session.last_activity_at

    chat_session.valid?

    assert_not_nil chat_session.last_activity_at
    assert_in_delta Time.current.to_f, chat_session.last_activity_at.to_f, 1.0
  end

  test "should validate presence of last_activity_at" do
    chat_session = @user.chat_sessions.build
    chat_session.last_activity_at = nil
    chat_session.valid?
    # Should be valid because it sets it automatically
    assert_predicate chat_session, :valid?
  end

  # Session number tests
  test "should set session_number automatically on create" do
    chat_session = @user.chat_sessions.create!

    assert_equal 1, chat_session.session_number
  end

  test "should increment session_number for each new session" do
    session1 = @user.chat_sessions.create!
    session2 = @user.chat_sessions.create!
    session3 = @user.chat_sessions.create!

    assert_equal 1, session1.session_number
    assert_equal 2, session2.session_number
    assert_equal 3, session3.session_number
  end

  test "should have unique session_number per user" do
    user2 = User.create!(identifier: "anotheruser")

    session1 = @user.chat_sessions.create!
    session2 = user2.chat_sessions.create!

    assert_equal 1, session1.session_number
    assert_equal 1, session2.session_number
  end

  test "should validate uniqueness of session_number scoped to user" do
    @user.chat_sessions.create!(session_number: 1)

    duplicate = @user.chat_sessions.build(session_number: 1)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:session_number], "has already been taken"
  end

  # Association tests
  test "should have many chat messages" do
    chat_session = @user.chat_sessions.build

    assert_respond_to chat_session, :chat_messages
  end

  test "should destroy associated chat messages when destroyed" do
    chat_session = @user.chat_sessions.create!

    chat_session.chat_messages.create!(role: "user", content: "Hello")
    assert_difference "ChatMessage.count", -1 do
      chat_session.destroy
    end
  end

  # Scope tests
  test "recent scope should order by last_activity_at descending" do
    old_session = @user.chat_sessions.create!(last_activity_at: 2.days.ago)
    new_session = @user.chat_sessions.create!(last_activity_at: 1.hour.ago)
    middle_session = @user.chat_sessions.create!(last_activity_at: 1.day.ago)

    recent_sessions = @user.chat_sessions.recent

    assert_equal [new_session, middle_session, old_session], recent_sessions.to_a
  end

  test "ordered scope should order by session_number descending" do
    session1 = @user.chat_sessions.create!
    session2 = @user.chat_sessions.create!
    session3 = @user.chat_sessions.create!

    ordered_sessions = @user.chat_sessions.ordered

    assert_equal [session3, session2, session1], ordered_sessions.to_a
  end

  # Display name test
  test "should have display_name method" do
    chat_session = @user.chat_sessions.create!

    assert_equal "Session #1", chat_session.display_name

    session2 = @user.chat_sessions.create!

    assert_equal "Session #2", session2.display_name
  end

  # Counter cache test
  test "should have messages_count with default value 0" do
    chat_session = @user.chat_sessions.create!

    assert_equal 0, chat_session.messages_count
  end

  # Edge cases
  test "should handle session_number assignment if manually set" do
    chat_session = @user.chat_sessions.build(session_number: 5)
    chat_session.save!

    assert_equal 5, chat_session.session_number

    # Next auto-generated should be 6
    next_session = @user.chat_sessions.create!

    assert_equal 6, next_session.session_number
  end
end

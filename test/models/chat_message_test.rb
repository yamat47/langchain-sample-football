require "test_helper"

class ChatMessageTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(identifier: "testuser")
    @chat_session = @user.chat_sessions.create!
  end

  # Validation tests
  test "should be valid with valid attributes" do
    message = @chat_session.chat_messages.build(role: "user", content: "Hello")

    assert_predicate message, :valid?
  end

  test "should belong to a chat session" do
    message = ChatMessage.new(role: "user", content: "Hello")

    assert_not message.valid?
    assert_includes message.errors[:chat_session], "must exist"
  end

  test "should require role" do
    message = @chat_session.chat_messages.build(content: "Hello")

    assert_not message.valid?
    assert_includes message.errors[:role], "can't be blank"
  end

  test "should require content" do
    message = @chat_session.chat_messages.build(role: "user")

    assert_not message.valid?
    assert_includes message.errors[:content], "can't be blank"
  end

  test "should validate role inclusion" do
    valid_roles = ["user", "assistant", "system"]

    valid_roles.each do |role|
      message = @chat_session.chat_messages.build(role: role, content: "Test")

      assert_predicate message, :valid?, "Role '#{role}' should be valid"
    end

    invalid_roles = ["admin", "bot", "tool", "unknown"]
    invalid_roles.each do |role|
      message = @chat_session.chat_messages.build(role: role, content: "Test")

      assert_not message.valid?, "Role '#{role}' should be invalid"
      assert_includes message.errors[:role], "is not included in the list"
    end
  end

  # Position tests
  test "should set position automatically on create" do
    message = @chat_session.chat_messages.create!(role: "user", content: "Hello")

    assert_equal 1, message.position
  end

  test "should increment position for each new message" do
    msg1 = @chat_session.chat_messages.create!(role: "user", content: "First")
    msg2 = @chat_session.chat_messages.create!(role: "assistant", content: "Second")
    msg3 = @chat_session.chat_messages.create!(role: "user", content: "Third")

    assert_equal 1, msg1.position
    assert_equal 2, msg2.position
    assert_equal 3, msg3.position
  end

  test "should have unique position within chat session" do
    @chat_session.chat_messages.create!(role: "user", content: "First", position: 1)

    duplicate = @chat_session.chat_messages.build(role: "user", content: "Second", position: 1)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:position], "has already been taken"
  end

  test "position should be scoped to chat session" do
    session2 = @user.chat_sessions.create!

    msg1 = @chat_session.chat_messages.create!(role: "user", content: "First")
    msg2 = session2.chat_messages.create!(role: "user", content: "First in session 2")

    assert_equal 1, msg1.position
    assert_equal 1, msg2.position
  end

  # Counter cache test
  test "should update messages_count on chat session" do
    assert_equal 0, @chat_session.reload.messages_count

    @chat_session.chat_messages.create!(role: "user", content: "Hello")

    assert_equal 1, @chat_session.reload.messages_count

    @chat_session.chat_messages.create!(role: "assistant", content: "Hi")

    assert_equal 2, @chat_session.reload.messages_count
  end

  test "should decrement messages_count when destroyed" do
    message = @chat_session.chat_messages.create!(role: "user", content: "Hello")

    assert_equal 1, @chat_session.reload.messages_count

    message.destroy

    assert_equal 0, @chat_session.reload.messages_count
  end

  # Activity update test
  test "should update session last_activity_at after create" do
    original_time = 1.hour.ago
    @chat_session.update!(last_activity_at: original_time)

    assert_in_delta original_time.to_f, @chat_session.last_activity_at.to_f, 1.0

    @chat_session.chat_messages.create!(role: "user", content: "New message")

    assert_in_delta Time.current.to_f, @chat_session.reload.last_activity_at.to_f, 1.0
  end

  # Scope test
  test "ordered scope should order by position" do
    msg3 = @chat_session.chat_messages.create!(role: "user", content: "Third", position: 3)
    msg1 = @chat_session.chat_messages.create!(role: "user", content: "First", position: 1)
    msg2 = @chat_session.chat_messages.create!(role: "assistant", content: "Second", position: 2)

    ordered = @chat_session.chat_messages.ordered

    assert_equal [msg1, msg2, msg3], ordered.to_a
  end

  # Edge cases
  test "should handle manual position assignment" do
    msg1 = @chat_session.chat_messages.create!(role: "user", content: "First", position: 5)

    assert_equal 5, msg1.position

    # Next auto-generated should be 6
    msg2 = @chat_session.chat_messages.create!(role: "user", content: "Second")

    assert_equal 6, msg2.position
  end

  test "should handle empty content validation" do
    message = @chat_session.chat_messages.build(role: "user", content: "")

    assert_not message.valid?
    assert_includes message.errors[:content], "can't be blank"
  end
end

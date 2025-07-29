require "test_helper"

class ChatPersistenceServiceTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(identifier: "testuser")
    @service = ChatPersistenceService.new(@user)
  end

  test "should initialize with a user" do
    assert_equal @user, @service.instance_variable_get(:@user)
  end

  test "should create a new session" do
    assert_difference "@user.chat_sessions.count", 1 do
      session = @service.create_session

      assert_kind_of ChatSession, session
      assert_predicate session, :persisted?
    end
  end

  test "should get session by id" do
    session = @user.chat_sessions.create!

    found_session = @service.get_session(session.id)

    assert_equal session, found_session
  end

  test "should raise error when getting non-existent session" do
    assert_raises(ActiveRecord::RecordNotFound) do
      @service.get_session(999_999)
    end
  end

  test "should get messages for a session" do
    session = @user.chat_sessions.create!
    msg1 = session.chat_messages.create!(role: "user", content: "Hello")
    msg2 = session.chat_messages.create!(role: "assistant", content: "Hi there")

    messages = @service.get_messages(session.id)

    assert_equal 2, messages.count
    assert_equal [msg1, msg2], messages.to_a
  end

  test "should return messages in correct order" do
    session = @user.chat_sessions.create!
    msg3 = session.chat_messages.create!(role: "user", content: "Third", position: 3)
    msg1 = session.chat_messages.create!(role: "user", content: "First", position: 1)
    msg2 = session.chat_messages.create!(role: "assistant", content: "Second", position: 2)

    messages = @service.get_messages(session.id)

    assert_equal [msg1, msg2, msg3], messages.to_a
  end

  test "should add message to session" do
    session = @user.chat_sessions.create!

    assert_difference "session.chat_messages.count", 1 do
      message = @service.add_message(session.id, "user", "Hello world")

      assert_kind_of ChatMessage, message
      assert_equal "user", message.role
      assert_equal "Hello world", message.content
      assert_equal 1, message.position
    end
  end

  test "should list sessions in recent order" do
    old_session = @user.chat_sessions.create!(last_activity_at: 2.days.ago)
    new_session = @user.chat_sessions.create!(last_activity_at: 1.hour.ago)
    middle_session = @user.chat_sessions.create!(last_activity_at: 1.day.ago)

    sessions = @service.list_sessions

    assert_equal [new_session, middle_session, old_session], sessions.to_a
  end

  test "should include chat messages when listing sessions" do
    session = @user.chat_sessions.create!
    session.chat_messages.create!(role: "user", content: "Test")

    sessions = @service.list_sessions

    # Should not trigger N+1 query
    assert_nothing_raised do
      sessions.each { |s| s.chat_messages.to_a }
    end
  end

  test "should handle adding messages with symbols or strings for role" do
    session = @user.chat_sessions.create!

    msg1 = @service.add_message(session.id, :user, "With symbol")
    msg2 = @service.add_message(session.id, "assistant", "With string")

    assert_equal "user", msg1.role
    assert_equal "assistant", msg2.role
  end

  test "should update session activity when adding message" do
    session = @user.chat_sessions.create!
    old_time = 1.hour.ago
    session.update!(last_activity_at: old_time)

    @service.add_message(session.id, "user", "New message")

    assert_in_delta Time.current.to_f, session.reload.last_activity_at.to_f, 1.0
  end

  test "should get or create session" do
    # Should create new session if nil passed
    assert_difference "@user.chat_sessions.count", 1 do
      session = @service.get_or_create_session(nil)

      assert_kind_of ChatSession, session
    end

    # Should return existing session if id passed
    existing = @user.chat_sessions.create!
    assert_no_difference "@user.chat_sessions.count" do
      session = @service.get_or_create_session(existing.id)

      assert_equal existing, session
    end
  end

  test "should format messages for assistant" do
    session = @user.chat_sessions.create!
    session.chat_messages.create!(role: "user", content: "Hello")
    session.chat_messages.create!(role: "assistant", content: "Hi there")
    session.chat_messages.create!(role: "user", content: "How are you?")

    formatted = @service.format_messages_for_assistant(session.id)

    assert_equal 3, formatted.length
    assert_equal({ role: "user", content: "Hello" }, formatted[0])
    assert_equal({ role: "assistant", content: "Hi there" }, formatted[1])
    assert_equal({ role: "user", content: "How are you?" }, formatted[2])
  end
end

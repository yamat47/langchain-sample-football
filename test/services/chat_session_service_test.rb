require "test_helper"

class ChatSessionServiceTest < ActiveSupport::TestCase
  def setup
    @session_id = SecureRandom.uuid
  end

  test "should return empty array for new session" do
    messages = ChatSessionService.get_messages(@session_id)
    assert_equal [], messages
  end

  test "should add and retrieve messages" do
    ChatSessionService.add_message(@session_id, "user", "Hello")
    ChatSessionService.add_message(@session_id, "assistant", "Hi there!")
    
    messages = ChatSessionService.get_messages(@session_id)
    assert_equal 2, messages.length
    assert_equal "user", messages[0][:role]
    assert_equal "Hello", messages[0][:content]
    assert_equal "assistant", messages[1][:role]
    assert_equal "Hi there!", messages[1][:content]
  end

  test "should limit message history to MAX_MESSAGES" do
    # Add more than MAX_MESSAGES
    25.times do |i|
      ChatSessionService.add_message(@session_id, "user", "Message #{i}")
    end
    
    messages = ChatSessionService.get_messages(@session_id)
    assert_equal ChatSessionService::MAX_MESSAGES, messages.length
    assert_equal "Message 5", messages.first[:content] # Should keep last 20 messages
  end

  test "should update all messages at once" do
    initial_messages = [
      { role: "user", content: "First" },
      { role: "assistant", content: "Second" }
    ]
    
    ChatSessionService.update_messages(@session_id, initial_messages)
    
    messages = ChatSessionService.get_messages(@session_id)
    assert_equal 2, messages.length
    assert_equal "First", messages[0][:content]
  end

  test "should clear session" do
    ChatSessionService.add_message(@session_id, "user", "Test")
    assert_not_empty ChatSessionService.get_messages(@session_id)
    
    ChatSessionService.clear_session(@session_id)
    assert_empty ChatSessionService.get_messages(@session_id)
  end

  test "should handle different sessions independently" do
    session_id_2 = SecureRandom.uuid
    
    ChatSessionService.add_message(@session_id, "user", "Session 1")
    ChatSessionService.add_message(session_id_2, "user", "Session 2")
    
    messages1 = ChatSessionService.get_messages(@session_id)
    messages2 = ChatSessionService.get_messages(session_id_2)
    
    assert_equal "Session 1", messages1[0][:content]
    assert_equal "Session 2", messages2[0][:content]
  end
end
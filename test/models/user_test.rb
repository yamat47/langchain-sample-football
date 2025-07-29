require "test_helper"

class UserTest < ActiveSupport::TestCase
  # Validation tests
  test "should be valid with valid attributes" do
    user = User.new(identifier: "yamat47")

    assert_predicate user, :valid?
  end

  test "should require identifier" do
    user = User.new(identifier: nil)

    assert_not user.valid?
    assert_includes user.errors[:identifier], "can't be blank"
  end

  test "should require alphanumeric identifier" do
    invalid_identifiers = ["user@123", "user-123", "user 123", "user.123", "ユーザー"]

    invalid_identifiers.each do |invalid_id|
      user = User.new(identifier: invalid_id)

      assert_not user.valid?, "#{invalid_id} should be invalid"
      assert_includes user.errors[:identifier], "is invalid"
    end
  end

  test "should accept valid alphanumeric identifiers" do
    valid_identifiers = ["user123", "User123", "123user", "u", "U", "1", "abc123DEF"]

    valid_identifiers.each do |valid_id|
      user = User.new(identifier: valid_id)

      assert_predicate user, :valid?, "#{valid_id} should be valid"
    end
  end

  test "should enforce unique identifier case-insensitively" do
    User.create!(identifier: "YamaT47")

    duplicate_user = User.new(identifier: "yamat47")

    assert_not duplicate_user.valid?
    assert_includes duplicate_user.errors[:identifier], "has already been taken"
  end

  # Normalization tests
  test "should normalize identifier to lowercase before saving" do
    user = User.create!(identifier: "YamaT47")

    assert_equal "yamat47", user.identifier
  end

  test "should normalize identifier to lowercase on validation" do
    user = User.new(identifier: "YamaT47")
    user.valid?

    assert_equal "yamat47", user.identifier
  end

  # Association tests
  test "should have many chat sessions" do
    user = User.new(identifier: "testuser")

    assert_respond_to user, :chat_sessions
  end

  test "should destroy associated chat sessions when destroyed" do
    user = User.create!(identifier: "testuser")

    user.chat_sessions.create!
    assert_difference "ChatSession.count", -1 do
      user.destroy
    end
  end

  # Edge cases
  test "should handle blank identifier" do
    user = User.new(identifier: "")

    assert_not user.valid?
    assert_includes user.errors[:identifier], "can't be blank"
  end

  test "should handle whitespace in identifier" do
    user = User.new(identifier: "  yamat47  ")
    user.valid?
    # Should not strip whitespace, just mark as invalid
    assert_not user.valid?
  end
end

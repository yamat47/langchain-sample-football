require "test_helper"

class UserServiceTest < ActiveSupport::TestCase
  test "should find existing user by identifier" do
    existing_user = User.create!(identifier: "existinguser")

    found_user = UserService.find_or_create_by_identifier("ExistingUser")

    assert_equal existing_user, found_user
  end

  test "should create new user if not exists" do
    assert_difference "User.count", 1 do
      user = UserService.find_or_create_by_identifier("newuser")

      assert_equal "newuser", user.identifier
    end
  end

  test "should normalize identifier before finding or creating" do
    user = UserService.find_or_create_by_identifier("NewUser123")

    assert_equal "newuser123", user.identifier

    # Should find the same user with different case
    same_user = UserService.find_or_create_by_identifier("NEWUSER123")

    assert_equal user, same_user
  end

  test "should return nil for blank identifier" do
    assert_nil UserService.find_or_create_by_identifier("")
    assert_nil UserService.find_or_create_by_identifier(nil)
    assert_nil UserService.find_or_create_by_identifier("   ")
  end

  test "should handle invalid identifiers" do
    # Invalid characters should cause validation error
    user = UserService.find_or_create_by_identifier("user@123")

    assert_not user.persisted?
    assert_not user.valid?
  end

  test "should be thread-safe for concurrent requests" do
    # Simulate concurrent requests for the same identifier
    threads = []
    users = []

    5.times do
      threads << Thread.new do
        users << UserService.find_or_create_by_identifier("concurrentuser")
      end
    end

    threads.each(&:join)

    # All threads should get the same user
    assert_equal 1, users.uniq.compact.size
    assert_equal 1, User.where(identifier: "concurrentuser").count
  end
end

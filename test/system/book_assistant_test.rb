require "application_system_test_case"

class BookAssistantTest < ApplicationSystemTestCase
  test "clears input field after sending message" do
    visit book_assistant_index_path

    # Fill in the input field
    fill_in "message", with: "Test message"

    # Submit the form
    click_button "Send"

    # Check that input field is cleared
    assert_equal "", find_field("message").value
  end

  test "disables submit button while processing" do
    visit book_assistant_index_path

    # Fill in the input field
    fill_in "message", with: "Test message"

    # Click submit and immediately check button state
    submit_button = find_button("Send")
    submit_button.click

    # Button should be disabled and show "Sending..."
    assert_predicate submit_button, :disabled?
    assert_match(/Sending/, submit_button.text)
  end

  test "hides introduction text after first message" do
    visit book_assistant_index_path

    # Initial greeting should be visible
    assert_selector "#initial-greeting", visible: true

    # Send a message
    fill_in "message", with: "Hello"
    click_button "Send"

    # Wait for response
    sleep 0.5

    # Initial greeting should be hidden
    assert_selector "#initial-greeting", visible: false
  end

  test "re-enables form after response" do
    visit book_assistant_index_path

    # Send a message
    fill_in "message", with: "Hello"
    click_button "Send"

    # Wait for response
    sleep 1

    # Form should be re-enabled
    submit_button = find_button("Send")

    assert_not submit_button.disabled?
    assert_equal "Send", submit_button.text

    # Input field should be enabled
    input_field = find_field("message")

    assert_not input_field.disabled?
  end
end

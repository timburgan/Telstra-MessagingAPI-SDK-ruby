require 'minitest/autorun'
require 'minitest/pride'
require 'json'
require_relative '../lib/Telstra_Messaging'

# Test helper for Telstra Messaging API SDK tests
class TestHelper < Minitest::Test
  
  # Common setup for all tests
  def setup
    @client_config = Telstra_Messaging::Configuration.new
  end

  # Helper method to load fixture data
  def load_fixture(filename)
    file_path = File.join(File.dirname(__FILE__), 'fixtures', filename)
    File.read(file_path)
  end

  # Helper method to load JSON fixture data
  def load_json_fixture(filename)
    JSON.parse(load_fixture(filename))
  end

  # Helper method to create a valid phone number for testing
  def valid_phone_number
    '+61412345678'
  end

  # Helper method to create an invalid phone number for testing
  def invalid_phone_number
    '123'
  end

  # Helper method to create valid SMS message content
  def valid_sms_body
    'Test message from Telstra Messaging API SDK'
  end

  # Helper method to create test message ID
  def test_message_id
    'test_message_id_12345'
  end
end

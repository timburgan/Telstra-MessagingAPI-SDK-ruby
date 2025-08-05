# frozen_string_literal: true

require_relative 'test_helper'

class RubyVersionTest < TestHelper
  
  def test_ruby_version_requirements
    # Test that we're running on a supported Ruby version
    ruby_version = RUBY_VERSION
    major, minor = ruby_version.split('.').map(&:to_i)
    
    # SDK should support Ruby 3.3+
    assert major >= 3, "Ruby major version should be 3 or higher"
    if major == 3
      assert minor >= 3, "Ruby 3.x version should be 3.3 or higher"
    end
    
    puts "Running on Ruby #{RUBY_VERSION}"
  end

  def test_gemspec_ruby_version_requirement
    gemspec_path = File.expand_path('../Telstra_Messaging.gemspec', __dir__)
    gemspec_content = File.read(gemspec_path)
    
    assert_match(/required_ruby_version.*>=.*3\.3/, gemspec_content,
                 'Gemspec should require Ruby 3.3 or higher')
  end

  def test_string_encoding_compatibility
    # Test that the SDK handles string encodings properly
    sms_request = Telstra_Messaging::SendSMSRequest.new
    
    # Test UTF-8 strings (default in Ruby 3.x)
    utf8_message = "Hello 世界! 🌟".force_encoding('UTF-8')
    sms_request.body = utf8_message
    
    hash_data = sms_request.to_hash
    assert_equal utf8_message, hash_data[:body]
    assert_equal Encoding::UTF_8, hash_data[:body].encoding
  end

  def test_frozen_string_literal_compatibility
    # Test that the SDK works with frozen string literals
    original_string = 'Test message'
    frozen_string = original_string.dup.freeze
    
    sms_request = Telstra_Messaging::SendSMSRequest.new
    
    begin
      sms_request.body = frozen_string
      hash_data = sms_request.to_hash
      assert_equal frozen_string, hash_data[:body]
    rescue => e
      flunk "Should handle frozen strings, but raised: #{e.message}"
    end
  end

  def test_frozen_string_literals_in_core_files
    core_files = [
      'lib/Telstra_Messaging.rb',
      'lib/Telstra_Messaging/api_client.rb',
      'lib/Telstra_Messaging/configuration.rb',
      'lib/Telstra_Messaging/http_client_utilities.rb'
    ]
    
    core_files.each do |file_path|
      full_path = File.expand_path("../#{file_path}", __dir__)
      if File.exist?(full_path)
        content = File.read(full_path)
        assert_match(/# frozen_string_literal: true/, content,
                     "#{file_path} should have frozen string literal pragma")
      end
    end
  end

  def test_hash_syntax_compatibility
    # Test that modern hash syntax works
    sms_request = Telstra_Messaging::SendSMSRequest.new
    sms_request.to = '+61412345678'
    sms_request.body = 'Test message'
    
    hash_data = sms_request.to_hash
    
    # Hash should be compatible with symbol access
    assert_instance_of Hash, hash_data
    assert hash_data.has_key?(:to) || hash_data.has_key?('to'), "Hash should have 'to' key"
    assert hash_data.has_key?(:body) || hash_data.has_key?('body'), "Hash should have 'body' key"
  end

  def test_numeric_precision_compatibility
    # Test numeric handling across Ruby versions
    oauth_response = Telstra_Messaging::OAuthResponse.new
    
    # Test various numeric types
    oauth_response.expires_in = 3600
    assert_equal 3600, oauth_response.expires_in
    
    oauth_response.expires_in = 3600.0
    assert_equal 3600.0, oauth_response.expires_in
    
    oauth_response.expires_in = 3_600
    assert_equal 3600, oauth_response.expires_in
  end

  def test_modern_dependencies
    gemspec_path = File.expand_path('../Telstra_Messaging.gemspec', __dir__)
    gemspec_content = File.read(gemspec_path)
    
    assert_match(/minitest/, gemspec_content,
                 'Should use Minitest as test framework')
    refute_match(/rspec/, gemspec_content,
                 'Should not use RSpec dependencies')
  end

  def test_exception_handling_compatibility
    # Test that exception handling works consistently
    assert_raises(Telstra_Messaging::ApiError) do
      raise Telstra_Messaging::ApiError.new("Test error")
    end
    
    # Test that custom errors inherit properly
    error = Telstra_Messaging::ApiError.new("Test")
    assert error.is_a?(StandardError)
    assert error.is_a?(Telstra_Messaging::ApiError)
    
    # Test exception message handling
    message = "Error with unicode: 测试 🚀"
    error = Telstra_Messaging::ApiError.new(message)
    assert_equal message, error.message
  end

  def test_require_patterns_work
    # Test that all required files can be loaded
    begin
      require 'Telstra_Messaging'
    rescue => e
      flunk "Should be able to require main module, but raised: #{e.message}"
    end
    
    # Test that we can access all expected classes
    expected_classes = [
      'Telstra_Messaging::Configuration',
      'Telstra_Messaging::ApiClient',
      'Telstra_Messaging::ApiError',
      'Telstra_Messaging::SendSMSRequest',
      'Telstra_Messaging::SendMmsRequest',
      'Telstra_Messaging::AuthenticationApi',
      'Telstra_Messaging::MessagingApi',
      'Telstra_Messaging::ProvisioningApi'
    ]
    
    expected_classes.each do |class_name|
      assert Object.const_defined?(class_name), "#{class_name} should be available"
      klass = Object.const_get(class_name)
      begin
        if class_name.include?('Api')
          klass.new # API classes can be instantiated with default params
        else
          klass.new # Other classes too
        end
      rescue => e
        flunk "Should be able to instantiate #{class_name}, but raised: #{e.message}"
      end
    end
  end

  def test_api_client_modernization
    # Test that ApiClient includes HttpClientUtilities
    api_client_path = File.expand_path('../lib/Telstra_Messaging/api_client.rb', __dir__)
    content = File.read(api_client_path)
    
    assert_match(/include HttpClientUtilities/, content,
                 'ApiClient should include HttpClientUtilities module')
    
    # Test that basic functionality works
    api_client = Telstra_Messaging::ApiClient.new
    assert_respond_to api_client, :json_mime?
    assert_respond_to api_client, :select_header_accept
    assert_respond_to api_client, :select_header_content_type
  end

  def test_modern_gemspec_patterns
    gemspec_path = File.expand_path('../Telstra_Messaging.gemspec', __dir__)
    gemspec_content = File.read(gemspec_path)
    
    assert_match(/__dir__/, gemspec_content,
                 'Gemspec should use __dir__ instead of __FILE__')
  end
end
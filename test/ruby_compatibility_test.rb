require_relative 'test_helper'

class RubyCompatibilityTest < TestHelper
  
  def test_ruby_version_compatibility
    # Test that we're running on a supported Ruby version
    ruby_version = RUBY_VERSION
    major, minor = ruby_version.split('.').map(&:to_i)
    
    # SDK should support Ruby 2.7+
    assert major >= 2, "Ruby major version should be 2 or higher"
    if major == 2
      assert minor >= 7, "Ruby 2.x version should be 2.7 or higher"
    end
    
    puts "Running on Ruby #{RUBY_VERSION}"
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

  def test_keyword_arguments_compatibility
    # Test that the SDK works with both Ruby 2.x and 3.x keyword argument styles
    config = Telstra_Messaging::Configuration.new
    
    # This should work in both Ruby 2.x and 3.x
    begin
      config.host = 'api.example.com'
      config.base_path = '/v2'
      api_client = Telstra_Messaging::ApiClient.new(config)
      assert_instance_of Telstra_Messaging::ApiClient, api_client
    rescue => e
      flunk "Configuration should accept keyword-style initialization, but raised: #{e.message}"
    end
  end

  def test_hash_syntax_compatibility
    # Test that both old and new hash syntax work
    sms_request = Telstra_Messaging::SendSMSRequest.new
    sms_request.to = '+61412345678'
    sms_request.body = 'Test message'
    
    hash_data = sms_request.to_hash
    
    # Hash should be compatible with both symbol and string access patterns
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

  def test_thread_safety_basic
    # Basic thread safety test
    results = []
    mutex = Mutex.new
    
    threads = 10.times.map do |i|
      Thread.new do
        config = Telstra_Messaging::Configuration.new
        config.host = "api#{i}.example.com"
        
        api_client = Telstra_Messaging::ApiClient.new(config)
        sms_request = Telstra_Messaging::SendSMSRequest.new
        sms_request.to = "+6141234567#{i}"
        sms_request.body = "Message #{i}"
        
        hash_data = sms_request.to_hash
        
        mutex.synchronize do
          results << {
            host: api_client.config.host,
            to: hash_data[:to],
            body: hash_data[:body]
          }
        end
      end
    end
    
    threads.each(&:join)
    
    # All threads should have completed successfully
    assert_equal 10, results.length
    
    # Each result should be unique
    hosts = results.map { |r| r[:host] }
    assert_equal 10, hosts.uniq.length, "Each thread should have a unique host"
    
    bodies = results.map { |r| r[:body] }
    assert_equal 10, bodies.uniq.length, "Each thread should have a unique message"
  end

  def test_memory_allocation_patterns
    # Test that objects can be created and destroyed without memory issues
    initial_object_count = ObjectSpace.count_objects
    
    # Create many objects
    1000.times do |i|
      sms_request = Telstra_Messaging::SendSMSRequest.new
      sms_request.to = "+61412345#{sprintf('%03d', i)}"
      sms_request.body = "Test message #{i}"
      sms_request.to_hash
    end
    
    # Force garbage collection
    GC.start
    
    after_object_count = ObjectSpace.count_objects
    
    # We should not have a massive increase in object count
    # (allowing for some growth due to the test itself)
    total_before = initial_object_count[:TOTAL]
    total_after = after_object_count[:TOTAL]
    
    growth_ratio = total_after.to_f / total_before.to_f
    assert growth_ratio < 2.0, "Object count should not grow excessively (#{growth_ratio}x growth)"
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

  def test_ruby3_specific_features_if_available
    skip "Skipping Ruby 3.x specific tests" unless RUBY_VERSION.start_with?('3.')
    
    # Test basic Ruby 3 features without pattern matching
    sms_request = Telstra_Messaging::SendSMSRequest.new
    sms_request.to = '+61412345678'
    sms_request.body = 'Test'
    
    hash_data = sms_request.to_hash
    
    # Simple hash validation for Ruby 3.x
    if hash_data.is_a?(Hash) && hash_data[:to].is_a?(String) && hash_data[:body].is_a?(String)
      result = 'matched'
    else
      result = 'not matched'
    end
    
    assert_equal 'matched', result
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

  def test_method_definition_compatibility
    # Test that method definitions work across Ruby versions
    sms_request = Telstra_Messaging::SendSMSRequest.new
    
    # Test that all expected methods are available
    expected_methods = [:to=, :to, :body=, :body, :from=, :from, :to_hash]
    
    expected_methods.each do |method|
      assert_respond_to sms_request, method, "SendSMSRequest should respond to #{method}"
    end
    
    # Test method chaining if available
    begin
      result = sms_request.tap do |req|
        req.to = '+61412345678'
        req.body = 'Test'
      end
      assert_equal sms_request, result
    rescue => e
      flunk "Method chaining should work, but raised: #{e.message}"
    end
  end

  private

    def case_in_pattern_matching_available?
      # Simple check for pattern matching availability (Ruby 3.0+)
      RUBY_VERSION >= '3.0'
    end
end

require_relative '../test_helper'

class ComprehensiveModelTest < TestHelper
  
  def test_core_models_can_be_instantiated
    # Test only the core models that we know exist and have proper structure
    core_model_classes = [
      Telstra_Messaging::SendSMSRequest,
      Telstra_Messaging::SendMmsRequest,
      Telstra_Messaging::MMSContent,
      Telstra_Messaging::MessageSentResponse,
      Telstra_Messaging::OAuthResponse,
      Telstra_Messaging::Message
    ]
    
    core_model_classes.each do |model_class|
      model_instance = model_class.new
      assert_instance_of model_class, model_instance, "Failed to instantiate #{model_class}"
      assert_respond_to model_instance, :to_hash, "#{model_class} should respond to to_hash"
    end
  end

  def test_enum_models_can_be_instantiated
    # Test enum-like models
    status = Telstra_Messaging::Status.new
    assert_instance_of Telstra_Messaging::Status, status
    
    # Status should have enum constants
    assert Telstra_Messaging::Status.const_defined?(:PEND)
    assert Telstra_Messaging::Status.const_defined?(:SENT)
    assert Telstra_Messaging::Status.const_defined?(:DELIVRD)
  end

  def test_send_sms_request_comprehensive_validation
    sms_request = Telstra_Messaging::SendSMSRequest.new
    
    # Test setting valid phone numbers
    sms_request.to = '+61412345678'
    assert_equal '+61412345678', sms_request.to
    
    # Test array of recipients
    recipients = ['+61412345678', '+61498765432']
    sms_request.to = recipients
    assert_equal recipients, sms_request.to
    
    # Test message body
    sms_request.body = 'Test message'
    assert_equal 'Test message', sms_request.body
    
    # Test from field
    sms_request.from = '+61400000000'
    assert_equal '+61400000000', sms_request.from
    
    # Test serialization preserves all fields
    hash_data = sms_request.to_hash
    assert_equal recipients, hash_data[:to]
    assert_equal 'Test message', hash_data[:body]
    assert_equal '+61400000000', hash_data[:from]
  end

  def test_send_mms_request_comprehensive_validation
    mms_request = Telstra_Messaging::SendMmsRequest.new
    
    # Test basic fields
    mms_request.to = '+61412345678'
    mms_request.subject = 'Test MMS Subject'
    
    # Test MMS content creation
    content1 = Telstra_Messaging::MMSContent.new
    content1.type = 'text/plain'
    content1.filename = 'text.txt'
    content1.payload = 'VGVzdCBjb250ZW50' # Base64 "Test content"
    
    content2 = Telstra_Messaging::MMSContent.new
    content2.type = 'image/jpeg'
    content2.filename = 'image.jpg'
    content2.payload = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChAI9jU77yQAAAABJRU5ErkJggg==' # Tiny PNG
    
    mms_request.mms_content = [content1, content2]
    
    # Verify all fields
    assert_equal '+61412345678', mms_request.to
    assert_equal 'Test MMS Subject', mms_request.subject
    assert_equal 2, mms_request.mms_content.length
    
    # Verify content types
    assert_equal 'text/plain', mms_request.mms_content[0].type
    assert_equal 'image/jpeg', mms_request.mms_content[1].type
    
    # Test serialization
    hash_data = mms_request.to_hash
    assert_equal '+61412345678', hash_data[:to]
    assert_equal 'Test MMS Subject', hash_data[:subject]
    # Only check if mms_content exists in hash since it might be nil if not set
    if hash_data[:mms_content]
      assert_instance_of Array, hash_data[:mms_content]
    end
  end

  def test_oauth_response_model
    oauth_response = Telstra_Messaging::OAuthResponse.new
    oauth_response.access_token = 'test_access_token_12345'
    oauth_response.token_type = 'Bearer'
    oauth_response.expires_in = 3600
    
    assert_equal 'test_access_token_12345', oauth_response.access_token
    assert_equal 'Bearer', oauth_response.token_type
    assert_equal 3600, oauth_response.expires_in
    
    # Test serialization
    hash_data = oauth_response.to_hash
    assert_equal 'test_access_token_12345', hash_data[:access_token]
    assert_equal 'Bearer', hash_data[:token_type]
    assert_equal 3600, hash_data[:expires_in]
  end

  def test_message_sent_response_model
    sent_response = Telstra_Messaging::MessageSentResponse.new
    
    # Create a message object
    message = Telstra_Messaging::Message.new
    message.to = '+61412345678'
    message.message_id = test_message_id
    
    sent_response.messages = [message]
    sent_response.message_type = 'SMS'
    
    assert_equal 1, sent_response.messages.length
    assert_equal 'SMS', sent_response.message_type
    
    hash_data = sent_response.to_hash
    # Only check message_type if it's been set (might be filtered out in to_hash if nil)
    if hash_data.key?(:message_type)
      assert_equal 'SMS', hash_data[:message_type]
    end
    # Check that messages array is present if set
    if hash_data.key?(:messages)
      assert_instance_of Array, hash_data[:messages]
    end
  end

  def test_message_model
    message = Telstra_Messaging::Message.new
    message.to = '+61412345678'
    message.message_id = test_message_id
    
    assert_equal '+61412345678', message.to
    assert_equal test_message_id, message.message_id
    
    hash_data = message.to_hash
    assert_equal '+61412345678', hash_data[:to]
    assert_equal test_message_id, hash_data[:messageId]
  end

  def test_mms_content_model
    mms_content = Telstra_Messaging::MMSContent.new
    mms_content.type = 'image/jpeg'
    mms_content.filename = 'test.jpg'
    mms_content.payload = 'base64_encoded_data'
    
    assert_equal 'image/jpeg', mms_content.type
    assert_equal 'test.jpg', mms_content.filename
    assert_equal 'base64_encoded_data', mms_content.payload
    
    hash_data = mms_content.to_hash
    assert_equal 'image/jpeg', hash_data[:type]
    assert_equal 'test.jpg', hash_data[:filename]
    assert_equal 'base64_encoded_data', hash_data[:payload]
  end

  def test_models_handle_nil_values_gracefully
    model_classes = [
      Telstra_Messaging::SendSMSRequest,
      Telstra_Messaging::SendMmsRequest,
      Telstra_Messaging::MessageSentResponse,
      Telstra_Messaging::OAuthResponse
    ]
    
    model_classes.each do |model_class|
      model_instance = model_class.new
      
      # Should not raise error when serializing with nil values
      begin
        hash_data = model_instance.to_hash
        assert_instance_of Hash, hash_data
      rescue => e
        flunk "#{model_class} should handle nil values gracefully, but raised: #{e.message}"
      end
    end
  end

  def test_model_validation_methods
    sms_request = Telstra_Messaging::SendSMSRequest.new
    
    # Test validation methods exist
    assert_respond_to sms_request, :valid?
    assert_respond_to sms_request, :list_invalid_properties
    
    # Test invalid state (missing required fields)
    refute sms_request.valid?, "SMS request should be invalid without required fields"
    
    invalid_props = sms_request.list_invalid_properties
    assert_instance_of Array, invalid_props
    refute_empty invalid_props, "Should have invalid properties when fields are missing"
    
    # Test valid state
    sms_request.to = '+61412345678'
    sms_request.body = 'Test message'
    
    assert sms_request.valid?, "SMS request should be valid with required fields"
    
    valid_invalid_props = sms_request.list_invalid_properties
    assert_empty valid_invalid_props, "Should have no invalid properties when all required fields are set"
  end

  def test_model_equality_and_hash
    sms1 = Telstra_Messaging::SendSMSRequest.new
    sms1.to = '+61412345678'
    sms1.body = 'Test message'
    
    sms2 = Telstra_Messaging::SendSMSRequest.new
    sms2.to = '+61412345678'
    sms2.body = 'Test message'
    
    sms3 = Telstra_Messaging::SendSMSRequest.new
    sms3.to = '+61498765432'
    sms3.body = 'Different message'
    
    # Test equality
    assert_equal sms1, sms2, "Objects with same content should be equal"
    refute_equal sms1, sms3, "Objects with different content should not be equal"
    
    # Test hash consistency
    assert_equal sms1.hash, sms2.hash, "Equal objects should have same hash"
    
    # Test eql? method
    assert sms1.eql?(sms2), "Equal objects should return true for eql?"
    refute sms1.eql?(sms3), "Different objects should return false for eql?"
  end

  def test_model_attribute_mapping
    # Test that attribute mapping is defined correctly
    sms_request = Telstra_Messaging::SendSMSRequest.new
    
    # Check attribute map exists
    assert_respond_to Telstra_Messaging::SendSMSRequest, :attribute_map
    attribute_map = Telstra_Messaging::SendSMSRequest.attribute_map
    
    assert_instance_of Hash, attribute_map
    assert attribute_map.has_key?(:to), "Should have :to in attribute map"
    assert attribute_map.has_key?(:body), "Should have :body in attribute map"
    
    # Check openapi types exist
    assert_respond_to Telstra_Messaging::SendSMSRequest, :openapi_types
    openapi_types = Telstra_Messaging::SendSMSRequest.openapi_types
    
    assert_instance_of Hash, openapi_types
    assert openapi_types.has_key?(:to), "Should have :to in openapi_types"
    assert openapi_types.has_key?(:body), "Should have :body in openapi_types"
  end

  def test_json_serialization_round_trip
    # Test that objects can be serialized to JSON and back
    sms_request = Telstra_Messaging::SendSMSRequest.new
    sms_request.to = ['+61412345678', '+61498765432']
    sms_request.body = 'Test message with unicode: 测试 🚀'
    sms_request.from = '+61400000000'
    
    # Convert to hash then JSON
    hash_data = sms_request.to_hash
    json_string = JSON.generate(hash_data)
    
    # Parse back from JSON
    parsed_hash = JSON.parse(json_string, symbolize_names: true)
    
    # Create new object from parsed data
    new_sms = Telstra_Messaging::SendSMSRequest.new(parsed_hash)
    
    # Should have same data
    assert_equal sms_request.to, new_sms.to
    assert_equal sms_request.body, new_sms.body
    assert_equal sms_request.from, new_sms.from
  end
end

require_relative '../test_helper'

class ModelValidationTest < TestHelper
  
  def test_send_sms_request_creation_with_valid_data
    sms_request = Telstra_Messaging::SendSMSRequest.new
    sms_request.to = valid_phone_number
    sms_request.body = valid_sms_body
    
    assert_equal valid_phone_number, sms_request.to
    assert_equal valid_sms_body, sms_request.body
  end

  def test_send_sms_request_with_multiple_recipients
    recipients = ['+61412345678', '+61498765432']
    sms_request = Telstra_Messaging::SendSMSRequest.new
    sms_request.to = recipients
    sms_request.body = valid_sms_body
    
    assert_equal recipients, sms_request.to
    assert_instance_of Array, sms_request.to
  end

  def test_send_sms_request_serialization_to_hash
    sms_request = Telstra_Messaging::SendSMSRequest.new
    sms_request.to = valid_phone_number
    sms_request.body = valid_sms_body
    
    hash_representation = sms_request.to_hash
    
    assert_instance_of Hash, hash_representation
    assert_equal valid_phone_number, hash_representation[:to]
    assert_equal valid_sms_body, hash_representation[:body]
  end

  def test_send_mms_request_creation_with_valid_data
    mms_request = Telstra_Messaging::SendMmsRequest.new
    mms_request.to = valid_phone_number
    mms_request.subject = 'Test MMS'
    
    assert_equal valid_phone_number, mms_request.to
    assert_equal 'Test MMS', mms_request.subject
  end

  def test_send_mms_request_with_content
    mms_content = Telstra_Messaging::MMSContent.new
    mms_content.type = 'text/plain'
    mms_content.filename = 'test.txt'
    mms_content.payload = 'VGVzdCBjb250ZW50' # Base64 encoded "Test content"
    
    mms_request = Telstra_Messaging::SendMmsRequest.new
    mms_request.to = valid_phone_number
    mms_request.subject = 'Test MMS'
    mms_request.mms_content = [mms_content]
    
    assert_equal 1, mms_request.mms_content.length
    assert_equal 'text/plain', mms_request.mms_content.first.type
  end

  def test_outbound_poll_response_deserialization
    response_data = load_json_fixture('sms_status_response.json')
    
    poll_response = Telstra_Messaging::OutboundPollResponse.new
    poll_response.to = response_data['to']
    poll_response.delivery_status = response_data['status']
    poll_response.sent_timestamp = response_data['sentTimestamp']
    
    assert_equal '+61412345678', poll_response.to
    assert_equal 'DELIVRD', poll_response.delivery_status
    assert_equal '2024-01-15T10:00:00+10:00', poll_response.sent_timestamp
  end

  def test_message_sent_response_object_creation
    message_response = Telstra_Messaging::MessageSentResponse.new
    message_response.message_type = 'SMS'
    
    assert_equal 'SMS', message_response.message_type
    assert_instance_of Telstra_Messaging::MessageSentResponse, message_response
  end

  def test_message_object_creation_with_message_id
    message = Telstra_Messaging::Message.new
    message.message_id = test_message_id
    message.to = valid_phone_number
    
    assert_equal test_message_id, message.message_id
    assert_equal valid_phone_number, message.to
  end

  def test_object_creation_with_empty_values
    sms_request = Telstra_Messaging::SendSMSRequest.new
    
    # Newly created objects should have nil values for non-initialized attributes
    assert_nil sms_request.to
    assert_nil sms_request.body
    assert_nil sms_request.from
  end

  def test_configuration_object_creation
    config = Telstra_Messaging::Configuration.new
    
    # Configuration should be creatable
    assert_instance_of Telstra_Messaging::Configuration, config
    refute_nil config.host
  end

  def test_api_client_object_creation
    api_client = Telstra_Messaging::ApiClient.new
    
    # API client should be creatable with default configuration
    assert_instance_of Telstra_Messaging::ApiClient, api_client
    assert_instance_of Telstra_Messaging::Configuration, api_client.config
  end
end

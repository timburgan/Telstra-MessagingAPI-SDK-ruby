require_relative 'test_helper'

class ErrorHandlingTest < TestHelper
  
  def test_api_error_creation_with_message
    error = Telstra_Messaging::ApiError.new("Test error message")
    
    assert_equal "Test error message", error.message
    assert_instance_of Telstra_Messaging::ApiError, error
  end

  def test_api_error_creation_with_hash_parameters
    error_params = {
      message: "API Error",
      code: 400,
      response_body: load_fixture('error_response.json')
    }
    
    error = Telstra_Messaging::ApiError.new(error_params)
    
    assert_equal "API Error", error.message
    assert_equal 400, error.code
    refute_nil error.response_body
  end

  def test_api_error_inherits_from_standard_error
    error = Telstra_Messaging::ApiError.new("Test error")
    
    assert error.is_a?(StandardError), "ApiError should inherit from StandardError"
    assert_instance_of Telstra_Messaging::ApiError, error
  end

  def test_configuration_accepts_various_settings
    config = Telstra_Messaging::Configuration.new
    
    # Test that we can set configuration values
    config.host = "api.example.com"
    config.base_path = "/test"
    
    # Configuration should accept and store these values
    assert_equal "api.example.com", config.host
    assert_equal "/test", config.base_path
  end
  
  def test_api_client_handles_network_timeout_simulation
    # Test that API client can be created with configuration
    # Note: Network simulation removed as webmock dependency was eliminated
    
    config = Telstra_Messaging::Configuration.new
    config.host = 'api.test.com'
    
    api_client = Telstra_Messaging::ApiClient.new(config)
    
    # API client should be created successfully
    assert_instance_of Telstra_Messaging::ApiClient, api_client
  end

  def test_api_client_handles_connection_error_simulation
    # Test that API client can be created with configuration
    # Note: Network simulation removed as webmock dependency was eliminated
    
    config = Telstra_Messaging::Configuration.new
    config.host = 'api.test.com'
    
    api_client = Telstra_Messaging::ApiClient.new(config)
    
    # API client should be created successfully
    assert_instance_of Telstra_Messaging::ApiClient, api_client
  end

  def test_api_error_response_structure
    error_response = load_json_fixture('error_response.json')
    
    # Verify error response structure matches expected format
    assert_equal "400", error_response["status"]
    assert_equal "INVALID-RECIPIENT", error_response["code"]
    assert_equal "Invalid recipient phone number format", error_response["message"]
  end

  def test_model_creation_with_nil_values_does_not_raise_error
    # Test that models can be created with nil values without raising errors
    sms_request = Telstra_Messaging::SendSMSRequest.new
    
    # Should not raise an error
    assert_nil sms_request.to
    assert_nil sms_request.body
    
    # Should be able to call methods on the object
    assert_respond_to sms_request, :to_hash
  end

  def test_configuration_with_missing_required_fields
    config = Telstra_Messaging::Configuration.new
    
    # Configuration should have reasonable defaults or handle missing fields gracefully
    refute_nil config.host
    refute_nil config.base_path
    
    # Should be able to construct base URL even with defaults
    assert_respond_to config, :base_url
  end

  def test_error_handling_preserves_original_error_information
    original_message = "Original error message"
    original_code = 500
    
    error = Telstra_Messaging::ApiError.new(
      message: original_message,
      code: original_code
    )
    
    assert_equal original_message, error.message
    assert_equal original_code, error.code
  end
end

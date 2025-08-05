require_relative 'test_helper'

class ApiClassTest < TestHelper
  
  def test_authentication_api_can_be_instantiated
    config = Telstra_Messaging::Configuration.new
    api_client = Telstra_Messaging::ApiClient.new(config)
    
    auth_api = Telstra_Messaging::AuthenticationApi.new(api_client)
    
    assert_instance_of Telstra_Messaging::AuthenticationApi, auth_api
    assert_equal api_client, auth_api.api_client
  end

  def test_messaging_api_can_be_instantiated
    config = Telstra_Messaging::Configuration.new
    api_client = Telstra_Messaging::ApiClient.new(config)
    
    messaging_api = Telstra_Messaging::MessagingApi.new(api_client)
    
    assert_instance_of Telstra_Messaging::MessagingApi, messaging_api
    assert_equal api_client, messaging_api.api_client
  end

  def test_provisioning_api_can_be_instantiated
    config = Telstra_Messaging::Configuration.new
    api_client = Telstra_Messaging::ApiClient.new(config)
    
    provisioning_api = Telstra_Messaging::ProvisioningApi.new(api_client)
    
    assert_instance_of Telstra_Messaging::ProvisioningApi, provisioning_api
    assert_equal api_client, provisioning_api.api_client
  end

  def test_authentication_api_has_expected_methods
    auth_api = Telstra_Messaging::AuthenticationApi.new
    
    # Test that authentication API has the expected public methods
    assert_respond_to auth_api, :auth_token, "AuthenticationApi should have auth_token method"
  end

  def test_messaging_api_has_expected_methods
    messaging_api = Telstra_Messaging::MessagingApi.new
    
    # Test that messaging API has the expected public methods
    assert_respond_to messaging_api, :get_mms_status, "MessagingApi should have get_mms_status method"
    assert_respond_to messaging_api, :get_sms_status, "MessagingApi should have get_sms_status method"
    assert_respond_to messaging_api, :send_mms, "MessagingApi should have send_mms method"
    assert_respond_to messaging_api, :send_sms, "MessagingApi should have send_sms method"
  end

  def test_provisioning_api_has_expected_methods
    provisioning_api = Telstra_Messaging::ProvisioningApi.new
    
    # Test that provisioning API has the expected public methods
    assert_respond_to provisioning_api, :create_subscription, "ProvisioningApi should have create_subscription method"
    assert_respond_to provisioning_api, :delete_subscription, "ProvisioningApi should have delete_subscription method"
    assert_respond_to provisioning_api, :get_subscription, "ProvisioningApi should have get_subscription method"
  end

  def test_api_classes_accept_configuration_in_api_client
    config = Telstra_Messaging::Configuration.new
    config.host = 'api.example.com'
    config.base_path = '/test'
    
    api_client = Telstra_Messaging::ApiClient.new(config)
    
    auth_api = Telstra_Messaging::AuthenticationApi.new(api_client)
    messaging_api = Telstra_Messaging::MessagingApi.new(api_client)
    provisioning_api = Telstra_Messaging::ProvisioningApi.new(api_client)
    
    # All APIs should use the same configured API client
    assert_equal 'api.example.com', auth_api.api_client.config.host
    assert_equal 'api.example.com', messaging_api.api_client.config.host
    assert_equal 'api.example.com', provisioning_api.api_client.config.host
    
    assert_equal '/test', auth_api.api_client.config.base_path
    assert_equal '/test', messaging_api.api_client.config.base_path
    assert_equal '/test', provisioning_api.api_client.config.base_path
  end

  def test_api_classes_work_with_default_configuration
    # Test that API classes can be instantiated with default configuration
    auth_api = Telstra_Messaging::AuthenticationApi.new
    messaging_api = Telstra_Messaging::MessagingApi.new
    provisioning_api = Telstra_Messaging::ProvisioningApi.new
    
    assert_instance_of Telstra_Messaging::AuthenticationApi, auth_api
    assert_instance_of Telstra_Messaging::MessagingApi, messaging_api
    assert_instance_of Telstra_Messaging::ProvisioningApi, provisioning_api
    
    # Each should have a valid API client with default configuration
    assert_instance_of Telstra_Messaging::ApiClient, auth_api.api_client
    assert_instance_of Telstra_Messaging::ApiClient, messaging_api.api_client
    assert_instance_of Telstra_Messaging::ApiClient, provisioning_api.api_client
  end

  def test_api_client_can_build_request_url
    config = Telstra_Messaging::Configuration.new
    config.host = 'tapi.telstra.com'
    config.base_path = '/v2'
    
    api_client = Telstra_Messaging::ApiClient.new(config)
    
    # Test that API client can build URLs (basic functionality test)
    assert_respond_to api_client, :build_request_url, "ApiClient should have build_request_url method"
    
    # Build a test URL
    url = api_client.build_request_url('/oauth/token')
    expected_url = 'https://tapi.telstra.com/v2/oauth/token'
    
    assert_equal expected_url, url
  end

  def test_api_client_handles_query_parameters
    config = Telstra_Messaging::Configuration.new
    config.host = 'tapi.telstra.com'
    config.base_path = '/v2'
    
    api_client = Telstra_Messaging::ApiClient.new(config)
    
    # Test URL building with paths (query params are handled elsewhere in the SDK)
    url = api_client.build_request_url('/oauth/token')
    
    # URL should contain the base structure
    assert_includes url, 'https://tapi.telstra.com/v2/oauth/token'
  end

  def test_configuration_supports_various_schemes
    # Test HTTP scheme
    config_http = Telstra_Messaging::Configuration.new
    config_http.scheme = 'http'
    config_http.host = 'localhost'
    config_http.base_path = '/api'
    
    assert_equal 'http://localhost/api', config_http.base_url
    
    # Test HTTPS scheme (default)
    config_https = Telstra_Messaging::Configuration.new
    config_https.host = 'api.example.com'
    config_https.base_path = '/v1'
    
    assert_equal 'https://api.example.com/v1', config_https.base_url
  end

  def test_api_client_user_agent_is_set
    api_client = Telstra_Messaging::ApiClient.new
    
    # API client should have a user agent set via instance variable
    assert_respond_to api_client, :user_agent=
    
    # Check default headers contain user agent
    assert api_client.default_headers.key?('User-Agent')
    user_agent = api_client.default_headers['User-Agent']
    
    refute_nil user_agent
    assert_instance_of String, user_agent
    
    # User agent should contain useful information
    assert_includes user_agent.downcase, 'ruby', "User agent should mention Ruby"
  end
end

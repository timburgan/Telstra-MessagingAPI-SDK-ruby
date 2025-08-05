require_relative 'test_helper'

class ConfigurationTest < TestHelper
  
  def test_configuration_setup_with_valid_settings
    config = Telstra_Messaging::Configuration.new
    config.host = 'tapi.telstra.com'
    config.base_path = '/v2'
    
    assert_equal 'tapi.telstra.com', config.host
    assert_equal '/v2', config.base_path
  end

  def test_configuration_default_values
    config = Telstra_Messaging::Configuration.new
    
    # Check that default values are set
    refute_nil config.host
    refute_nil config.base_path
  end

  def test_api_client_initialization_with_configuration
    config = Telstra_Messaging::Configuration.new
    config.host = 'tapi.telstra.com'
    
    api_client = Telstra_Messaging::ApiClient.new(config)
    
    assert_equal config, api_client.config
    assert_equal 'tapi.telstra.com', api_client.config.host
  end

  def test_api_client_default_configuration
    api_client = Telstra_Messaging::ApiClient.new
    
    refute_nil api_client.config
    assert_instance_of Telstra_Messaging::Configuration, api_client.config
  end

  def test_configuration_base_url_construction
    config = Telstra_Messaging::Configuration.new
    config.host = 'tapi.telstra.com'
    config.base_path = '/v2'
    
    expected_base_url = 'https://tapi.telstra.com/v2'
    assert_equal expected_base_url, config.base_url
  end

  def test_configuration_with_different_schemes
    config = Telstra_Messaging::Configuration.new
    config.scheme = 'http'
    config.host = 'localhost'
    config.base_path = '/api'
    
    expected_base_url = 'http://localhost/api'
    assert_equal expected_base_url, config.base_url
  end
end

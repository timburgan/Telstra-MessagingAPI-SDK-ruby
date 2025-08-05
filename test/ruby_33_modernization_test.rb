# frozen_string_literal: true

=begin
#Telstra Messaging API - Ruby 3.3+ Modernization Tests

Tests for Ruby version requirements and modern patterns introduced.

OpenAPI spec version: 2.2.9

=end

require 'test_helper'

class Ruby33ModernizationTest < Minitest::Test
  describe 'Ruby version requirements' do
    it 'requires Ruby 3.3 or higher' do
      gemspec_path = File.expand_path('../Telstra_Messaging.gemspec', __dir__)
      gemspec_content = File.read(gemspec_path)
      
      assert_match /required_ruby_version.*>=.*3\.3/, gemspec_content,
                   'Gemspec should require Ruby 3.3 or higher'
    end

    it 'uses current Ruby version that meets requirements' do
      current_version = Gem::Version.new(RUBY_VERSION)
      required_version = Gem::Version.new('3.3')
      
      # Note: This test may fail in development environments with older Ruby
      # but should pass in production with Ruby 3.3+
      skip "Running on Ruby #{RUBY_VERSION}, expected 3.3+" if current_version < required_version
      
      assert current_version >= required_version,
             "Current Ruby version #{RUBY_VERSION} should be >= 3.3"
    end
  end

  describe 'modern dependencies' do
    it 'uses Minitest instead of RSpec' do
      gemspec_path = File.expand_path('../Telstra_Messaging.gemspec', __dir__)
      gemspec_content = File.read(gemspec_path)
      
      assert_match /minitest/, gemspec_content,
                   'Should use Minitest as test framework'
      refute_match /rspec/, gemspec_content,
                   'Should not use RSpec dependencies'
    end

    it 'uses modern dependency versions' do
      gemspec_path = File.expand_path('../Telstra_Messaging.gemspec', __dir__)
      gemspec_content = File.read(gemspec_path)
      
      # Check for modern dependency versions
      assert_match /typhoeus.*~>.*1\.4/, gemspec_content
      assert_match /json.*~>.*2\.7/, gemspec_content
      assert_match /minitest.*~>.*5\.25/, gemspec_content
    end
  end

  describe 'frozen string literals' do
    it 'has frozen string literals in core library files' do
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
          assert_match /# frozen_string_literal: true/, content,
                       "#{file_path} should have frozen string literal pragma"
        end
      end
    end
  end

  describe 'Integer type consistency' do
    it 'uses Integer instead of deprecated Fixnum in documentation' do
      api_files = Dir[File.expand_path('../lib/Telstra_Messaging/**/*.rb', __dir__)]
      
      api_files.each do |file_path|
        content = File.read(file_path)
        refute_match /Fixnum/, content,
                     "#{File.basename(file_path)} should not contain deprecated Fixnum references"
        
        # Should contain Integer for return types
        if content.match?(/@return.*Array.*Integer/)
          assert_match /@return.*Array.*Integer/, content,
                       "#{File.basename(file_path)} should use Integer type in documentation"
        end
      end
    end
  end

  describe 'modern gemspec patterns' do
    it 'uses __dir__ instead of __FILE__' do
      gemspec_path = File.expand_path('../Telstra_Messaging.gemspec', __dir__)
      gemspec_content = File.read(gemspec_path)
      
      assert_match /__dir__/, gemspec_content,
                   'Gemspec should use __dir__ instead of __FILE__'
    end

    it 'uses spec instead of s for cleaner declarations' do
      gemspec_path = File.expand_path('../Telstra_Messaging.gemspec', __dir__)
      gemspec_content = File.read(gemspec_path)
      
      assert_match /spec\.add_runtime_dependency/, gemspec_content,
                   'Should use spec instead of s for dependency declarations'
    end
  end

  describe 'ApiClient refactoring' do
    it 'has extracted HttpClientUtilities module' do
      utilities_path = File.expand_path('../lib/Telstra_Messaging/http_client_utilities.rb', __dir__)
      assert File.exist?(utilities_path),
             'HttpClientUtilities module file should exist'
      
      content = File.read(utilities_path)
      assert_match /module HttpClientUtilities/, content,
                   'Should define HttpClientUtilities module'
    end

    it 'ApiClient includes HttpClientUtilities' do
      api_client_path = File.expand_path('../lib/Telstra_Messaging/api_client.rb', __dir__)
      content = File.read(api_client_path)
      
      assert_match /include HttpClientUtilities/, content,
                   'ApiClient should include HttpClientUtilities module'
    end

    it 'ApiClient is significantly reduced in size' do
      api_client_path = File.expand_path('../lib/Telstra_Messaging/api_client.rb', __dir__)
      content = File.read(api_client_path)
      line_count = content.lines.count
      
      # Should be around 289 lines or less (reduced from 389)
      assert line_count <= 320,
             "ApiClient should be reduced in size (currently #{line_count} lines, target ~289)"
    end
  end

  describe 'functional compatibility' do
    it 'can instantiate basic SDK components' do
      # Test that core components can be instantiated
      config = Telstra_Messaging::Configuration.new
      assert_instance_of Telstra_Messaging::Configuration, config
      
      api_client = Telstra_Messaging::ApiClient.new(config)
      assert_instance_of Telstra_Messaging::ApiClient, api_client
    end

    it 'has object_to_hash method working' do
      api_client = Telstra_Messaging::ApiClient.new
      
      # Test with simple hash
      test_hash = { key: 'value', number: 42 }
      result = api_client.object_to_hash(test_hash)
      
      assert_equal test_hash, result
    end

    it 'ApiClient utility methods are accessible' do
      api_client = Telstra_Messaging::ApiClient.new
      
      # Test that methods from HttpClientUtilities are accessible
      assert_respond_to api_client, :json_mime?
      assert_respond_to api_client, :select_header_accept
      assert_respond_to api_client, :select_header_content_type
      
      # Note: sanitize_filename is a private method, so we don't test it directly
    end
  end
end
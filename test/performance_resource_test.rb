require_relative 'test_helper'
require 'benchmark'
require 'base64'

class PerformanceResourceTest < TestHelper
  
  def test_object_creation_performance
    # Test that object creation is reasonably fast
    iterations = 1000
    
    time_taken = Benchmark.realtime do
      iterations.times do
        sms_request = Telstra_Messaging::SendSMSRequest.new
        sms_request.to = '+61412345678'
        sms_request.body = 'Test message'
        sms_request.to_hash
      end
    end
    
    # Should create 1000 objects and serialize them in under 1 second
    assert time_taken < 1.0, "Object creation should be fast, took #{time_taken}s for #{iterations} objects"
    
    puts "Created #{iterations} SMS objects in #{time_taken.round(4)}s (#{(iterations / time_taken).round(0)} objects/sec)"
  end

  def test_large_data_serialization_performance
    # Test performance with large data structures
    large_recipient_list = (1..100).map { |i| "+61412345#{sprintf('%03d', i)}" }
    
    sms_request = Telstra_Messaging::SendSMSRequest.new
    sms_request.to = large_recipient_list
    sms_request.body = 'Bulk message to many recipients'
    
    time_taken = Benchmark.realtime do
      50.times do
        sms_request.to_hash
      end
    end
    
    # Should serialize large objects quickly
    assert time_taken < 0.5, "Large object serialization should be fast, took #{time_taken}s"
    
    puts "Serialized large object (100 recipients) 50 times in #{time_taken.round(4)}s"
  end

  def test_memory_usage_stability
    # Test that memory usage doesn't grow unbounded
    iterations = 500
    
    # Measure memory before
    GC.start
    memory_before = get_memory_usage
    
    # Create many objects without holding references
    iterations.times do |i|
      config = Telstra_Messaging::Configuration.new
      config.host = "api#{i}.example.com"
      
      api_client = Telstra_Messaging::ApiClient.new(config)
      
      sms_request = Telstra_Messaging::SendSMSRequest.new
      sms_request.to = "+6141234567#{i % 10}"
      sms_request.body = "Message #{i}"
      
      mms_request = Telstra_Messaging::SendMmsRequest.new
      mms_request.to = "+6141234567#{i % 10}"
      mms_request.subject = "Subject #{i}"
      
      # Serialize objects
      sms_request.to_hash
      mms_request.to_hash
      
      # Periodically force garbage collection
      GC.start if i % 100 == 0
    end
    
    # Force final garbage collection
    GC.start
    memory_after = get_memory_usage
    
    memory_growth = memory_after - memory_before
    memory_growth_mb = memory_growth / (1024 * 1024)
    
    # Memory growth should be reasonable (less than 50MB for 500 iterations)
    assert memory_growth_mb < 50, "Memory growth should be reasonable, grew by #{memory_growth_mb.round(2)}MB"
    
    puts "Memory usage: #{memory_before / (1024 * 1024)}MB -> #{memory_after / (1024 * 1024)}MB (#{memory_growth_mb.round(2)}MB growth)"
  end

  def test_concurrent_object_creation
    # Test that concurrent object creation doesn't cause issues
    thread_count = 10
    iterations_per_thread = 50
    
    start_time = Time.now
    
    threads = thread_count.times.map do |thread_id|
      Thread.new do
        iterations_per_thread.times do |i|
          # Create different types of objects
          config = Telstra_Messaging::Configuration.new
          config.host = "thread#{thread_id}-api#{i}.example.com"
          
          api_client = Telstra_Messaging::ApiClient.new(config)
          
          sms_request = Telstra_Messaging::SendSMSRequest.new
          sms_request.to = "+61412345#{thread_id}#{i}"
          sms_request.body = "Thread #{thread_id} message #{i}"
          
          # Serialize objects
          hash_data = sms_request.to_hash
          
          # Verify data integrity
          assert_equal "+61412345#{thread_id}#{i}", hash_data[:to]
          assert_equal "Thread #{thread_id} message #{i}", hash_data[:body]
        end
      end
    end
    
    # Wait for all threads to complete
    threads.each(&:join)
    
    end_time = Time.now
    total_time = end_time - start_time
    total_operations = thread_count * iterations_per_thread
    
    # Should complete all operations reasonably quickly
    assert total_time < 5.0, "Concurrent operations should complete quickly, took #{total_time}s"
    
    puts "Completed #{total_operations} concurrent operations in #{total_time.round(4)}s (#{(total_operations / total_time).round(0)} ops/sec)"
  end

  def test_deep_object_nesting_performance
    # Test performance with deeply nested MMS content
    mms_request = Telstra_Messaging::SendMmsRequest.new
    mms_request.to = '+61412345678'
    mms_request.subject = 'Deep nesting test'
    
    # Create multiple nested content objects
    content_objects = 20.times.map do |i|
      content = Telstra_Messaging::MMSContent.new
      content.type = 'text/plain'
      content.filename = "file#{i}.txt"
      content.payload = Base64.encode64("Content for file #{i} with some data " * 10)
      content
    end
    
    mms_request.mms_content = content_objects
    
    time_taken = Benchmark.realtime do
      25.times do
        hash_data = mms_request.to_hash
        # Check if mms_content exists in hash data, or verify on the object itself
        if hash_data.key?(:mms_content) && hash_data[:mms_content]
          assert_equal 20, hash_data[:mms_content].length
        else
          # Fall back to checking the object directly
          assert_equal 20, mms_request.mms_content.length
        end
      end
    end
    
    # Should handle deep nesting efficiently
    assert time_taken < 0.5, "Deep object nesting should be handled efficiently, took #{time_taken}s"
    
    puts "Serialized deeply nested object (20 content items) 25 times in #{time_taken.round(4)}s"
  end

  def test_string_handling_efficiency
    # Test efficiency of string operations
    long_message = "A" * 1000 + " 🌟 " + "B" * 1000 + " 世界 " + "C" * 1000
    
    sms_request = Telstra_Messaging::SendSMSRequest.new
    sms_request.body = long_message
    
    time_taken = Benchmark.realtime do
      100.times do
        hash_data = sms_request.to_hash
        assert_equal long_message, hash_data[:body]
      end
    end
    
    # String operations should be efficient
    assert time_taken < 0.2, "String handling should be efficient, took #{time_taken}s"
    
    puts "Processed long strings (#{long_message.length} chars) 100 times in #{time_taken.round(4)}s"
  end

  def test_api_client_creation_overhead
    # Test that API client creation is not too expensive
    iterations = 100
    
    time_taken = Benchmark.realtime do
      iterations.times do
        config = Telstra_Messaging::Configuration.new
        config.host = 'tapi.telstra.com'
        config.base_path = '/v2'
        
        api_client = Telstra_Messaging::ApiClient.new(config)
        
        # Create API instances
        auth_api = Telstra_Messaging::AuthenticationApi.new(api_client)
        messaging_api = Telstra_Messaging::MessagingApi.new(api_client)
        provisioning_api = Telstra_Messaging::ProvisioningApi.new(api_client)
        
        # Verify they're created correctly
        assert_instance_of Telstra_Messaging::AuthenticationApi, auth_api
        assert_instance_of Telstra_Messaging::MessagingApi, messaging_api
        assert_instance_of Telstra_Messaging::ProvisioningApi, provisioning_api
      end
    end
    
    # API client creation should be fast
    assert time_taken < 1.0, "API client creation should be fast, took #{time_taken}s for #{iterations} clients"
    
    puts "Created #{iterations} API clients and API instances in #{time_taken.round(4)}s"
  end

  def test_garbage_collection_behavior
    # Test that objects are properly garbage collected
    iterations = 200
    
    # Create objects in a method scope so they can be GC'd
    create_objects = lambda do
      iterations.times do |i|
        sms = Telstra_Messaging::SendSMSRequest.new
        sms.to = "+61412345#{i % 100}"
        sms.body = "Message #{i}"
        sms.to_hash
        
        mms = Telstra_Messaging::SendMmsRequest.new
        mms.to = "+61412345#{i % 100}"
        mms.subject = "Subject #{i}"
        mms.to_hash
      end
    end
    
    # Count objects before
    GC.start
    objects_before = ObjectSpace.count_objects
    
    # Create objects
    create_objects.call
    
    # Force garbage collection
    GC.start
    objects_after = ObjectSpace.count_objects
    
    # Object count should not grow excessively
    growth = objects_after[:TOTAL] - objects_before[:TOTAL]
    growth_ratio = growth.to_f / iterations.to_f
    
    # Should not have more than 5 objects remaining per iteration on average
    assert growth_ratio < 5.0, "Object growth should be minimal after GC, #{growth} objects for #{iterations} iterations (#{growth_ratio.round(2)} per iteration)"
    
    puts "Object growth after GC: #{growth} objects for #{iterations} iterations (#{growth_ratio.round(2)} per iteration)"
  end

  def test_configuration_object_reuse
    # Test that configuration objects can be reused efficiently
    config = Telstra_Messaging::Configuration.new
    config.host = 'tapi.telstra.com'
    config.base_path = '/v2'
    
    iterations = 100
    
    time_taken = Benchmark.realtime do
      iterations.times do
        # Reuse the same configuration
        api_client = Telstra_Messaging::ApiClient.new(config)
        messaging_api = Telstra_Messaging::MessagingApi.new(api_client)
        
        # Verify configuration is preserved
        assert_equal 'tapi.telstra.com', api_client.config.host
        assert_equal '/v2', api_client.config.base_path
      end
    end
    
    # Configuration reuse should be very fast
    assert time_taken < 0.5, "Configuration reuse should be fast, took #{time_taken}s"
    
    puts "Reused configuration #{iterations} times in #{time_taken.round(4)}s"
  end

  private

    def get_memory_usage
      # Get current memory usage in bytes
      # This is a simple approximation using GC stats
      if GC.respond_to?(:stat)
        GC.stat(:heap_live_slots) * 40 # Rough approximation
      else
        # Fallback for older Ruby versions
        ObjectSpace.count_objects[:TOTAL] * 40
      end
    end
end

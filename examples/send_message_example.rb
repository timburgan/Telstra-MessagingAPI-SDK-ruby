#!/usr/bin/env ruby

# Message Sending Example for Telstra Messaging API Ruby SDK
#
# This example demonstrates how to send SMS and MMS messages
# with proper error handling and retry logic.
#
# Usage: ruby send_message_example.rb

require 'Telstra_Messaging'
require 'base64'
require 'logger'

class TelstraMessagingService
  MAX_RETRIES = 3
  RETRY_DELAY = 1.0

  def initialize
    @logger = Logger.new(STDOUT)
    setup_authentication
    
    @messaging_api = Telstra_Messaging::MessagingApi.new
    @auth_api = Telstra_Messaging::AuthenticationApi.new
  end

  # Send a basic SMS message
  def send_sms(to:, body:, options: {})
    @logger.info "Sending SMS to #{to}: #{body[0..50]}#{'...' if body.length > 50}"
    
    sms_request = Telstra_Messaging::SendSMSRequest.new({
      to: to,
      body: body,
      from: options[:from],
      validity: options[:validity],
      scheduled_delivery: options[:scheduled_delivery] || 0,
      notify_url: options[:notify_url],
      reply_request: options[:reply_request] || false,
      priority: options[:priority] || false
    }.compact)

    send_with_retry { @messaging_api.send_sms(sms_request) }
  end

  # Send an MMS message with content
  def send_mms(to:, subject:, content:, options: {})
    @logger.info "Sending MMS to #{to}: #{subject}"
    
    mms_request = Telstra_Messaging::SendMmsRequest.new({
      to: to,
      subject: subject,
      from: options[:from],
      reply_request: options[:reply_request] || false,
      notify_url: options[:notify_url],
      mms_content: content
    }.compact)

    send_with_retry { @messaging_api.send_mms(mms_request) }
  end

  # Send SMS to multiple recipients (broadcast)
  def send_broadcast_sms(recipients:, body:, options: {})
    @logger.info "Sending broadcast SMS to #{recipients.size} recipients"
    
    sms_request = Telstra_Messaging::SendSMSRequest.new({
      to: recipients,
      body: body,
      from: options[:from],
      notify_url: options[:notify_url],
      reply_request: options[:reply_request] || false
    }.compact)

    send_with_retry { @messaging_api.send_sms(sms_request) }
  end

  # Check message delivery status
  def get_sms_status(message_id)
    @logger.info "Checking SMS status for: #{message_id}"
    @messaging_api.get_sms_status(message_id)
  rescue Telstra_Messaging::ApiError => e
    @logger.error "Error checking SMS status: #{e.message}"
    raise e
  end

  def get_mms_status(message_id)
    @logger.info "Checking MMS status for: #{message_id}"
    @messaging_api.get_mms_status(message_id)
  rescue Telstra_Messaging::ApiError => e
    @logger.error "Error checking MMS status: #{e.message}"
    raise e
  end

  # Helper method to create text content for MMS
  def create_text_content(text, filename = 'message.txt')
    Telstra_Messaging::MMSContent.new(
      type: 'text/plain',
      filename: filename,
      payload: Base64.encode64(text)
    )
  end

  # Helper method to create image content for MMS
  def create_image_content(image_path, filename = nil)
    filename ||= File.basename(image_path)
    image_data = File.read(image_path)
    content_type = get_content_type(image_path)
    
    Telstra_Messaging::MMSContent.new(
      type: content_type,
      filename: filename,
      payload: Base64.encode64(image_data)
    )
  end

  # Helper method to create video content for MMS
  def create_video_content(video_path, filename = nil)
    filename ||= File.basename(video_path)
    video_data = File.read(video_path)
    content_type = get_content_type(video_path)
    
    Telstra_Messaging::MMSContent.new(
      type: content_type,
      filename: filename,
      payload: Base64.encode64(video_data)
    )
  end

  private

    def setup_authentication
      client_id = ENV['TELSTRA_CLIENT_ID']
      client_secret = ENV['TELSTRA_CLIENT_SECRET']
      
      unless client_id && client_secret
        raise "Please set TELSTRA_CLIENT_ID and TELSTRA_CLIENT_SECRET environment variables"
      end

      @logger.info "Authenticating with Telstra API..."
      
      # Get access token
      result = @auth_api.auth_token(client_id, client_secret, 'client_credentials')
      access_token = result.access_token
      
      # Configure the SDK
      Telstra_Messaging.configure do |config|
        config.access_token = access_token
      end
      
      @logger.info "Authentication successful"
    end

    def send_with_retry(retries = 0, &block)
      block.call
    rescue Telstra_Messaging::ApiError => e
      if retries < MAX_RETRIES && retryable_error?(e)
        @logger.warn "API error (attempt #{retries + 1}/#{MAX_RETRIES}): #{e.message}"
        sleep(RETRY_DELAY * (2**retries)) # Exponential backoff
        send_with_retry(retries + 1, &block)
      else
        handle_api_error(e)
        raise e
      end
    end

    def retryable_error?(error)
      # Retry on server errors and rate limits
      [429, 500, 502, 503, 504].include?(error.code)
    end

    def handle_api_error(error)
      case error.code
      when 400
        # Parse error details
        begin
          error_body = JSON.parse(error.response_body)
          @logger.error "Validation error: #{error_body['message']}"
          @logger.error "Error code: #{error_body['code']}"
        rescue JSON::ParserError
          @logger.error "Bad request: #{error.message}"
        end
      when 401
        @logger.error "Authentication failed: #{error.message}"
      when 403
        @logger.error "Access forbidden: #{error.message}"
      when 429
        @logger.error "Rate limit exceeded: #{error.message}"
      else
        @logger.error "API error #{error.code}: #{error.message}"
      end
    end

    def get_content_type(file_path)
      case File.extname(file_path).downcase
      when '.jpg', '.jpeg'
        'image/jpeg'
      when '.png'
        'image/png'
      when '.gif'
        'image/gif'
      when '.bmp'
        'image/bmp'
      when '.mp4'
        'video/mp4'
      when '.3gp'
        'video/3gp'
      when '.wav'
        'audio/wav'
      when '.mp3'
        'audio/mp3'
      when '.amr'
        'audio/amr'
      else
        'application/octet-stream'
      end
    end
end

# Example usage and testing
if __FILE__ == $0
  puts "=== Telstra Messaging API Examples ==="
  
  begin
    service = TelstraMessagingService.new
    
    # Example 1: Send basic SMS
    puts "\n1. Sending basic SMS..."
    recipient = ENV['TEST_PHONE_NUMBER'] || '+61412345678'
    
    sms_result = service.send_sms(
      to: recipient,
      body: "Hello from Telstra API! This is a test message sent at #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    )
    
    puts "SMS sent successfully!"
    puts "Message ID: #{sms_result.message_id}"
    puts "Status: #{sms_result.status}"
    
    # Example 2: Send SMS with all options
    puts "\n2. Sending SMS with options..."
    sms_result = service.send_sms(
      to: recipient,
      body: "This is a test SMS with delivery tracking and 1-hour expiry.",
      options: {
        validity: 60, # Expire after 1 hour
        notify_url: "https://yourapp.com/webhooks/delivery",
        priority: true,
        reply_request: false
      }
    )
    puts "Advanced SMS sent! Message ID: #{sms_result.message_id}"
    
    # Example 3: Send broadcast SMS
    puts "\n3. Sending broadcast SMS..."
    recipients = [recipient] # Add more numbers for real broadcast
    broadcast_result = service.send_broadcast_sms(
      recipients: recipients,
      body: "This is a broadcast message sent to multiple recipients.",
      options: {
        notify_url: "https://yourapp.com/webhooks/delivery"
      }
    )
    puts "Broadcast SMS sent! Message ID: #{broadcast_result.message_id}"
    
    # Example 4: Send MMS with text content
    puts "\n4. Sending text MMS..."
    text_content = service.create_text_content(
      "This is a text MMS message with some content to demonstrate the MMS functionality."
    )
    
    mms_result = service.send_mms(
      to: recipient,
      subject: "Test MMS",
      content: [text_content],
      options: {
        notify_url: "https://yourapp.com/webhooks/delivery"
      }
    )
    puts "Text MMS sent! Message ID: #{mms_result.message_id}"
    
    # Example 5: Send MMS with image (if test image exists)
    test_image_path = 'test_image.jpg'
    if File.exist?(test_image_path)
      puts "\n5. Sending image MMS..."
      
      text_content = service.create_text_content("Check out this image!")
      image_content = service.create_image_content(test_image_path)
      
      mms_result = service.send_mms(
        to: recipient,
        subject: "Image MMS Test",
        content: [text_content, image_content]
      )
      puts "Image MMS sent! Message ID: #{mms_result.message_id}"
    else
      puts "\n5. Skipping image MMS (no test_image.jpg found)"
    end
    
    # Example 6: Check message status
    puts "\n6. Checking message status..."
    sleep(2) # Wait a moment for processing
    
    begin
      status_result = service.get_sms_status(sms_result.message_id)
      puts "Message status check completed"
      status_result.each do |status|
        puts "  To: #{status.to}"
        puts "  Status: #{status.delivery_status}"
        puts "  Sent: #{status.sent_timestamp}"
        puts "  Received: #{status.received_timestamp}" if status.received_timestamp
      end
    rescue Telstra_Messaging::ApiError => e
      puts "Status check error: #{e.message} (this is normal for new messages)"
    end
    
    puts "\n=== All examples completed successfully! ==="
    
  rescue => e
    puts "Error running examples: #{e.message}"
    puts e.backtrace.join("\n") if ENV['DEBUG']
    exit 1
  end
end

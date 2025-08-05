#!/usr/bin/env ruby

# Comprehensive Examples for Telstra Messaging API Ruby SDK
#
# This file contains complete examples for:
# - Message sending (SMS and MMS)
# - Webhook handling (inbound messages and delivery status)
# - Error handling and retry logic
# - Authentication and configuration
#
# Usage:
#   ruby examples/comprehensive_example.rb send    # Run sending examples
#   ruby examples/comprehensive_example.rb webhook # Run webhook examples
#   ruby examples/comprehensive_example.rb         # Run all examples

require 'Telstra_Messaging'
require 'json'
require 'base64'
require 'logger'
require 'fileutils'

# === MESSAGE SENDING EXAMPLES ===

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
      @logger.error "Validation error: #{error.message}"
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
    when '.jpg', '.jpeg' then 'image/jpeg'
    when '.png' then 'image/png'
    when '.gif' then 'image/gif'
    when '.mp4' then 'video/mp4'
    when '.wav' then 'audio/wav'
    else 'application/octet-stream'
    end
  end
end

# === WEBHOOK HANDLING EXAMPLES ===

class TelstraWebhookHandler
  def initialize
    @logger = Logger.new(STDOUT)
    @processed_messages = Set.new # Simple in-memory storage for demo
  end

  # Main webhook handler - determines webhook type and routes accordingly
  def handle_webhook(request_body, headers)
    begin
      payload = JSON.parse(request_body)
      webhook_type = determine_webhook_type(payload, headers)
      
      @logger.info "Processing webhook: #{webhook_type}"
      
      case webhook_type
      when :inbound_sms
        handle_inbound_sms(payload)
      when :inbound_mms
        handle_inbound_mms(payload)
      when :delivery_status
        handle_delivery_status(payload)
      else
        @logger.warn "Unknown webhook type: #{payload.inspect}"
        return { status: 'unknown_type', code: 200 }
      end
      
      { status: 'received', code: 200 }
      
    rescue JSON::ParserError => e
      @logger.error "Invalid JSON in webhook: #{e.message}"
      { status: 'invalid_json', code: 400 }
    rescue => e
      @logger.error "Webhook processing error: #{e.message}"
      { status: 'error', code: 200 }
    end
  end

  private

  # Determine webhook type based on payload structure
  def determine_webhook_type(payload, headers)
    if payload.key?('deliveryStatus')
      :delivery_status
    elsif payload.key?('MMSContent')
      :inbound_mms  
    elsif payload.key?('body') && payload.key?('from')
      :inbound_sms
    else
      :unknown
    end
  end

  # Handle inbound SMS messages
  def handle_inbound_sms(payload)
    # Check for duplicate processing (idempotency)
    message_id = payload['messageId']
    if @processed_messages.include?(message_id)
      @logger.info "Duplicate SMS webhook ignored: #{message_id}"
      return
    end
    @processed_messages.add(message_id)

    # Extract message details
    from = payload['from']
    to = payload['to']
    body = payload['body']
    sent_at = Time.parse(payload['sentTimestamp'])

    @logger.info "Received SMS from #{from} to #{to}: #{body}"

    # Example: Auto-reply logic
    if body.downcase.include?('help')
      auto_reply = "Thanks for your message! For support, visit our website."
      @logger.info "Would send auto-reply to #{from}: #{auto_reply}"
    end
  end

  # Handle inbound MMS messages
  def handle_inbound_mms(payload)
    from = payload['senderAddress']
    to = payload['destinationAddress'] 
    subject = payload['subject'] || ''
    
    @logger.info "Received MMS from #{from} to #{to}, subject: #{subject}"

    # Process MMS content
    content_items = payload['MMSContent'] || []
    content_items.each do |content|
      process_mms_content(content)
    end
  end

  # Handle delivery status notifications
  def handle_delivery_status(payload)
    message_id = payload['messageId']
    status = payload['deliveryStatus']
    
    @logger.info "Delivery status for #{message_id}: #{status}"
    
    case status
    when 'DELIVRD'
      @logger.info "Message delivered successfully"
    when 'EXPIRED'
      @logger.warn "Message expired before delivery"
    when 'UNDELIV'
      @logger.error "Message could not be delivered"
    when 'REJECTD'
      @logger.error "Message was rejected"
    end
  end

  # Process MMS content (decode base64, determine type)
  def process_mms_content(content)
    content_type = content['type']
    filename = content['filename']
    payload_data = content['payload']

    begin
      decoded_content = Base64.decode64(payload_data)
      
      case content_type
      when /^image\//
        @logger.info "Received image: #{filename} (#{decoded_content.size} bytes)"
      when /^video\//
        @logger.info "Received video: #{filename} (#{decoded_content.size} bytes)"
      when 'text/plain'
        text_content = decoded_content.force_encoding('UTF-8')
        @logger.info "Text content: #{text_content}"
      else
        @logger.info "Unknown content type: #{content_type}"
      end
      
    rescue => e
      @logger.error "Error processing MMS content: #{e.message}"
    end
  end
end

# === EXAMPLE RUNNER ===

def run_sending_examples
  puts "=== Telstra Messaging API - Sending Examples ==="
  
  begin
    service = TelstraMessagingService.new
    recipient = ENV['TEST_PHONE_NUMBER'] || '+61412345678'
    
    # Example 1: Send basic SMS
    puts "\n1. Sending basic SMS..."
    sms_result = service.send_sms(
      to: recipient,
      body: "Hello from Telstra API! This is a test message sent at #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    )
    puts "SMS sent successfully! Message ID: #{sms_result.message_id}"
    
    # Example 2: Send MMS with text content
    puts "\n2. Sending text MMS..."
    text_content = service.create_text_content(
      "This is a text MMS message demonstrating the MMS functionality."
    )
    
    mms_result = service.send_mms(
      to: recipient,
      subject: "Test MMS",
      content: [text_content]
    )
    puts "Text MMS sent! Message ID: #{mms_result.message_id}"
    
    # Example 3: Send broadcast SMS
    puts "\n3. Sending broadcast SMS..."
    recipients = [recipient] # Add more numbers for real broadcast
    broadcast_result = service.send_broadcast_sms(
      recipients: recipients,
      body: "This is a broadcast message sent to multiple recipients."
    )
    puts "Broadcast SMS sent! Message ID: #{broadcast_result.message_id}"
    
    puts "\n=== Sending examples completed successfully! ==="
    
  rescue => e
    puts "Error running sending examples: #{e.message}"
    exit 1
  end
end

def run_webhook_examples
  puts "=== Telstra Messaging API - Webhook Examples ==="
  
  handler = TelstraWebhookHandler.new

  # Example inbound SMS payload
  sms_payload = {
    "to" => "+61400000000",
    "from" => "+61412345678",
    "body" => "Hello! I need help with my account",
    "sentTimestamp" => Time.now.iso8601,
    "messageId" => "SMS_#{SecureRandom.hex(8)}"
  }.to_json

  puts "\n1. Testing Inbound SMS Webhook..."
  result = handler.handle_webhook(sms_payload, {})
  puts "Result: #{result}"

  # Example inbound MMS payload
  mms_payload = {
    "status" => "RECEIVED",
    "destinationAddress" => "+61400000000",
    "senderAddress" => "+61412345678", 
    "subject" => "Check out this photo!",
    "sentTimestamp" => Time.now.iso8601,
    "MMSContent" => [
      {
        "type" => "text/plain",
        "filename" => "message.txt",
        "payload" => Base64.encode64("Here's the photo I mentioned!")
      },
      {
        "type" => "image/jpeg",
        "filename" => "photo.jpg", 
        "payload" => Base64.encode64("fake_image_data_for_testing")
      }
    ]
  }.to_json

  puts "\n2. Testing Inbound MMS Webhook..."
  result = handler.handle_webhook(mms_payload, {})
  puts "Result: #{result}"

  # Example delivery status payload
  delivery_payload = {
    "to" => "+61412345678",
    "sentTimestamp" => (Time.now - 300).iso8601,
    "receivedTimestamp" => (Time.now - 295).iso8601,
    "messageId" => "MSG_#{SecureRandom.hex(8)}",
    "deliveryStatus" => "DELIVRD"
  }.to_json

  puts "\n3. Testing Delivery Status Webhook..."
  result = handler.handle_webhook(delivery_payload, {})
  puts "Result: #{result}"

  puts "\n=== Webhook examples completed successfully! ==="
end

# === MAIN EXECUTION ===

if __FILE__ == $0
  case ARGV[0]
  when 'send'
    run_sending_examples
  when 'webhook'
    run_webhook_examples
  else
    puts "Running all examples...\n"
    run_webhook_examples
    puts "\n" + "="*50 + "\n"
    run_sending_examples if ENV['TELSTRA_CLIENT_ID'] && ENV['TELSTRA_CLIENT_SECRET']
  end
end
#!/usr/bin/env ruby

# Webhook Example for Telstra Messaging API Ruby SDK
# 
# This example demonstrates how to handle inbound SMS/MMS webhooks
# and delivery status notifications in a Ruby application.
#
# Usage: ruby webhook_example.rb

require 'json'
require 'base64'
require 'logger'

# Sample webhook handler that can be integrated into Rails or Sinatra
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
      @logger.error e.backtrace.join("\n")
      # Return 200 to prevent retries for processing errors
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
      # Check for required fields
      required_fields = %w[to from body sentTimestamp messageId]
      missing_fields = required_fields.select { |field| payload[field].nil? || payload[field].empty? }
      
      if missing_fields.any?
        @logger.error "Missing required fields: #{missing_fields.join(', ')}"
        return
      end

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

      # Process the message (add your business logic here)
      process_inbound_sms(
        from: from,
        to: to,
        body: body,
        sent_at: sent_at,
        message_id: message_id
      )
    end

    # Handle inbound MMS messages
    def handle_inbound_mms(payload)
      # Check for required fields
      unless payload['destinationAddress'] && payload['senderAddress'] && payload['MMSContent']
        @logger.error "Missing required MMS fields"
        return
      end

      from = payload['senderAddress']
      to = payload['destinationAddress'] 
      subject = payload['subject'] || ''
      sent_at = Time.parse(payload['sentTimestamp']) if payload['sentTimestamp']
      
      @logger.info "Received MMS from #{from} to #{to}, subject: #{subject}"

      # Process MMS content
      content_items = payload['MMSContent'] || []
      processed_content = content_items.map { |content| process_mms_content(content) }

      process_inbound_mms(
        from: from,
        to: to,
        subject: subject,
        content: processed_content,
        sent_at: sent_at
      )
    end

    # Handle delivery status notifications
    def handle_delivery_status(payload)
      message_id = payload['messageId']
      status = payload['deliveryStatus']
      to = payload['to']
      
      @logger.info "Delivery status for #{message_id}: #{status}"
      
      # Update message status in your database
      update_message_status(message_id, status, payload)
    end

    # Process MMS content (decode base64, determine type, save files)
    def process_mms_content(content)
      content_type = content['type']
      filename = content['filename']
      payload_data = content['payload']

      begin
        decoded_content = Base64.decode64(payload_data)
        
        case content_type
        when /^image\//
          # Save image file
          file_path = save_media_file(decoded_content, filename, 'images')
          @logger.info "Saved image: #{file_path}"
          { type: 'image', filename: filename, path: file_path, size: decoded_content.size }
          
        when /^video\//
          # Save video file
          file_path = save_media_file(decoded_content, filename, 'videos')
          @logger.info "Saved video: #{file_path}"
          { type: 'video', filename: filename, path: file_path, size: decoded_content.size }
          
        when /^audio\//
          # Save audio file
          file_path = save_media_file(decoded_content, filename, 'audio')
          @logger.info "Saved audio: #{file_path}"
          { type: 'audio', filename: filename, path: file_path, size: decoded_content.size }
          
        when 'text/plain'
          # Process text content
          text_content = decoded_content.force_encoding('UTF-8')
          @logger.info "Text content: #{text_content}"
          { type: 'text', content: text_content }
          
        when 'text/x-vCard'
          # Process vCard contact
          vcard_content = decoded_content.force_encoding('UTF-8')
          @logger.info "Received vCard"
          { type: 'vcard', content: vcard_content }
          
        when 'text/x-vCalendar'
          # Process calendar event
          calendar_content = decoded_content.force_encoding('UTF-8')
          @logger.info "Received calendar event"
          { type: 'calendar', content: calendar_content }
          
        else
          # Handle unknown content types
          @logger.warn "Unknown content type: #{content_type}"
          { type: 'unknown', content_type: content_type, filename: filename }
        end
        
      rescue => e
        @logger.error "Error processing MMS content: #{e.message}"
        { type: 'error', error: e.message }
      end
    end

    # Save media file to disk (replace with your preferred storage)
    def save_media_file(content, filename, media_type)
      # Create directory if it doesn't exist
      dir_path = File.join('uploads', media_type)
      FileUtils.mkdir_p(dir_path) unless Dir.exist?(dir_path)
      
      # Generate unique filename to prevent conflicts
      timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
      extension = File.extname(filename)
      base_name = File.basename(filename, extension)
      unique_filename = "#{timestamp}_#{base_name}#{extension}"
      
      file_path = File.join(dir_path, unique_filename)
      
      # Write file
      File.open(file_path, 'wb') { |file| file.write(content) }
      
      file_path
    end

    # Your business logic for processing inbound SMS
    def process_inbound_sms(from:, to:, body:, sent_at:, message_id:)
      # Example: Auto-reply logic
      if body.downcase.include?('help')
        auto_reply = "Thanks for your message! For support, visit our website or call 1-800-HELP"
        # You would send this reply using the Telstra API here
        @logger.info "Would send auto-reply to #{from}: #{auto_reply}"
      end
      
      # Example: Store in database
      @logger.info "Storing SMS in database: #{message_id}"
      
      # Example: Trigger business workflows
      if body.downcase.include?('urgent')
        @logger.info "Triggering urgent notification workflow"
      end
    end

    # Your business logic for processing inbound MMS
    def process_inbound_mms(from:, to:, subject:, content:, sent_at:)
      @logger.info "Processing MMS with #{content.size} content items"
      
      # Example: Process images for content moderation
      content.each do |item|
        if item[:type] == 'image'
          @logger.info "Would process image for content moderation: #{item[:filename]}"
        end
      end
      
      # Example: Store MMS details
      @logger.info "Storing MMS in database"
    end

    # Update message delivery status
    def update_message_status(message_id, status, payload)
      case status
      when 'DELIVRD'
        @logger.info "Message #{message_id} delivered successfully"
      when 'EXPIRED'
        @logger.warn "Message #{message_id} expired before delivery"
      when 'UNDELIV'
        @logger.error "Message #{message_id} could not be delivered"
      when 'REJECTD'
        @logger.error "Message #{message_id} was rejected"
      else
        @logger.info "Message #{message_id} status: #{status}"
      end
      
      # Update your database here
      @logger.info "Would update database with status: #{status}"
    end
end

# Example usage (for testing)
if __FILE__ == $0
  require 'fileutils'
  
  handler = TelstraWebhookHandler.new

  # Example inbound SMS payload
  sms_payload = {
    "to" => "+61400000000",
    "from" => "+61412345678",
    "body" => "Hello! I need help with my account",
    "sentTimestamp" => Time.now.iso8601,
    "messageId" => "SMS_#{SecureRandom.hex(8)}"
  }.to_json

  puts "=== Testing Inbound SMS Webhook ==="
  result = handler.handle_webhook(sms_payload, {})
  puts "Result: #{result}"

  # Example inbound MMS payload
  mms_payload = {
    "status" => "RECEIVED",
    "destinationAddress" => "+61400000000",
    "senderAddress" => "+61412345678", 
    "subject" => "Check out this photo!",
    "sentTimestamp" => Time.now.iso8601,
    "envelope" => "test_envelope",
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

  puts "\n=== Testing Inbound MMS Webhook ==="
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

  puts "\n=== Testing Delivery Status Webhook ==="
  result = handler.handle_webhook(delivery_payload, {})
  puts "Result: #{result}"

  puts "\nWebhook testing completed!"
end

# Telstra Messaging API Ruby SDK - Developer Guide

This guide provides comprehensive documentation for developers integrating the Telstra Messaging API Ruby SDK into their applications, with a focus on practical implementation, webhook handling, and testing.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Webhook Payloads](#webhook-payloads)
3. [Sending Messages](#sending-messages)
4. [Testing and Mocking](#testing-and-mocking)
5. [Message Flow Sequence](#message-flow-sequence)
6. [Error Handling](#error-handling)
7. [Best Practices](#best-practices)

## Quick Start

### Installation

Add this line to your application's Gemfile:

```ruby
gem 'Telstra_Messaging', '~> 1.0.6'
```

### Basic Setup

```ruby
require 'Telstra_Messaging'

# Configure authentication
Telstra_Messaging.configure do |config|
  config.access_token = 'YOUR_ACCESS_TOKEN'
end

# Initialize API instances
auth_api = Telstra_Messaging::AuthenticationApi.new
messaging_api = Telstra_Messaging::MessagingApi.new
provisioning_api = Telstra_Messaging::ProvisioningApi.new
```

### Getting an Access Token

```ruby
# Get OAuth2 token
auth_api = Telstra_Messaging::AuthenticationApi.new
result = auth_api.auth_token(
  'your_client_id',
  'your_client_secret', 
  'client_credentials'
)
access_token = result.access_token
```

## Webhook Payloads

### Inbound SMS Webhook Payload

When someone sends an SMS to your provisioned number, Telstra will POST to your `notifyURL` with this payload:

#### Headers
```
Content-Type: application/json
User-Agent: Telstra-Messaging/1.0
X-Webhook-Event: inbound-sms
```

#### Payload Structure
```json
{
  "to": "+61472880123",
  "from": "+61412345678", 
  "body": "Hello, this is a test message",
  "sentTimestamp": "2018-04-20T14:24:35",
  "messageId": "DMASApiA0000000146"
}
```

#### Field Definitions

| Field | Type | Description | Required | Possible Values |
|-------|------|-------------|----------|-----------------|
| `to` | String | Your provisioned number that received the message (E.164 format) | Yes | "+61XXXXXXXXX" |
| `from` | String | Sender's phone number (E.164 format) | Yes | "+61XXXXXXXXX" or international |
| `body` | String | SMS content (UTF-8 encoded, supports emojis) | Yes | 1-1600 characters |
| `sentTimestamp` | String | When message was sent (ISO 8601) | Yes | "YYYY-MM-DDTHH:mm:ss" |
| `messageId` | String | Unique identifier for this message | Yes | Alphanumeric string |

#### Ruby Handler Example
```ruby
class WebhookController < ApplicationController
  def inbound_sms
    payload = JSON.parse(request.body.read)
    
    # Validate required fields
    required_fields = %w[to from body sentTimestamp messageId]
    missing_fields = required_fields.select { |field| payload[field].nil? }
    
    if missing_fields.any?
      render json: { error: "Missing fields: #{missing_fields.join(', ')}" }, status: 400
      return
    end
    
    # Process the message
    process_inbound_sms(
      to: payload['to'],
      from: payload['from'],
      body: payload['body'],
      sent_at: Time.parse(payload['sentTimestamp']),
      message_id: payload['messageId']
    )
    
    render json: { status: 'received' }, status: 200
  end
  
  private
  
  def process_inbound_sms(to:, from:, body:, sent_at:, message_id:)
    # Your application logic here
    Rails.logger.info "Received SMS from #{from}: #{body}"
    
    # Store in database, trigger workflows, etc.
    InboundMessage.create!(
      sender: from,
      recipient: to,
      content: body,
      received_at: sent_at,
      external_id: message_id
    )
  end
end
```

### Inbound MMS Webhook Payload

#### Headers
```
Content-Type: application/json
User-Agent: Telstra-Messaging/1.0
X-Webhook-Event: inbound-mms
```

#### Payload Structure
```json
{
  "status": "RECEIVED",
  "destinationAddress": "+61418123456",
  "senderAddress": "+61421987654",
  "subject": "Photo from vacation",
  "sentTimestamp": "2018-03-23T12:15:45+10:00",
  "envelope": "string",
  "MMSContent": [
    {
      "type": "text/plain",
      "filename": "text_1.txt",
      "payload": "SGVsbG8gV29ybGQ="
    },
    {
      "type": "image/jpeg", 
      "filename": "photo.jpg",
      "payload": "/9j/4AAQSkZJRgABAQEAYABgAAD..."
    }
  ]
}
```

#### Field Definitions

| Field | Type | Description | Required | Possible Values |
|-------|------|-------------|----------|-----------------|
| `status` | String | Message status | Yes | "RECEIVED", "FAILED" |
| `destinationAddress` | String | Your provisioned number (E.164) | Yes | "+61XXXXXXXXX" |
| `senderAddress` | String | Sender's number (E.164) | Yes | "+61XXXXXXXXX" or international |
| `subject` | String | MMS subject line | No | Up to 40 characters |
| `sentTimestamp` | String | Timestamp with timezone (ISO 8601) | Yes | "YYYY-MM-DDTHH:mm:ss±HH:MM" |
| `envelope` | String | Message envelope information | No | String |
| `MMSContent` | Array | Array of content objects | Yes | 1-10 content items |

#### MMS Content Object

| Field | Type | Description | Possible Values |
|-------|------|-------------|-----------------|
| `type` | String | MIME type | `audio/amr`, `audio/aac`, `audio/mp3`, `audio/mpeg3`, `audio/mpeg`, `audio/mpg`, `audio/wav`, `audio/3gpp`, `audio/mp4`, `image/gif`, `image/jpeg`, `image/jpg`, `image/png`, `image/bmp`, `video/mpeg4`, `video/mp4`, `video/mpeg`, `video/3gpp`, `video/3gp`, `video/h263`, `text/plain`, `text/x-vCard`, `text/x-vCalendar` |
| `filename` | String | Original filename | Any valid filename |
| `payload` | String | Base64-encoded content | Base64 string |

#### Ruby Handler Example
```ruby
class WebhookController < ApplicationController
  def inbound_mms
    payload = JSON.parse(request.body.read)
    
    # Process MMS content
    mms_content = payload['MMSContent'] || []
    processed_content = mms_content.map do |content|
      process_mms_content(content)
    end
    
    # Store message
    InboundMmsMessage.create!(
      sender: payload['senderAddress'],
      recipient: payload['destinationAddress'],
      subject: payload['subject'],
      content_items: processed_content,
      received_at: Time.parse(payload['sentTimestamp'])
    )
    
    render json: { status: 'received' }, status: 200
  end
  
  private
  
  def process_mms_content(content)
    decoded_content = Base64.decode64(content['payload'])
    
    case content['type']
    when /^image\//
      # Save image file
      save_media_file(decoded_content, content['filename'], 'image')
    when /^video\//
      # Save video file  
      save_media_file(decoded_content, content['filename'], 'video')
    when /^audio\//
      # Save audio file
      save_media_file(decoded_content, content['filename'], 'audio')
    when 'text/plain'
      # Process text content
      { type: 'text', content: decoded_content }
    else
      # Handle other content types
      { type: content['type'], filename: content['filename'] }
    end
  end
  
  def save_media_file(content, filename, media_type)
    # Save to your preferred storage (S3, local filesystem, etc.)
    file_path = "uploads/#{media_type}/#{SecureRandom.uuid}_#{filename}"
    File.write(Rails.root.join('public', file_path), content)
    { type: media_type, url: "/#{file_path}", filename: filename }
  end
end
```

### Delivery Status Webhook Payload

When you send a message with a `notifyURL`, delivery status updates are sent to that URL:

#### SMS Delivery Status
```json
{
  "to": "+61418123456",
  "sentTimestamp": "2017-03-17T10:05:22+10:00",
  "receivedTimestamp": "2017-03-17T10:05:23+10:00", 
  "messageId": "/cccb284200035236000000000ee9d074019e0301/1261418123456",
  "deliveryStatus": "DELIVRD"
}
```

#### MMS Delivery Status
```json
{
  "to": "+61418123456",
  "receivedTimestamp": "2017-03-17T10:05:23+10:00",
  "sentTimestamp": "2017-03-17T10:05:22+10:00",
  "deliveryStatus": "DELIVRD",
  "messageId": "/cccb284200035236000000000ee9d074019e0301/1261418123456"
}
```

#### Delivery Status Values

| Status | Description |
|--------|-------------|
| `DELIVRD` | Message delivered successfully |
| `EXPIRED` | Message expired before delivery |
| `DELETED` | Message was deleted |
| `UNDELIV` | Message undeliverable |
| `ACCEPTD` | Message accepted by network |
| `UNKNOWN` | Status unknown |
| `REJECTD` | Message rejected |

## Sending Messages

### Sending SMS

#### Basic SMS
```ruby
require 'Telstra_Messaging'

# Configure SDK
Telstra_Messaging.configure do |config|
  config.access_token = 'YOUR_ACCESS_TOKEN'
end

messaging_api = Telstra_Messaging::MessagingApi.new

# Create SMS request
sms_request = Telstra_Messaging::SendSMSRequest.new(
  to: "+61412345678",
  body: "Hello from Telstra API!"
)

begin
  result = messaging_api.send_sms(sms_request)
  puts "Message sent! ID: #{result.message_id}"
  puts "Status: #{result.status}"
rescue Telstra_Messaging::ApiError => e
  puts "Error sending SMS: #{e.message}"
  puts "Response body: #{e.response_body}"
end
```

#### Advanced SMS with All Options
```ruby
sms_request = Telstra_Messaging::SendSMSRequest.new(
  to: "+61412345678",
  body: "Your verification code is 123456. Valid for 10 minutes.",
  from: "+61400000000",  # Your provisioned number
  validity: 60,          # Expire after 60 minutes
  scheduled_delivery: 0, # Send immediately  
  notify_url: "https://yourapp.com/webhooks/delivery",
  reply_request: false,  # Set to true for reply tracking
  priority: false        # Set to true for high priority
)

result = messaging_api.send_sms(sms_request)
```

#### Broadcast SMS (Multiple Recipients)
```ruby
# Send to multiple numbers
sms_request = Telstra_Messaging::SendSMSRequest.new(
  to: ["+61412345678", "+61418765432", "+61400123456"],
  body: "Broadcast message to multiple recipients"
)

result = messaging_api.send_sms(sms_request)
# Returns array of message IDs, one for each recipient
```

#### Long SMS (Concatenated Messages)
```ruby
long_message = "This is a very long message that exceeds 160 characters. " \
               "The Telstra API will automatically split this into multiple " \
               "SMS messages and reassemble them on the recipient's device. " \
               "You can send up to 1900 characters for a single recipient."

sms_request = Telstra_Messaging::SendSMSRequest.new(
  to: "+61412345678",
  body: long_message
)

result = messaging_api.send_sms(sms_request)
```

#### SMS with Reply Tracking
```ruby
sms_request = Telstra_Messaging::SendSMSRequest.new(
  to: "+61412345678",
  body: "Please reply with your preference: A, B, or C",
  reply_request: true,  # Enables reply tracking
  notify_url: "https://yourapp.com/webhooks/inbound"
)

result = messaging_api.send_sms(sms_request)
# Replies will be sent to your notify_url with the same messageId
```

### Sending MMS

#### Text MMS
```ruby
# Create text content
text_content = Telstra_Messaging::MMSContent.new(
  type: "text/plain",
  filename: "message.txt", 
  payload: Base64.encode64("Hello from MMS!")
)

mms_request = Telstra_Messaging::SendMmsRequest.new(
  to: "+61412345678",
  subject: "Test MMS",
  mms_content: [text_content]
)

result = messaging_api.send_mms(mms_request)
```

#### Image MMS
```ruby
# Read and encode image
image_data = File.read("path/to/image.jpg")
encoded_image = Base64.encode64(image_data)

image_content = Telstra_Messaging::MMSContent.new(
  type: "image/jpeg",
  filename: "photo.jpg",
  payload: encoded_image
)

mms_request = Telstra_Messaging::SendMmsRequest.new(
  to: "+61412345678",
  subject: "Check out this photo!",
  mms_content: [image_content],
  notify_url: "https://yourapp.com/webhooks/delivery"
)

result = messaging_api.send_mms(mms_request)
```

#### Multi-Content MMS
```ruby
# Text content
text_content = Telstra_Messaging::MMSContent.new(
  type: "text/plain",
  filename: "message.txt",
  payload: Base64.encode64("Here are the files you requested:")
)

# Image content
image_data = File.read("report_chart.png")
image_content = Telstra_Messaging::MMSContent.new(
  type: "image/png", 
  filename: "chart.png",
  payload: Base64.encode64(image_data)
)

# PDF content (as application/octet-stream)
pdf_data = File.read("report.pdf")
pdf_content = Telstra_Messaging::MMSContent.new(
  type: "application/pdf",
  filename: "report.pdf", 
  payload: Base64.encode64(pdf_data)
)

mms_request = Telstra_Messaging::SendMmsRequest.new(
  to: "+61412345678",
  subject: "Monthly Report",
  mms_content: [text_content, image_content, pdf_content]
)

result = messaging_api.send_mms(mms_request)
```

### Message Status Checking

#### Check SMS Status
```ruby
message_id = "your_message_id_here"

begin
  status_result = messaging_api.get_sms_status(message_id)
  status_result.each do |status|
    puts "To: #{status.to}"
    puts "Status: #{status.delivery_status}"
    puts "Sent: #{status.sent_timestamp}"
    puts "Received: #{status.received_timestamp}" if status.received_timestamp
  end
rescue Telstra_Messaging::ApiError => e
  puts "Error getting status: #{e.message}"
end
```

#### Check MMS Status  
```ruby
message_id = "your_mms_message_id"

begin
  status_result = messaging_api.get_mms_status(message_id)
  status_result.each do |status|
    puts "To: #{status.to}"
    puts "Status: #{status.delivery_status}"
    puts "Sent: #{status.sent_timestamp}"
  end
rescue Telstra_Messaging::ApiError => e
  puts "Error getting MMS status: #{e.message}"
end
```

## Testing and Mocking

### RSpec Test Examples

#### Mock Webhook Payloads
```ruby
# spec/support/webhook_helpers.rb
module WebhookHelpers
  def inbound_sms_payload(overrides = {})
    {
      to: "+61400000000",
      from: "+61412345678", 
      body: "Test SMS message",
      sentTimestamp: "2023-01-15T10:30:00",
      messageId: "TEST_MSG_#{SecureRandom.hex(8)}"
    }.merge(overrides)
  end
  
  def inbound_mms_payload(overrides = {})
    {
      status: "RECEIVED",
      destinationAddress: "+61400000000",
      senderAddress: "+61412345678",
      subject: "Test MMS",
      sentTimestamp: "2023-01-15T10:30:00+10:00",
      envelope: "test_envelope",
      MMSContent: [
        {
          type: "text/plain",
          filename: "message.txt", 
          payload: Base64.encode64("Test MMS content")
        }
      ]
    }.merge(overrides)
  end
  
  def delivery_status_payload(overrides = {})
    {
      to: "+61412345678",
      sentTimestamp: "2023-01-15T10:30:00+10:00",
      receivedTimestamp: "2023-01-15T10:30:05+10:00",
      messageId: "TEST_MSG_#{SecureRandom.hex(8)}",
      deliveryStatus: "DELIVRD"
    }.merge(overrides)
  end
end
```

#### Controller Tests
```ruby
# spec/controllers/webhook_controller_spec.rb
require 'rails_helper'

RSpec.describe WebhookController, type: :controller do
  include WebhookHelpers
  
  describe "POST #inbound_sms" do
    it "processes valid SMS webhook" do
      payload = inbound_sms_payload(body: "Hello World")
      
      post :inbound_sms, body: payload.to_json, 
           headers: { 'CONTENT_TYPE' => 'application/json' }
      
      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body)['status']).to eq('received')
      
      # Verify message was stored
      message = InboundMessage.last
      expect(message.content).to eq("Hello World")
      expect(message.sender).to eq("+61412345678")
    end
    
    it "returns error for missing required fields" do
      payload = inbound_sms_payload.except(:body)
      
      post :inbound_sms, body: payload.to_json,
           headers: { 'CONTENT_TYPE' => 'application/json' }
      
      expect(response).to have_http_status(400)
      expect(JSON.parse(response.body)['error']).to include('Missing fields')
    end
  end
  
  describe "POST #inbound_mms" do
    it "processes MMS with image content" do
      image_payload = Base64.encode64("fake_image_data")
      payload = inbound_mms_payload(
        MMSContent: [
          {
            type: "image/jpeg",
            filename: "test.jpg",
            payload: image_payload
          }
        ]
      )
      
      post :inbound_mms, body: payload.to_json,
           headers: { 'CONTENT_TYPE' => 'application/json' }
      
      expect(response).to have_http_status(200)
      
      message = InboundMmsMessage.last
      expect(message.content_items.first['type']).to eq('image')
    end
  end
end
```

#### Service Tests with API Mocking
```ruby
# spec/services/sms_service_spec.rb
require 'rails_helper'

RSpec.describe SmsService do
  let(:messaging_api) { instance_double(Telstra_Messaging::MessagingApi) }
  let(:service) { described_class.new(messaging_api) }
  
  before do
    allow(Telstra_Messaging::MessagingApi).to receive(:new).and_return(messaging_api)
  end
  
  describe "#send_notification" do
    it "sends SMS successfully" do
      message_response = double(
        message_id: "MSG123",
        status: "sent"
      )
      
      expect(messaging_api).to receive(:send_sms) do |request|
        expect(request.to).to eq("+61412345678")
        expect(request.body).to eq("Your order is ready!")
        message_response
      end
      
      result = service.send_notification(
        phone: "+61412345678",
        message: "Your order is ready!"
      )
      
      expect(result[:success]).to be true
      expect(result[:message_id]).to eq("MSG123")
    end
    
    it "handles API errors gracefully" do
      api_error = Telstra_Messaging::ApiError.new("Invalid phone number")
      allow(messaging_api).to receive(:send_sms).and_raise(api_error)
      
      result = service.send_notification(
        phone: "invalid",
        message: "Test"
      )
      
      expect(result[:success]).to be false
      expect(result[:error]).to include("Invalid phone number")
    end
  end
end
```

### Stub Data for Development

#### Create Test Data Generator
```ruby
# lib/telstra_messaging/test_data.rb
module TelstraMessaging
  module TestData
    def self.sample_inbound_sms
      {
        to: "+61400000000",
        from: "+61412345678",
        body: "Sample inbound SMS for testing",
        sentTimestamp: Time.current.iso8601,
        messageId: "SAMPLE_#{SecureRandom.hex(8)}"
      }
    end
    
    def self.sample_inbound_mms_with_image
      {
        status: "RECEIVED",
        destinationAddress: "+61400000000", 
        senderAddress: "+61412345678",
        subject: "Sample Image MMS",
        sentTimestamp: Time.current.iso8601,
        envelope: "sample_envelope",
        MMSContent: [
          {
            type: "text/plain",
            filename: "caption.txt",
            payload: Base64.encode64("Check out this image!")
          },
          {
            type: "image/jpeg",
            filename: "sample.jpg", 
            payload: sample_image_base64
          }
        ]
      }
    end
    
    def self.sample_delivery_status(status = "DELIVRD")
      {
        to: "+61412345678",
        sentTimestamp: 5.minutes.ago.iso8601,
        receivedTimestamp: 4.minutes.ago.iso8601,
        messageId: "DELIVERY_#{SecureRandom.hex(8)}",
        deliveryStatus: status
      }
    end
    
    private
    
    def self.sample_image_base64
      # 1x1 pixel transparent PNG
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="
    end
  end
end
```

#### Development Webhook Simulator
```ruby
# lib/tasks/webhook_simulator.rake
namespace :telstra do
  desc "Simulate inbound SMS webhook"
  task :simulate_inbound_sms, [:phone, :message] => :environment do |t, args|
    phone = args[:phone] || "+61412345678"
    message = args[:message] || "Test message from simulator"
    
    payload = {
      to: ENV['TELSTRA_PROVISIONED_NUMBER'] || "+61400000000",
      from: phone,
      body: message,
      sentTimestamp: Time.current.iso8601,
      messageId: "SIM_#{SecureRandom.hex(8)}"
    }
    
    # Post to local webhook endpoint
    require 'net/http'
    require 'json'
    
    uri = URI('http://localhost:3000/webhooks/inbound_sms')
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = payload.to_json
    
    response = http.request(request)
    puts "Simulated SMS webhook sent. Response: #{response.code}"
    puts "Payload: #{payload.to_json}"
  end
  
  desc "Simulate delivery status webhook" 
  task :simulate_delivery_status, [:message_id, :status] => :environment do |t, args|
    message_id = args[:message_id] || "MSG_#{SecureRandom.hex(8)}"
    status = args[:status] || "DELIVRD"
    
    payload = TelstraMessaging::TestData.sample_delivery_status(status)
    payload[:messageId] = message_id
    
    uri = URI('http://localhost:3000/webhooks/delivery_status')
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = payload.to_json
    
    response = http.request(request)
    puts "Simulated delivery webhook sent. Response: #{response.code}"
    puts "Status: #{status}, Message ID: #{message_id}"
  end
end
```

## Message Flow Sequence

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│    Your     │    │   Telstra   │    │   Telstra   │    │  Recipient  │
│     App     │    │    OAuth    │    │ Messaging   │    │   Device    │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
        │                   │                   │                   │
        │ 1. Get Token      │                   │                   │
        │──────────────────>│                   │                   │
        │                   │                   │                   │
        │ 2. Access Token   │                   │                   │
        │<──────────────────│                   │                   │
        │                   │                   │                   │
        │ 3. Send SMS/MMS   │                   │                   │
        │──────────────────────────────────────>│                   │
        │                   │                   │                   │
        │ 4. Message ID     │                   │                   │
        │<──────────────────────────────────────│                   │
        │                   │                   │                   │
        │                   │                   │ 5. Deliver Message│
        │                   │                   │──────────────────>│
        │                   │                   │                   │
        │ 6. Delivery Status (webhook)          │                   │
        │<──────────────────────────────────────│                   │
        │                   │                   │                   │
        │                   │                   │ 7. Reply Message  │
        │                   │                   │<──────────────────│
        │                   │                   │                   │
        │ 8. Inbound Message (webhook)          │                   │
        │<──────────────────────────────────────│                   │
```

### Sequence Steps Explained

1. **Authentication**: Your app gets an OAuth2 token using client credentials
2. **Token Response**: Telstra returns access token for API calls  
3. **Send Message**: Your app sends SMS/MMS via the API
4. **Message Queued**: Telstra returns message ID and queues for delivery
5. **Message Delivery**: Telstra delivers message to recipient's device
6. **Delivery Notification**: If you provided a notifyURL, Telstra sends delivery status
7. **Reply Message**: If recipient replies and you have reply tracking enabled
8. **Inbound Webhook**: Telstra sends the reply to your webhook endpoint

## Error Handling

### Common Error Responses

#### Authentication Errors
```ruby
begin
  result = messaging_api.send_sms(sms_request)
rescue Telstra_Messaging::ApiError => e
  case e.code
  when 401
    # Invalid or expired access token
    puts "Authentication failed: #{e.message}"
    # Refresh token and retry
  when 403  
    # Insufficient permissions
    puts "Access forbidden: #{e.message}"
  end
end
```

#### Validation Errors
```ruby
begin
  result = messaging_api.send_sms(sms_request)
rescue Telstra_Messaging::ApiError => e
  if e.code == 400
    # Parse error details
    error_body = JSON.parse(e.response_body)
    puts "Validation error: #{error_body['message']}"
    puts "Error code: #{error_body['code']}"
    
    case error_body['code']
    when 'DELIVERY-IMPOSSIBLE'
      puts "Invalid 'from' address - check your provisioned number"
    when 'INVALID-RECIPIENT'
      puts "Invalid recipient phone number format"  
    when 'MESSAGE-TOO-LONG'
      puts "Message exceeds maximum length"
    end
  end
end
```

#### Rate Limiting
```ruby
begin
  result = messaging_api.send_sms(sms_request)
rescue Telstra_Messaging::ApiError => e
  if e.code == 429
    # Rate limit exceeded
    retry_after = e.response_headers['Retry-After']
    puts "Rate limited. Retry after #{retry_after} seconds"
    
    # Implement exponential backoff
    sleep(retry_after.to_i)
    retry
  end
end
```

### Robust Error Handling Pattern
```ruby
class TelstraMessagingService
  MAX_RETRIES = 3
  RETRY_DELAY = 1.0
  
  def send_sms_with_retry(sms_request, retries = 0)
    messaging_api.send_sms(sms_request)
  rescue Telstra_Messaging::ApiError => e
    if retries < MAX_RETRIES && retryable_error?(e)
      sleep(RETRY_DELAY * (2 ** retries)) # Exponential backoff
      send_sms_with_retry(sms_request, retries + 1)
    else
      handle_final_error(e)
      raise e
    end
  end
  
  private
  
  def retryable_error?(error)
    # Retry on server errors and rate limits
    [429, 500, 502, 503, 504].include?(error.code)
  end
  
  def handle_final_error(error)
    # Log error, notify monitoring system, etc.
    Rails.logger.error "Telstra API error after retries: #{error.message}"
    ErrorNotificationService.notify(error)
  end
end
```

## Best Practices

### Security
- **Never log access tokens** or sensitive message content
- **Validate webhook signatures** if provided by Telstra
- **Use HTTPS** for all webhook URLs
- **Sanitize user input** before including in messages

### Performance  
- **Implement retry logic** with exponential backoff
- **Use background jobs** for sending messages to avoid blocking requests
- **Cache access tokens** until they expire
- **Batch operations** when possible

### Reliability
- **Handle all webhook payloads idempotently** 
- **Store message IDs** for tracking and deduplication
- **Implement dead letter queues** for failed webhook processing
- **Monitor delivery rates** and set up alerts

### Message Content
- **Keep SMS under 160 characters** when possible to avoid splitting
- **Test emoji support** thoroughly across different devices  
- **Optimize MMS file sizes** - keep under 600kB for "small" classification
- **Include clear call-to-action** and sender identification

### Webhook Handling
```ruby
class WebhookController < ApplicationController
  # Skip CSRF for webhooks
  skip_before_action :verify_authenticity_token
  
  # Ensure idempotent processing
  before_action :check_duplicate_webhook
  
  def inbound_sms
    # Process webhook
    ProcessInboundSmsJob.perform_later(webhook_params)
    render json: { status: 'received' }, status: 200
  rescue => e
    # Log error but return 200 to prevent retries
    Rails.logger.error "Webhook processing error: #{e.message}"
    render json: { status: 'error' }, status: 200
  end
  
  private
  
  def check_duplicate_webhook
    message_id = params[:messageId]
    if message_id && ProcessedWebhook.exists?(message_id: message_id)
      render json: { status: 'duplicate' }, status: 200
      return
    end
    ProcessedWebhook.create!(message_id: message_id) if message_id
  end
end
```

This guide provides comprehensive coverage of the Telstra Messaging API Ruby SDK with practical examples for integration, testing, and production use.
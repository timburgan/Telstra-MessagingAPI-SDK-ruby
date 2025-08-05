# Telstra Messaging API Ruby SDK

The official Ruby gem for integrating with the Telstra Messaging API. Send and receive SMS and MMS messages globally using Telstra's enterprise-grade messaging platform.

## Features

| Feature | Description |
| --- | --- |
| **Send SMS/MMS** | Send text and multimedia messages to mobile devices globally |
| **Receive Messages** | Handle inbound SMS/MMS via webhooks to your application |
| **Delivery Tracking** | Get real-time delivery status and read receipts |
| **Two-Way Messaging** | Enable reply conversations with automatic message tracking |
| **Broadcast Messages** | Send to multiple recipients in a single API call |
| **Rich Content** | Support for images, videos, audio, and documents in MMS |
| **Unicode Support** | Full UTF-8 character set including emojis |
| **Enterprise Features** | Dedicated numbers, alphanumeric sender IDs, and priority messaging |

## Quick Start

Add to your Gemfile:
```ruby
gem 'Telstra_Messaging', '~> 1.0.6'
```

Basic usage:
```ruby
require 'Telstra_Messaging'

# Configure authentication
Telstra_Messaging.configure do |config|
  config.access_token = 'YOUR_ACCESS_TOKEN'
end

# Send an SMS
messaging_api = Telstra_Messaging::MessagingApi.new
sms_request = Telstra_Messaging::SendSMSRequest.new(
  to: "+61412345678",
  body: "Hello from Telstra!"
)

result = messaging_api.send_sms(sms_request)
puts "Message sent! ID: #{result.message_id}"
```

## 📖 Documentation

- **[Developer Guide](DEVELOPER_GUIDE.md)** - Comprehensive integration guide with webhook payloads, examples, and testing
- **[API Reference](docs/)** - Detailed API documentation for all classes and methods
- **[Examples](examples/)** - Complete code examples for sending messages and handling webhooks

### Message Flow Overview

The Telstra Messaging API follows these basic flows:

**Sending Messages:** App → Authentication → Send Message → Delivery → Optional Webhook
**Receiving Messages:** Device → Telstra Network → Webhook → Your App → Process & Reply

## Requirements

- **Ruby 3.3+** - This gem requires Ruby version 3.3 or higher

## Installation

### From RubyGems
```bash
gem install Telstra_Messaging
```

### With Bundler
Add to your `Gemfile`:
```ruby
gem 'Telstra_Messaging', '~> 1.0.6'
```
Then run:
```bash
bundle install
```

### From Git
```ruby
gem 'Telstra_Messaging', git: 'https://github.com/Telstra/MessagingAPI-SDK-Ruby.git'
```

### Build from Source
```bash
git clone https://github.com/Telstra/MessagingAPI-SDK-Ruby.git
cd MessagingAPI-SDK-Ruby
gem build Telstra_Messaging.gemspec
gem install ./Telstra_Messaging-1.0.6.gem
```

## Getting Started

### 1. Get API Access
1. Register at [dev.telstra.com](https://dev.telstra.com)
2. Create an application and select **API Free Trial** product
3. Note your `Client Key` and `Client Secret` for authentication
4. Get 1000 free messages to start (additional messages available for purchase)

### 2. Authentication
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

### 3. Provision a Number
```ruby
# Get a dedicated number for sending/receiving
provisioning_api = Telstra_Messaging::ProvisioningApi.new
provision_request = Telstra_Messaging::ProvisionNumberRequest.new(
  active_days: 30,
  notify_url: "https://yourapp.com/webhooks/inbound"
)
result = provisioning_api.create_subscription(provision_request)
puts "Your number: #{result.destination_address}"
```

### 4. Send Your First Message
```ruby
sms_request = Telstra_Messaging::SendSMSRequest.new(
  to: "+61412345678",
  body: "Hello from Telstra API!"
)
result = messaging_api.send_sms(sms_request)
puts "Message sent! ID: #{result.message_id}"
```

## Key Use Cases

### Send SMS
```ruby
sms_request = Telstra_Messaging::SendSMSRequest.new(
  to: "+61412345678",
  body: "Your verification code is: 123456",
  notify_url: "https://yourapp.com/delivery-status"
)
result = messaging_api.send_sms(sms_request)
```

### Send MMS with Image
```ruby
# Encode image as base64
image_data = Base64.encode64(File.read("image.jpg"))

mms_content = Telstra_Messaging::MMSContent.new(
  type: "image/jpeg",
  filename: "image.jpg",
  payload: image_data
)

mms_request = Telstra_Messaging::SendMmsRequest.new(
  to: "+61412345678",
  subject: "Check this out!",
  mms_content: [mms_content]
)
result = messaging_api.send_mms(mms_request)
```

### Handle Inbound Messages
```ruby
# In your webhook endpoint
def webhook_handler
  payload = JSON.parse(request.body.read)
  
  case request.headers['X-Webhook-Event']
  when 'inbound-sms'
    handle_inbound_sms(payload)
  when 'inbound-mms' 
    handle_inbound_mms(payload)
  when 'delivery-status'
    handle_delivery_status(payload)
  end
  
  render json: { status: 'received' }
end
```

### Two-Way Conversations
```ruby
# Enable reply tracking
sms_request = Telstra_Messaging::SendSMSRequest.new(
  to: "+61412345678", 
  body: "Reply with A, B, or C for your choice",
  reply_request: true,
  notify_url: "https://yourapp.com/webhooks/replies"
)
result = messaging_api.send_sms(sms_request)

# Replies will be sent to your webhook with the same messageId
```

## Frequently Asked Questions

**Q: Do I need a provisioned number to send messages?**
A: Yes, you must provision a dedicated number before sending SMS/MMS messages.

**Q: How long does my number stay active?**
A: Numbers are active for 30 days by default. Use the `activeDays` parameter when provisioning to extend this.

**Q: Can I send to international numbers?**
A: Yes, except to sanctioned countries: Burma, Côte d'Ivoire, Cuba, Iran, North Korea, Syria.

**Q: What's the difference between Small and Large MMS?**
A: Small MMS are under 600kB, Large MMS are over 600kB. They're charged differently.

**Q: How do I handle message delivery failures?**
A: Implement webhook handlers for delivery status updates, or poll the status API for messages without webhooks.

**Q: Can I use alphanumeric sender IDs?**
A: Yes, but only on Telstra Account paid plans (not credit card plans).

**Q: What's the maximum message length?**
A: SMS: 1900 characters (single recipient) or 500 characters (multiple recipients). Messages over 160 chars are automatically split.

For more detailed information, see the [Developer Guide](DEVELOPER_GUIDE.md).

## Resources

- 📖 [Developer Guide](DEVELOPER_GUIDE.md) - Comprehensive integration guide
- 🔄 [Message Flows](MESSAGE_FLOWS.md) - Visual sequence diagrams 
- 💻 [Code Examples](examples/) - Practical webhook and messaging examples
- 🧪 [API Testing with Postman](https://app.getpostman.com/run-collection/ded00578f69a9deba256)

## API Reference

All URIs are relative to *https://tapi.telstra.com/v2*

| Class | Method | HTTP request | Description |
|-------|--------|--------------|-------------|
| *Telstra_Messaging::AuthenticationApi* | [**auth_token**](docs/AuthenticationApi.md#auth_token) | **POST** /oauth/token | Generate OAuth2 token |
| *Telstra_Messaging::MessagingApi* | [**send_sms**](docs/MessagingApi.md#send_sms) | **POST** /messages/sms | Send SMS |
| *Telstra_Messaging::MessagingApi* | [**send_mms**](docs/MessagingApi.md#send_mms) | **POST** /messages/mms | Send MMS |
| *Telstra_Messaging::MessagingApi* | [**get_sms_status**](docs/MessagingApi.md#get_sms_status) | **GET** /messages/sms/{messageId}/status | Get SMS Status |
| *Telstra_Messaging::MessagingApi* | [**get_mms_status**](docs/MessagingApi.md#get_mms_status) | **GET** /messages/mms/{messageid}/status | Get MMS Status |
| *Telstra_Messaging::MessagingApi* | [**retrieve_sms_responses**](docs/MessagingApi.md#retrieve_sms_responses) | **GET** /messages/sms | Retrieve SMS Responses |
| *Telstra_Messaging::MessagingApi* | [**retrieve_mms_responses**](docs/MessagingApi.md#retrieve_mms_responses) | **GET** /messages/mms | Retrieve MMS Responses |
| *Telstra_Messaging::ProvisioningApi* | [**create_subscription**](docs/ProvisioningApi.md#create_subscription) | **POST** /messages/provisioning/subscriptions | Create Subscription |
| *Telstra_Messaging::ProvisioningApi* | [**get_subscription**](docs/ProvisioningApi.md#get_subscription) | **GET** /messages/provisioning/subscriptions | Get Subscription |
| *Telstra_Messaging::ProvisioningApi* | [**delete_subscription**](docs/ProvisioningApi.md#delete_subscription) | **DELETE** /messages/provisioning/subscriptions | Delete Subscription |

### Models

- [Telstra_Messaging::SendSMSRequest](docs/SendSMSRequest.md)
- [Telstra_Messaging::SendMmsRequest](docs/SendMmsRequest.md)
- [Telstra_Messaging::MMSContent](docs/MMSContent.md)
- [Telstra_Messaging::MessageSentResponse](docs/MessageSentResponse.md)
- [Telstra_Messaging::InboundPollResponse](docs/InboundPollResponse.md)
- [Telstra_Messaging::OutboundPollResponse](docs/OutboundPollResponse.md)
- [Telstra_Messaging::ProvisionNumberRequest](docs/ProvisionNumberRequest.md)
- [Telstra_Messaging::ProvisionNumberResponse](docs/ProvisionNumberResponse.md)
- [Complete Model List](docs/)

## Version Information

- API version: 2.2.9
- Package version: 1.0.6

## Authentication

This SDK uses OAuth2 with client credentials flow:

- **Type**: OAuth
- **Flow**: application
- **Scopes**: NSMS

## License

See the LICENSE file for details.

## Support

For technical support and questions:
- [Developer Portal](https://dev.telstra.com)
- [API Documentation](https://dev.telstra.com/content/messaging-api-v2)
- [GitHub Issues](https://github.com/Telstra/MessagingAPI-SDK-Ruby/issues)
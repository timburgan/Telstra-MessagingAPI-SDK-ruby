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
- **[Message Flows](MESSAGE_FLOWS.md)** - Visual sequence diagrams showing API interaction patterns
- **[API Reference](docs/)** - Detailed API documentation for all classes and methods

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

# Frequently Asked Questions

**Q: Is creating a subscription via the Provisioning call a required step?**

A. Yes. You will only be able to start sending messages if you have a provisioned dedicated number. Use Provisioning to create a dedicated number subscription, or renew your dedicated number if it has expired.

**Q: When trying to send an SMS I receive a `400 Bad Request` response. How can I fix this?**

A. You need to make sure you have a provisioned dedicated number before you can send an SMS. 
If you do not have a provisioned dedicated number and you try to send a message via the API, you will get the error below in the response:

<pre><code class=\"language-sh\">{
  \"status\":\"400\",
  \"code\":\"DELIVERY-IMPOSSIBLE\",
  \"message\":\"Invalid \\'from\\' address specified\"
}</code></pre>

Use Provisioning to create a dedicated number subscription, or renew your dedicated number if it has expired.

**Q: How long does my dedicated number stay active for?**

A. When you provision a dedicated number, by default it will be active for 30 days. 
You can use the `activeDays` parameter during the provisioning call to increment or decrement the number of days your dedicated number will remain active.

Note that Free Trial apps will have 30 days as the maximum `activeDays` they can add to their provisioned number. If the Provisioning call is made several times within that 30-Day period, it will return the `expiryDate` in the Unix format and will not add any activeDays until after that `expiryDate`.

**Q: Can I send a broadcast message using the Telstra Messaging API?**

A. Yes. Recipient numbers can be in the form of an array of strings if a broadcast message needs to be sent, allowing you to send to multiple mobile numbers in one API call.
  A sample request body for this will be: `{\"to\":[\"+61412345678\",\"+61487654321\"],\"body\":\"Test Message\"}`
  
**Q: Can I send SMS and MMS to all countries?**

A. You can send SMS and MMS to all countries EXCEPT to countries which are subject to global sanctions namely: Burma, Côte d'Ivoire, Cuba, Iran, North Korea, Syria.

**Q: Can I use `Alphanumeric Identifier` from my paid plan via credit card?**

A. `Alphanumeric Identifier` is only available on Telstra Account paid plans, not through credit card paid plans.

**Q: What is the maximum sized MMS that I can send?**

A. This will depend on the carrier that will receive the MMS. For Telstra it's up to 2MB,  Optus up to 1.5MB and Vodafone only allows up to 500kB. You will need to check with international carriers for thier MMS size limits.

**Q: How is the size of an MMS calculated?**

A. Images are scaled up to approximately 4/3 when base64 encoded.
Additionally, there is approximately 200 bytes of overhead on each MMS.
Assuming the maximum MMS that can be sent on Telstra’s network is 2MB, then the maximum image size that can be sent will be approximately 1.378MB (1.378 x 1.34 + 200, without SOAP encapsulation).

**Q: How is an MMS classified as Small or Large?**

A. MMSes with size below 600kB are classed as Small whereas those that are bigger than 600kB are classed as Large. They will be charged accordingly.

**Q: Are SMILs supported by the Messaging API?**

A. While there will be no error if you send an MMS with a SMIL presentation, the actual layout or sequence defined in the SMIL may not display as expected because most of the new smartphone devices ignore the SMIL presentation layer. SMIL was used in feature phones which had limited capability and SMIL allowed a *powerpoint type* presentation to be provided. Smartphones now have the capability to display video which is the better option for presentations. It is recommended that MMS messages should just drop the SMIL.

**Q: How do I assign a delivery notification or callback URL?**

A. You can assign a delivery notification or callback URL by adding the `notifyURL` parameter in the body of the request when you send a message. Once the message has been delivered, a notification will then be posted to this callback URL.

**Q: What is the difference between the `notifyURL` parameter in the Provisoning call versus the `notifyURL` parameter in the Send Message call?**

A. The `notifyURL` in the Provisoning call will be the URL where replies to the provisioned number will be posted.
On the other hand, the `notifyURL` in the Send Message call will be the URL where the delivery notification will be posted, e.g. when an SMS has already been delivered to the recipient.

# Getting Started

Below are the steps to get started with the Telstra Messaging API.
  1. Generate an OAuth2 token using your `Client key` and `Client secret`.
  2. Use the Provisioning call to create a subscription and receive a dedicated number.
  3. Send a message to a specific mobile number.

## Run in Postman
<a
href=\"https://app.getpostman.com/run-collection/ded00578f69a9deba256#?env%5BMessaging%20API%20Environments%5D=W3siZW5hYmxlZCI6dHJ1ZSwia2V5IjoiY2xpZW50X2lkIiwidmFsdWUiOiIiLCJ0eXBlIjoidGV4dCJ9LHsiZW5hYmxlZCI6dHJ1ZSwia2V5IjoiY2xpZW50X3NlY3JldCIsInZhbHVlIjoiIiwidHlwZSI6InRleHQifSx7ImVuYWJsZWQiOnRydWUsImtleSI6ImFjY2Vzc190b2tlbiIsInZhbHVlIjoiIiwidHlwZSI6InRleHQifSx7ImVuYWJsZWQiOnRydWUsImtleSI6Imhvc3QiLCJ2YWx1ZSI6InRhcGkudGVsc3RyYS5jb20iLCJ0eXBlIjoidGV4dCJ9LHsiZW5hYmxlZCI6dHJ1ZSwia2V5IjoiQXV0aG9yaXphdGlvbiIsInZhbHVlIjoiIiwidHlwZSI6InRleHQifSx7ImVuYWJsZWQiOnRydWUsImtleSI6Im9hdXRoX2hvc3QiLCJ2YWx1ZSI6InNhcGkudGVsc3RyYS5jb20iLCJ0eXBlIjoidGV4dCJ9LHsiZW5hYmxlZCI6dHJ1ZSwia2V5IjoibWVzc2FnZV9pZCIsInZhbHVlIjoiIiwidHlwZSI6InRleHQifV0=\"><img
src=\"https://run.pstmn.io/button.svg\" alt=\"Run in Postman\"/></a>

## Sample Apps
  - [Perl Sample App](https://github.com/telstra/MessagingAPI-perl-sample-app)
  - [Happy Chat App](https://github.com/telstra/messaging-sample-code-happy-chat)
  - [PHP Sample App](https://github.com/developersteve/telstra-messaging-php)

## SDK Repos
  - [Messaging API - PHP SDK](https://github.com/telstra/MessagingAPI-SDK-php)
  - [Messaging API - Python SDK](https://github.com/telstra/MessagingAPI-SDK-python)
  - [Messaging API - Ruby SDK](https://github.com/telstra/MessagingAPI-SDK-ruby)
  - [Messaging API - NodeJS SDK](https://github.com/telstra/MessagingAPI-SDK-node)
  - [Messaging API - .Net2 SDK](https://github.com/telstra/MessagingAPI-SDK-dotnet)
  - [Messaging API - Java SDK](https://github.com/telstra/MessagingAPI-SDK-Java)

## Blog Posts
For more information on the Messaging API, you can read these blog posts:
- [Callbacks Part 1](https://dev.telstra.com/content/understanding-messaging-api-callbacks-part-1) 
- [Callbacks Part 2](https://dev.telstra.com/content/understanding-messaging-api-callbacks-part-2)



- API version: 2.2.9
- Package version: 1.0.6

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

## Documentation for API Endpoints

All URIs are relative to *https://tapi.telstra.com/v2*

Class | Method | HTTP request | Description
------------ | ------------- | ------------- | -------------
*Telstra_Messaging::AuthenticationApi* | [**auth_token**](docs/AuthenticationApi.md#auth_token) | **POST** /oauth/token | Generate OAuth2 token
*Telstra_Messaging::MessagingApi* | [**get_mms_status**](docs/MessagingApi.md#get_mms_status) | **GET** /messages/mms/{messageid}/status | Get MMS Status
*Telstra_Messaging::MessagingApi* | [**get_sms_status**](docs/MessagingApi.md#get_sms_status) | **GET** /messages/sms/{messageId}/status | Get SMS Status
*Telstra_Messaging::MessagingApi* | [**retrieve_mms_responses**](docs/MessagingApi.md#retrieve_mms_responses) | **GET** /messages/mms | Retrieve MMS Responses
*Telstra_Messaging::MessagingApi* | [**retrieve_sms_responses**](docs/MessagingApi.md#retrieve_sms_responses) | **GET** /messages/sms | Retrieve SMS Responses
*Telstra_Messaging::MessagingApi* | [**send_mms**](docs/MessagingApi.md#send_mms) | **POST** /messages/mms | Send MMS
*Telstra_Messaging::MessagingApi* | [**send_sms**](docs/MessagingApi.md#send_sms) | **POST** /messages/sms | Send SMS
*Telstra_Messaging::ProvisioningApi* | [**create_subscription**](docs/ProvisioningApi.md#create_subscription) | **POST** /messages/provisioning/subscriptions | Create Subscription
*Telstra_Messaging::ProvisioningApi* | [**delete_subscription**](docs/ProvisioningApi.md#delete_subscription) | **DELETE** /messages/provisioning/subscriptions | Delete Subscription
*Telstra_Messaging::ProvisioningApi* | [**get_subscription**](docs/ProvisioningApi.md#get_subscription) | **GET** /messages/provisioning/subscriptions | Get Subscription


## Documentation for Models

 - [Telstra_Messaging::DeleteNumberRequest](docs/DeleteNumberRequest.md)
 - [Telstra_Messaging::GetSubscriptionResponse](docs/GetSubscriptionResponse.md)
 - [Telstra_Messaging::InboundPollResponse](docs/InboundPollResponse.md)
 - [Telstra_Messaging::MMSContent](docs/MMSContent.md)
 - [Telstra_Messaging::Message](docs/Message.md)
 - [Telstra_Messaging::MessageSentResponse](docs/MessageSentResponse.md)
 - [Telstra_Messaging::OAuthResponse](docs/OAuthResponse.md)
 - [Telstra_Messaging::OutboundPollResponse](docs/OutboundPollResponse.md)
 - [Telstra_Messaging::ProvisionNumberRequest](docs/ProvisionNumberRequest.md)
 - [Telstra_Messaging::ProvisionNumberResponse](docs/ProvisionNumberResponse.md)
 - [Telstra_Messaging::SendMmsRequest](docs/SendMmsRequest.md)
 - [Telstra_Messaging::SendSMSRequest](docs/SendSMSRequest.md)
 - [Telstra_Messaging::Status](docs/Status.md)


## Documentation for Authorisation


### auth

- **Type**: OAuth
- **Flow**: application
- **Authorisation URL**: 
- **Scopes**: 
  - NSMS: NSMS


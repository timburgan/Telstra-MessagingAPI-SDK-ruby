# Telstra Messaging API - Testing Examples

This directory contains practical examples for testing and development with the Telstra Messaging API Ruby SDK.

## Examples Included

### Webhook Testing (`webhook_example.rb`)
Complete webhook handler implementation with:
- Inbound SMS/MMS processing
- Delivery status handling
- Error handling and validation
- Idempotency checks

### Message Sending (`send_message_example.rb`)
Examples for sending messages:
- Basic SMS with all options
- MMS with multiple content types
- Broadcast messaging
- Error handling with retries

### Mock Data (`mock_data.rb`)
Sample webhook payloads for testing:
- Inbound SMS payloads
- Inbound MMS payloads with various content types
- Delivery status notifications
- Error scenarios

## Running the Examples

1. Install dependencies:
```bash
bundle install
```

2. Set environment variables:
```bash
export TELSTRA_CLIENT_ID="your_client_id"
export TELSTRA_CLIENT_SECRET="your_client_secret"
export TELSTRA_PROVISIONED_NUMBER="+61400000000"
```

3. Run individual examples:
```bash
ruby examples/send_message_example.rb
ruby examples/webhook_example.rb
```

## Using in Your Application

These examples are designed to be copied and adapted for your specific use case. Each file includes comprehensive comments explaining the implementation details.

For complete documentation, see:
- [Developer Guide](../DEVELOPER_GUIDE.md)
- [Message Flows](../MESSAGE_FLOWS.md)
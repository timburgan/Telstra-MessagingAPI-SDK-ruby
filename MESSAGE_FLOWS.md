# Message Flow Sequence Diagram

This document provides visual representations of the message flows in the Telstra Messaging API.

## Outbound Message Flow (Sending Messages)

```mermaid
sequenceDiagram
    participant App as Your Application
    participant Auth as Telstra OAuth
    participant API as Telstra Messaging API
    participant Network as Telstra Network
    participant Device as Recipient Device
    
    Note over App,Device: 1. Authentication Flow
    App->>Auth: POST /oauth/token<br/>(client_id, client_secret)
    Auth-->>App: access_token
    
    Note over App,Device: 2. Sending Message Flow
    App->>API: POST /messages/sms<br/>(to, body, notifyURL)
    API-->>App: messageId, status
    
    Note over App,Device: 3. Message Delivery
    API->>Network: Queue message for delivery
    Network->>Device: Deliver SMS/MMS
    Device-->>Network: Delivery receipt
    
    Note over App,Device: 4. Delivery Notification (Optional)
    Network->>API: Update delivery status
    API->>App: POST to notifyURL<br/>(deliveryStatus, messageId)
    App-->>API: 200 OK
```

## Inbound Message Flow (Receiving Messages)

```mermaid
sequenceDiagram
    participant Device as Sender Device  
    participant Network as Telstra Network
    participant API as Telstra Messaging API
    participant App as Your Application
    participant DB as Your Database
    
    Note over Device,DB: 1. Receiving Inbound Messages
    Device->>Network: Send SMS/MMS to your number
    Network->>API: Process inbound message
    
    Note over Device,DB: 2. Webhook Delivery
    API->>App: POST to notifyURL<br/>(from, to, body, messageId)
    
    Note over Device,DB: 3. Message Processing
    App->>App: Validate payload
    App->>DB: Store message
    App->>App: Process business logic
    App-->>API: 200 OK
    
    Note over Device,DB: 4. Optional Auto-Reply
    alt Reply enabled
        App->>API: POST /messages/sms<br/>(auto-reply message)
        API-->>App: messageId
        API->>Network: Queue reply
        Network->>Device: Deliver reply
    end
```

## Reply Request Flow (Two-Way Messaging)

```mermaid
sequenceDiagram
    participant App as Your Application
    participant API as Telstra Messaging API
    participant Network as Telstra Network
    participant Customer as Customer Device
    
    Note over App,Customer: 1. Initiate Conversation
    App->>API: POST /messages/sms<br/>(replyRequest: true, notifyURL)
    API-->>App: messageId (conversation ID)
    
    Note over App,Customer: 2. Send with Temporary Number
    API->>Network: Assign temporary number
    Network->>Customer: SMS from temporary number
    
    Note over App,Customer: 3. Customer Replies
    Customer->>Network: Reply to temporary number
    Network->>API: Process reply
    
    Note over App,Customer: 4. Reply Webhook
    API->>App: POST to notifyURL<br/>(same messageId, reply content)
    App-->>API: 200 OK
    
    Note over App,Customer: 5. Continue Conversation
    loop Conversation continues
        App->>API: Send follow-up message
        API->>Customer: Deliver message
        Customer->>API: Send reply
        API->>App: Webhook with reply
    end
    
    Note over App,Customer: 6. Conversation Expires (8 days)
```

## MMS with Multiple Content Flow

```mermaid
sequenceDiagram
    participant App as Your Application
    participant Files as File Storage
    participant API as Telstra Messaging API
    participant Device as Recipient Device
    
    Note over App,Device: 1. Prepare MMS Content
    App->>Files: Read image/video files
    Files-->>App: File data
    App->>App: Base64 encode content
    
    Note over App,Device: 2. Send MMS
    App->>API: POST /messages/mms<br/>(subject, MMSContent[])
    Note right of API: MMSContent contains:<br/>- text/plain<br/>- image/jpeg<br/>- video/mp4
    API-->>App: messageId, status
    
    Note over App,Device: 3. Content Processing
    API->>API: Validate content types
    API->>API: Check size limits<br/>(Small: <600kB, Large: >600kB)
    
    Note over App,Device: 4. Delivery
    API->>Device: Deliver MMS
    Device->>Device: Download and display content
    
    Note over App,Device: 5. Delivery Confirmation
    Device-->>API: Delivery receipt
    API->>App: POST to notifyURL<br/>(deliveryStatus: DELIVRD)
```

## Error Handling Flow

```mermaid
sequenceDiagram
    participant App as Your Application
    participant API as Telstra Messaging API
    participant Monitor as Error Monitoring
    participant Queue as Retry Queue
    
    Note over App,Queue: 1. Initial Request
    App->>API: POST /messages/sms
    
    alt Success Case
        API-->>App: 200 OK (messageId)
        App->>App: Process success
    else Client Error (4xx)
        API-->>App: 400/401/403/404
        App->>Monitor: Log error
        App->>App: Handle user error<br/>(don't retry)
    else Server Error (5xx)
        API-->>App: 500/502/503/504
        App->>Queue: Add to retry queue
        App->>Monitor: Log for investigation
        
        Note over App,Queue: 2. Retry with Backoff
        loop Retry attempts (max 3)
            Queue->>API: Retry request
            alt Success
                API-->>Queue: 200 OK
                Queue->>App: Success notification
            else Still failing
                API-->>Queue: 5xx error
                Queue->>Queue: Wait (exponential backoff)
            end
        end
        
        Note over App,Queue: 3. Final failure
        Queue->>Monitor: Alert after max retries
        Queue->>App: Dead letter queue
    else Rate Limited (429)
        API-->>App: 429 + Retry-After header
        App->>Queue: Schedule retry after delay
        Queue->>API: Retry after delay
    end
```

## Webhook Security Flow

```mermaid
sequenceDiagram
    participant API as Telstra Messaging API
    participant LB as Load Balancer
    participant App as Your Application
    participant DB as Database
    participant Cache as Redis Cache
    
    Note over API,Cache: 1. Webhook Delivery
    API->>LB: POST /webhooks/inbound<br/>(message payload)
    LB->>App: Forward request
    
    Note over API,Cache: 2. Security Validation
    App->>App: Validate content-type
    App->>App: Check IP whitelist
    App->>App: Verify webhook signature<br/>(if implemented)
    
    Note over API,Cache: 3. Idempotency Check
    App->>Cache: Check messageId exists
    alt Already processed
        Cache-->>App: Duplicate detected
        App-->>API: 200 OK (ignore)
    else New message
        Cache-->>App: Not found
        App->>Cache: Store messageId
        
        Note over API,Cache: 4. Process Message
        App->>DB: Validate and store
        App->>App: Business logic
        App-->>API: 200 OK
    end
    
    Note over API,Cache: 5. Error Handling
    alt Processing fails
        App->>App: Log error
        App-->>API: 200 OK<br/>(prevent retries)
    end
```

## Provisioning Flow

```mermaid
sequenceDiagram
    participant App as Your Application
    participant Auth as Telstra OAuth
    participant Provision as Provisioning API
    participant Messaging as Messaging API
    participant Customer as Customer Device
    
    Note over App,Customer: 1. Get Access Token
    App->>Auth: POST /oauth/token
    Auth-->>App: access_token
    
    Note over App,Customer: 2. Create Subscription
    App->>Provision: POST /provisioning/subscriptions<br/>(activeDays, notifyURL)
    Provision-->>App: destinationAddress<br/>(your dedicated number)
    
    Note over App,Customer: 3. Start Messaging
    App->>Messaging: POST /messages/sms<br/>(using dedicated number)
    Messaging-->>App: messageId
    
    Note over App,Customer: 4. Receive Inbound
    Customer->>Provision: Send to dedicated number
    Provision->>App: POST to notifyURL<br/>(inbound message)
    
    Note over App,Customer: 5. Subscription Management
    loop Subscription active (30 days default)
        App->>Provision: GET /provisioning/subscriptions
        Provision-->>App: expiryDate, destinationAddress
        
        alt Near expiry
            App->>Provision: POST /provisioning/subscriptions<br/>(extend activeDays)
            Provision-->>App: new expiryDate
        end
    end
    
    Note over App,Customer: 6. Cleanup (Optional)
    App->>Provision: DELETE /provisioning/subscriptions
    Provision-->>App: 204 No Content
```

## Message Status Polling Flow

```mermaid
sequenceDiagram
    participant App as Your Application
    participant API as Telstra Messaging API
    participant Scheduler as Background Job
    participant DB as Database
    
    Note over App,DB: 1. Send Message (No notifyURL)
    App->>API: POST /messages/sms<br/>(no notifyURL specified)
    API-->>App: messageId
    App->>DB: Store messageId + status: SENT
    
    Note over App,DB: 2. Schedule Status Polling
    App->>Scheduler: Schedule job for messageId
    
    Note over App,DB: 3. Periodic Status Check
    loop Until delivered or expired
        Scheduler->>API: GET /messages/sms/{messageId}/status
        API-->>Scheduler: deliveryStatus, timestamps
        
        alt Status changed
            Scheduler->>DB: Update message status
            Scheduler->>App: Trigger status webhook/callback
        else Status unchanged
            Scheduler->>Scheduler: Wait before next poll
        end
        
        alt Message expired or final status
            Scheduler->>Scheduler: Stop polling
        end
    end
    
    Note over App,DB: 4. Final Status Update
    Scheduler->>DB: Mark as final status
    Scheduler->>App: Final notification
```

These diagrams illustrate the key workflows when using the Telstra Messaging API Ruby SDK. They can help developers understand the interaction patterns and implement robust messaging solutions.
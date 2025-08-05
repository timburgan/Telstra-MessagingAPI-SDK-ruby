# Telstra Messaging API Ruby SDK - Practical Test Scenarios

This document outlines focused, practical test scenarios for the Telstra Messaging API Ruby SDK. These scenarios prioritize SDK-specific functionality and practical testing approaches that don't require extensive API mocking.

## Testing Philosophy

Since this gem is primarily a wrapper around the Telstra API, testing focuses on:
- **SDK Functionality**: Object creation, validation, serialization, configuration
- **Error Handling**: How the SDK handles various error conditions
- **Ruby Compatibility**: Ensuring the SDK works across supported Ruby versions
- **Integration Points**: Basic integration tests against test environments when possible
- **Breaking Change Prevention**: Tests to catch regressions during development

## Implementation Notes

These scenarios use:
- **RSpec** as the testing framework (existing setup)
- **Fixtures** for consistent test data
- **Minimal mocking** - primarily for error conditions and edge cases
- **Real API testing** for critical integration scenarios (when test credentials available)

---

## 1. Model Validation and Serialization Tests

These tests focus on the SDK's ability to create, validate, and serialize request/response objects.

### 1.1 SendSMSRequest Object Creation and Validation
- **Purpose**: Ensure the SDK properly validates input and creates valid request objects
- **Test**: Create SendSMSRequest with various valid and invalid parameters
- **Assertions**:
  - Valid phone numbers are accepted
  - Invalid phone numbers are rejected with clear errors
  - Required fields (to, body) are enforced
  - Optional fields are handled correctly
  - Object serializes to expected JSON format

### 1.2 SendMmsRequest Object Creation and Validation  
- **Purpose**: Test MMS-specific validation and content handling
- **Test**: Create SendMmsRequest with various media content
- **Assertions**:
  - Media content validation works
  - Base64 encoding is handled correctly
  - File size calculations are accurate
  - Missing content is detected

### 1.3 Response Object Deserialization
- **Purpose**: Ensure API responses are correctly parsed into objects
- **Test**: Parse JSON responses into model objects
- **Assertions**:
  - Valid JSON creates proper objects
  - All fields are mapped correctly
  - Missing optional fields don't break parsing
  - Invalid JSON raises appropriate errors

## 2. Configuration and Setup Tests

These tests verify SDK configuration and initialization work correctly.

### 2.1 SDK Configuration Setup
- **Purpose**: Test SDK configuration with various settings
- **Test**: Configure SDK with different client credentials and settings
- **Assertions**:
  - Valid configuration is accepted
  - Invalid configurations raise clear errors
  - Default values are applied correctly
  - Environment variables are read when present

### 2.2 API Client Initialization
- **Purpose**: Ensure API client is properly initialized
- **Test**: Initialize API client with various configurations
- **Assertions**:
  - Client is created with correct settings
  - Authentication headers are set properly
  - Base URL configuration works
  - Timeout settings are applied

## 3. Error Handling Tests

These tests verify the SDK handles various error conditions gracefully.

### 3.1 Network Error Handling
- **Purpose**: Test SDK behavior during network issues
- **Test**: Simulate network timeouts and connection errors
- **Assertions**:
  - Appropriate exceptions are raised
  - Error messages are helpful
  - No partial state corruption occurs
  - Retry logic works as expected (if implemented)

### 3.2 API Error Response Handling
- **Purpose**: Ensure SDK properly handles API error responses
- **Test**: Mock various API error responses (400, 401, 403, 500, etc.)
- **Assertions**:
  - Each error code raises appropriate exception type
  - Error messages from API are preserved
  - HTTP status codes are available in exceptions
  - Error details are accessible

### 3.3 Authentication Error Handling
- **Purpose**: Test handling of authentication failures
- **Test**: Use invalid credentials and expired tokens
- **Assertions**:
  - Authentication failures raise appropriate errors
  - Error messages clearly indicate auth issues
  - No sensitive data is leaked in error messages

## 4. Ruby Version Compatibility Tests

These tests ensure compatibility across Ruby versions. The SDK now requires Ruby 3.3+ as the minimum version.

### 4.1 Ruby 3.3+ Compatibility
- **Purpose**: Verify SDK works with Ruby 3.3 and newer features (required minimum version)
- **Test**: Run core SDK functionality on Ruby 3.3+
- **Assertions**:
  - All core functionality works
  - No deprecation warnings
  - New Ruby features don't break existing code

### 4.2 Gem Dependencies Compatibility
- **Purpose**: Ensure all dependencies work with target Ruby versions
- **Test**: Install and load all dependencies
- **Assertions**:
  - All dependencies install successfully
  - No version conflicts
  - All required features are available

## 5. Critical Integration Tests

These are minimal integration tests for core functionality (requires test API credentials).

### 5.1 Authentication Flow Integration
- **Purpose**: Test end-to-end authentication with real API
- **Test**: Authenticate with test credentials
- **Assertions**:
  - Authentication succeeds with valid credentials
  - Token is received and usable
  - Authentication fails with invalid credentials

### 5.2 Basic SMS Send Integration (if test number available)
- **Purpose**: Test complete SMS sending workflow
- **Test**: Send SMS to test number (if available)
- **Assertions**:
  - SMS request is accepted by API
  - Valid response is received
  - Message ID is returned

### 5.3 Number Provisioning Integration (if test environment supports)
- **Purpose**: Test number provisioning workflow
- **Test**: Provision and delete test number
- **Assertions**:
  - Provisioning request succeeds
  - Number details are returned correctly
  - Deletion works properly

## 6. Security and Input Validation Tests

### 6.1 Input Sanitization
- **Purpose**: Ensure malicious input is handled safely
- **Test**: Pass various malicious inputs to SDK methods
- **Assertions**:
  - Malicious input is properly escaped or rejected
  - No code injection is possible
  - Input validation prevents security issues

### 6.2 Credential Protection
- **Purpose**: Verify credentials are handled securely
- **Test**: Check credential handling in various scenarios
- **Assertions**:
  - Credentials are not logged in plain text
  - Credentials don't appear in error messages
  - Memory handling follows security best practices

## 7. Performance and Resource Tests

### 7.1 Memory Usage Test
- **Purpose**: Ensure SDK doesn't have memory leaks
- **Test**: Create and destroy many SDK objects
- **Assertions**:
  - Memory usage remains stable
  - Objects are properly garbage collected
  - No obvious memory leaks

### 7.2 Concurrent Usage Test
- **Purpose**: Test SDK behavior under concurrent access
- **Test**: Use SDK from multiple threads simultaneously
- **Assertions**:
  - No race conditions occur
  - Thread safety is maintained
  - Performance degrades gracefully

---

## Prioritized Implementation Order

### Phase 1: Essential SDK Tests (High Priority)
1. Model validation and serialization (1.1, 1.2, 1.3)
2. Configuration setup (2.1, 2.2)
3. Basic error handling (3.1, 3.2, 3.3)

### Phase 2: Compatibility and Security (Medium Priority)
4. Ruby version compatibility (4.1, 4.2)
5. Input validation and security (6.1, 6.2)

### Phase 3: Integration and Performance (Lower Priority)
6. Critical integration tests (5.1, 5.2, 5.3) - requires test credentials
7. Performance and resource tests (7.1, 7.2)

## Test Data and Fixtures

Create reusable fixtures for:
- Valid phone numbers (test numbers that don't send real messages)
- Sample message content (including Unicode/emoji)
- Valid media content for MMS testing
- API response examples for deserialization tests
- Error response examples for error handling tests

## Notes for Implementation

1. **Focus on SDK, not API**: Tests should verify SDK behavior, not test the Telstra API itself
2. **Minimize mocking**: Use real objects and minimal mocking except for error conditions
3. **Clear error messages**: Ensure test failures provide actionable information
4. **Fast execution**: Keep tests fast by avoiding unnecessary API calls
5. **Environment flexibility**: Tests should work in CI/CD environments without API access
6. **Documentation**: Each test should clearly document what it's verifying and why
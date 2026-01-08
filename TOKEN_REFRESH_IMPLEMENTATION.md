# Token Refresh Implementation

## Overview
This implementation reduces OTP costs by using a refresh token flow. Users only need to enter OTP once, then stay logged in for 7 days.

## How It Works

### 1. Login Flow
- User enters phone number and receives OTP
- User verifies OTP
- Backend returns **both** `accessToken` (3 hours) and `refreshToken` (7 days)
- Both tokens are stored securely using `flutter_secure_storage`

### 2. Automatic Token Refresh
- All API calls go through `_makeRequest()` helper
- If API returns 401 (Unauthorized), the app automatically:
  1. Calls `/auth/refresh` endpoint with the refresh token
  2. Gets a new access token
  3. Retries the original request with the new token
- User never sees an error or needs to re-login

### 3. Session Duration
- Access token expires after 3 hours
- Refresh token expires after 7 days
- User stays logged in for 7 days without entering OTP again
- After 7 days, both tokens expire and user must re-authenticate with OTP

## Files Modified

1. **pubspec.yaml** - Added `flutter_secure_storage` dependency
2. **token_service.dart** - New service for secure token storage and refresh
3. **api_service.dart** - Updated to use TokenService and auto-refresh on 401
4. **app_provider.dart** - Updated to use TokenService instead of SharedPreferences

## Key Features

- **Secure Storage**: Tokens stored in device keychain/keystore
- **Automatic Refresh**: Transparent to the user
- **Cost Reduction**: OTP only sent once per 7 days instead of every app launch
- **Minimal Code**: Only essential changes, no bloat

## Backend Requirements

The backend must provide:
- `POST /auth/verify-otp` - Returns both `accessToken` and `refreshToken`
- `POST /auth/refresh` - Accepts `refreshToken`, returns new `accessToken`

Example response from `/auth/verify-otp`:
```json
{
  "accessToken": "eyJhbGc...",
  "refreshToken": "eyJhbGc...",
  "user": {
    "id": 123,
    "firstName": "John",
    "lastName": "Doe"
  }
}
```

# Firebase Cloud Messaging Setup Guide

## Overview

ClawChat uses Firebase Cloud Messaging (FCM) for push notifications. This guide explains how to configure your Firebase project and integrate it with ClawChat.

## Prerequisites

- A Firebase account (free tier available)
- A ClawChat server configured to send push notifications

## Setup Steps

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add project"
3. Enter a project name (e.g., "ClawChat")
4. Follow the setup wizard

### 2. Add Android App

1. In your Firebase project, click the Android icon to add an app
2. Enter the package name: `com.openclaw.clawchat`
3. Enter a nickname (e.g., "ClawChat Android")
4. Enter the SHA-1 certificate fingerprint (optional for FCM, but recommended):
   ```bash
   # For debug certificate
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

### 3. Download google-services.json

1. Download `google-services.json` from Firebase Console
2. Place it at: `android/app/google-services.json`
3. **IMPORTANT**: Do NOT commit this file to version control

### 4. Configure Cloud Messaging

1. In Firebase Console, go to Project Settings > Cloud Messaging
2. Note your Server Key (for server-side integration)
3. Generate new VAPID keys if needed for web push

### 5. Server Configuration

On your ClawChat server, configure FCM:

```typescript
// Example server configuration
const fcmConfig = {
  serverKey: 'YOUR_SERVER_KEY_FROM_FIREBASE',
  // Or use Service Account for more secure authentication
  serviceAccount: require('./service-account.json')
};
```

## Push Notification Format

### Message Payload

Your server should send FCM messages in this format:

```json
{
  "to": "DEVICE_TOKEN_OR_TOPIC",
  "notification": {
    "title": "Sender Name",
    "body": "Message content preview..."
  },
  "data": {
    "conversationId": "conv_123",
    "messageId": "msg_456",
    "senderId": "user_789",
    "senderName": "John Doe",
    "type": "chat_message"
  },
  "android": {
    "priority": "high",
    "notification": {
      "channel_id": "clawchat_messages",
      "priority": "high"
    }
  }
}
```

### Required Data Fields

| Field | Description |
|-------|-------------|
| `conversationId` | The conversation ID to navigate to |
| `messageId` | The message ID (optional) |
| `senderId` | The sender's user ID |
| `senderName` | The sender's display name for notification title |
| `type` | Message type (e.g., "chat_message") |

## Client Integration

### Initialize in Flutter

```dart
import 'package:clawchat/src/core/api/push_handler.dart';
import 'package:clawchat/src/platform/push_notification.dart';

// In your main.dart or app initialization:
await PushHandler.initialize(
  onNavigateToConversation: (conversationId, {messageId, senderId, senderName}) {
    // Navigate to chat screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(conversationId: conversationId),
      ),
    );
  },
);

// Subscribe to user's personal topic after login
await PushHandler.subscribeToUserTopic(userId);

// Unsubscribe on logout
await PushHandler.unsubscribeFromUserTopic(userId);
```

### Handle App State

```dart
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      PushHandler.onAppForeground();
    } else if (state == AppLifecycleState.paused) {
      PushHandler.onAppBackground();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PushHandler.dispose();
    super.dispose();
  }
}
```

## Testing

### Send Test Notification

Using Firebase Console:
1. Go to Cloud Messaging section
2. Click "Send your first message"
3. Enter title and body
4. Select your app (com.openclaw.clawchat)
5. Click "Send test message"
6. Enter your device's FCM token (get it from app logs)

### Get Device Token

In your app:
```dart
final token = await PushNotification.getToken();
print('FCM Token: $token');
```

## Troubleshooting

### No notifications received

1. Check if `google-services.json` is in place
2. Verify package name matches in Firebase Console
3. Check notification permissions on device
4. Verify FCM token is registered on server

### Notifications not showing in foreground

This is by design. Foreground messages are forwarded to the app via `PushHandler.onForegroundMessage` stream. You can update UI directly.

### Notifications not navigating to conversation

1. Ensure `onNavigateToConversation` callback is set
2. Check that `conversationId` is in the data payload
3. Verify MainActivity has proper intent handling

### Build errors

1. Make sure Google Services plugin is applied in `app/build.gradle`
2. Check that `google-services.json` exists
3. Sync Gradle files

## Security

- **Never commit** `google-services.json` to version control
- Add it to `.gitignore`:
  ```
  android/app/google-services.json
  ```
- Use the provided `google-services.json.example` as a template
- Each developer/team should use their own Firebase project for development

## Additional Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [FlutterFire Cloud Messaging](https://firebase.flutter.dev/docs/messaging/overview)
- [Android Notification Channels](https://developer.android.com/develop/ui/views/notifications/channels)
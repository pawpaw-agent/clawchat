# Isar Local Storage Implementation

## Overview

This implementation provides persistent local storage for ClawChat messages and sessions using Isar 3.1.0 database.

## Directory Structure

```
lib/src/core/storage/isar/
├── isar.dart                        # Barrel file (exports)
├── isar_service.dart                # Database service (init + CRUD)
├── model_converters.dart            # Freezed ↔ Isar converters
└── collections/
    ├── message_collection.dart      # Message Isar collection
    └── session_collection.dart      # Session Isar collection
```

## Key Components

### 1. Collections (Isar Schema)

**MessageCollection** (`message_collection.dart`)
- Stores message data with indexes on `messageId` (unique), `sessionKey`, and `createdAtMs`
- Fields: messageId, sessionKey, role, content, mediaUrlsJson, timestamps, streaming status

**SessionCollection** (`session_collection.dart`)
- Stores session data with indexes on `sessionKey` (unique), `createdAtMs`, and `lastActiveAtMs`
- Fields: sessionKey, label, agentId, lastMessage, timestamps, archived/pinned flags, messageCount

### 2. Model Converters

**Converters between freezed models and Isar collections:**
- `messageToCollection()` - Message → MessageCollection
- `messageToModel()` - MessageCollection → Message
- `sessionToCollection()` - Session → SessionCollection
- `sessionToModel()` - SessionCollection → Session

This preserves the existing freezed model structure while enabling Isar persistence.

### 3. IsarService

**Initialization:**
```dart
final isarService = IsarService();
await isarService.init();
```

**Message Operations:**
- `saveMessage()` - Save single message
- `saveMessages()` - Bulk save messages
- `getMessage()` - Get by messageId
- `getMessagesBySession()` - Get all messages for a session
- `getMessagesPaginated()` - Paginated message retrieval
- `updateMessage()` - Update message content
- `updateMessageStreaming()` - Update streaming status
- `deleteMessage()` - Delete single message
- `deleteMessagesBySession()` - Delete all messages in session
- `getMessageCount()` - Count messages in session

**Session Operations:**
- `saveSession()` - Save single session
- `saveSessions()` - Bulk save sessions
- `getSession()` - Get by sessionKey
- `getAllSessions()` - Get all sessions (with/without archived)
- `getPinnedSessions()` - Get pinned sessions only
- `updateSessionLastMessage()` - Update last message preview
- `updateSession()` - Update session properties (label, archived, pinned)
- `deleteSession()` - Delete session and all its messages
- `getSessionCount()` - Count sessions

**Utilities:**
- `clearAll()` - Clear all data (for logout)
- `getStats()` - Get database statistics
- `close()` - Close database connection

## Setup Instructions

### 1. Install Dependencies

Dependencies already added to `pubspec.yaml`:
- `isar: ^3.1.0+1`
- `isar_flutter_libs: ^3.1.0+1`
- `isar_generator: ^3.1.0+1` (dev)
- `path_provider: ^2.1.1`

### 2. Run Code Generation

Generate Isar collection schemas:
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate:
- `message_collection.g.dart`
- `session_collection.g.dart`

### 3. Initialize in App

```dart
// In main.dart or app initialization
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final isarService = IsarService();
  await isarService.init();
  
  runApp(MyApp());
}
```

### 4. Usage Example

```dart
import 'package:clawchat/src/core/storage/isar/isar.dart';

// Create message from freezed model
final message = Message(
  id: 'msg_123',
  sessionKey: 'session_abc',
  role: 'user',
  content: 'Hello!',
);

// Convert and save
final collection = messageToCollection(message);
await isarService.saveMessage(collection);

// Retrieve and convert back
final saved = await isarService.getMessage('msg_123');
if (saved != null) {
  final messageModel = messageToModel(saved);
  print(messageModel.content);
}
```

## Database Location

Database files are stored in:
```
<application_documents_directory>/clawchat/
```

On Android: `/data/data/<package_name>/app_flutter/clawchat/`

## Key Features

✅ **Non-invasive**: Preserves existing freezed model structure
✅ **Type-safe**: Full Isar type safety with generated code
✅ **Indexed**: Optimized queries with indexes on frequently accessed fields
✅ **Paginated**: Efficient message loading with pagination support
✅ **Transactional**: All writes wrapped in transactions
✅ **Error Handling**: Comprehensive error logging with Logger

## Notes

- **Generated files**: `*.g.dart` files must be generated before use (see Setup Instructions)
- **Freezed compatibility**: Model converters ensure seamless integration with existing freezed models
- **Media URLs**: Stored as JSON string for simplicity; consider using `json_decode` for production
- **Timestamps**: Stored as milliseconds since epoch for efficient querying and sorting

## Next Steps

1. Run `flutter pub run build_runner build` to generate Isar code
2. Integrate IsarService into Riverpod providers
3. Add database migration strategy for schema changes
4. Consider adding search functionality with Isar's full-text search
5. Add unit tests for CRUD operations
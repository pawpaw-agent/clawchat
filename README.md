# ClawChat

OpenClaw Android Client - Mobile companion app for OpenClaw Gateway.

## Features

- WebSocket connection to OpenClaw Gateway
- Device authentication with secure storage
- Real-time chat with streaming responses
- Session management
- Agent interaction

## Getting Started

1. Install Flutter SDK (3.2.0 or higher)
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the app

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # App configuration
└── src/
    ├── core/                 # Core layer
    │   ├── api/              # Gateway API client
    │   ├── models/           # Data models
    │   ├── storage/         # Storage services
    │   └── constants.dart    # App constants
    ├── features/             # Feature layer
    │   ├── chat/             # Chat feature
    │   ├── sessions/         # Session management
    │   ├── nodes/            # Node management
    │   └── settings/         # Settings
    ├── shared/               # Shared components
    │   ├── widgets/          # Reusable widgets
    │   └── utils/            # Utilities
    └── platform/             # Platform-specific code
```

## Configuration

Set the Gateway URL in settings or use the default:
- Default: `ws://localhost:18789`

## Development

### Code Generation

Run code generation for freezed and JSON serialization:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Linting

```bash
flutter analyze
```

### Testing

```bash
flutter test
```

## License

MIT
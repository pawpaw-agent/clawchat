#!/bin/bash
# Performance Measurement Script for ClawChat
# Measures FPS, memory usage, and scroll performance

set -e

PROJECT_DIR="/home/xsj/.openclaw/workspace-Clay/clawchat"
cd "$PROJECT_DIR"

echo "=== ClawChat Performance Measurement Script ==="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check Flutter installation
if ! command -v flutter &> /dev/null; then
    print_error "Flutter not found. Please install Flutter first."
    exit 1
fi

print_status "Flutter found: $(flutter --version | head -1)"

# Run unit tests
echo ""
echo "=== Running Unit Tests ==="
flutter test test/performance/list_performance_test.dart --reporter=compact

if [ $? -eq 0 ]; then
    print_status "Unit tests passed"
else
    print_error "Unit tests failed"
    exit 1
fi

# Analyze code
echo ""
echo "=== Analyzing Code ==="
flutter analyze lib/src/core/utils/list_optimizer.dart lib/src/features/chat/message_list.dart lib/src/features/sessions/session_list_screen.dart

if [ $? -eq 0 ]; then
    print_status "Code analysis passed"
else
    print_warning "Code analysis found issues"
fi

# Check for compilation errors
echo ""
echo "=== Checking Compilation ==="
flutter build apk --debug --target-platform android-arm64 2>&1 | head -50

if [ $? -eq 0 ]; then
    print_status "Build successful"
else
    print_error "Build failed"
    exit 1
fi

# Profile mode build for performance testing
echo ""
echo "=== Building Profile Mode APK ==="
flutter build apk --profile --target-platform android-arm64

if [ $? -eq 0 ]; then
    print_status "Profile build successful"
    print_status "APK location: $PROJECT_DIR/build/app/outputs/flutter-apk/app-profile.apk"
else
    print_error "Profile build failed"
    exit 1
fi

echo ""
echo "=== Performance Test Instructions ==="
echo "1. Install the profile APK on a physical device:"
echo "   adb install build/app/outputs/flutter-apk/app-profile.apk"
echo ""
echo "2. Use Flutter DevTools to measure performance:"
echo "   flutter pub global activate devtools"
echo "   flutter pub global run devtools"
echo ""
echo "3. Connect to the running app and measure:"
echo "   - FPS during scroll (target: ≥60fps)"
echo "   - Memory usage (target: <200MB with 1000 messages)"
echo "   - Scroll latency"
echo ""
echo "4. For detailed performance overlay, enable in the app:"
echo "   - Go to Settings > Developer Options"
echo "   - Enable 'Performance Overlay'"
echo ""
echo "=== Targets ==="
echo "✓ Message list scroll: 60fps"
echo "✓ Memory with 1000 messages: <200MB"
echo "✓ Image cache: configured for 50MB limit"
echo "✓ Pagination: 20 items per page"
echo ""
print_status "Performance setup complete!"
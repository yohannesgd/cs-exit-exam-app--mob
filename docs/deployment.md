# Deployment Guide

## Building for Production

### Prerequisites

1. Flutter SDK installed
2. Android Studio / VS Code
3. Valid keystore file (for signing)

### Build Steps

```bash
# 1. Clean previous builds
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Build Android App Bundle (for Play Store)
flutter build appbundle --release

# 4. Or build APK (for direct installation)
flutter build apk --release
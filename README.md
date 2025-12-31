# Flutter RTC Streaming App

A comprehensive Flutter application featuring real-time video/audio streaming with dual-platform support for Agora and Tencent RTC SDKs.

## Features

### 🎥 Agora RTC
- **Live Streaming** - High-quality real-time video and audio broadcasting
- **Conference Meetings** - Multi-party video calls with grid layout (up to 17 participants)
- **Interactive Live Room** - Host/Audience modes with live chat, reactions, and co-host requests

### 📹 Tencent RTC
- **Real-time Communication** - Reliable video/audio streaming with Tencent TRTC SDK
- **Multi-platform Support** - Stable connectivity across platforms

### ✨ Core Capabilities
- **Dual-Platform Support** - Switch between Agora and Tencent RTC seamlessly
- **Test Credentials Auto-fill** - Quick login for testing purposes
- **Advanced Controls** - Mute/unmute, camera on/off, camera switching
- **Role Management** - Host, broadcaster, and audience roles
- **Live Interactions** - Chat messaging, reactions, and viewer analytics
- **Modern UI** - Clean Material Design 3 interface

## Tech Stack

- **Flutter** 3.13.2+
- **Agora RTC Engine** ^6.3.2
- **Tencent TRTC Cloud** ^2.9.5
- **Permission Handler** ^11.0.1
- **Provider** ^6.1.1

## Getting Started

### Prerequisites
- Flutter SDK 3.13.2 or higher
- Xcode (for iOS) with deployment target iOS 11.0+
- Android Studio with minSdkVersion 21
- Agora and Tencent Cloud accounts

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd flutter_agora_app
```

2. Install dependencies
```bash
flutter pub get
```

3. Configure SDK credentials
- Update `appId` in Agora screen files
- Set `sdkAppId` and `userSig` in `tencent_screen.dart`

4. Run the app
```bash
flutter run
```

For iOS:
```bash
cd ios && pod install && cd ..
flutter run
```

## Configuration

### Agora Setup
- App ID: Configure in `agora_screen.dart`, `agora_conference_screen.dart`, and `agora_live_screen.dart`
- Generate tokens from [Agora Console](https://console.agora.io/)

### Tencent RTC Setup
- App ID: 20032063
- Generate UserSig from [Tencent Console](https://console.cloud.tencent.com/trtc)

## Build Configuration

### Android
- Gradle: 8.10.2
- Android Gradle Plugin: 8.7.3
- Kotlin: 1.9.24
- compileSdkVersion: 34
- minSdkVersion: 21

### iOS
- Deployment Target: iOS 11.0+
- Requires valid Apple Developer credentials

## Screens

1. **Login Screen** - Test credential auto-fill for quick access
2. **Home Screen** - Platform selection hub (scrollable)
3. **Agora Live Streaming** - One-to-many broadcasting
4. **Agora Conference** - Multi-party video meetings
5. **Agora Live Room** - Interactive live streaming with chat
6. **Tencent RTC** - Tencent-based video streaming

## Permissions

### Android
- Camera, Microphone, Internet, Network State, WiFi State, Bluetooth

### iOS
- Camera, Microphone, Local Network

## License

This project is for demonstration purposes.

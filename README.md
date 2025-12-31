# Flutter Agora & Tencent RTC Streaming App

A Flutter application demonstrating live video/audio streaming using both **Agora RTC** and **Tencent RTC** SDKs.

## Features

- ✅ User authentication with test credentials auto-fill
- ✅ Dual RTC platform support (Agora & Tencent)
- ✅ Live video streaming
- ✅ Live audio streaming
- ✅ Camera switching (front/back)
- ✅ Audio mute/unmute
- ✅ Video on/off
- ✅ Multiple user support
- ✅ Modern Material Design UI

## Screenshots

The app includes:
- Login screen with test credentials button
- Home screen to choose between Agora or Tencent RTC
- Streaming screens with full controls for both platforms

## Prerequisites

Before running this app, make sure you have:

1. **Flutter SDK** installed (version 3.13.2 or higher)
2. **Xcode** (for iOS development)
3. **Android Studio** (for Android development)
4. **Agora Account** - [Sign up here](https://www.agora.io/)
5. **Tencent Cloud Account** - [Sign up here](https://cloud.tencent.com/)

## Getting Started

### 1. Clone the Repository

```bash
cd /path/to/flutter_agora_app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Agora

1. Create an account at [Agora.io](https://www.agora.io/)
2. Create a new project in the Agora Console
3. Get your **App ID**
4. Open `lib/screens/agora_screen.dart`
5. Replace `YOUR_AGORA_APP_ID` with your actual App ID:

```dart
final String appId = 'YOUR_AGORA_APP_ID';  // Replace this
```

**For production**, you should also generate a token:
- In Agora Console, enable App Certificate
- Generate a temporary token for testing
- Update the `token` variable in `agora_screen.dart`

### 4. Configure Tencent RTC

1. Create an account at [Tencent Cloud](https://cloud.tencent.com/)
2. Navigate to TRTC (Tencent Real-Time Communication)
3. Create a new application
4. Get your **SDKAppID** and generate a **UserSig**
5. Open `lib/screens/tencent_screen.dart`
6. Update the following:

```dart
final int sdkAppId = 0;  // Replace with your SDK App ID
final String userSig = '';  // Generate UserSig for production
```

**To generate UserSig:**
- Use the [UserSig Generator](https://console.cloud.tencent.com/trtc/usersigtool)
- For production, implement server-side UserSig generation

### 5. Run the App

#### For Android:
```bash
flutter run
```

#### For iOS:
```bash
cd ios
pod install
cd ..
flutter run
```

## Usage

### Login
1. Launch the app
2. Click "Test Credentials" button to auto-fill login fields
3. Or manually enter:
   - Email: `test@example.com`
   - Password: `Test@123`
4. Click "Login"

### Agora Streaming
1. From home screen, tap "Agora RTC"
2. Click "Join Channel" to start streaming
3. Use controls to:
   - Mute/unmute microphone
   - Turn camera on/off
   - Switch between front/back camera
   - Leave channel

### Tencent Streaming
1. From home screen, tap "Tencent RTC"
2. Click "Join Room" to start streaming
3. Use controls to:
   - Mute/unmute microphone
   - Turn camera on/off
   - Switch between front/back camera
   - Leave room

## Project Structure

```
lib/
├── main.dart                    # App entry point
└── screens/
    ├── login_screen.dart        # Login UI with test credentials
    ├── home_screen.dart         # Platform selection screen
    ├── agora_screen.dart        # Agora RTC implementation
    └── tencent_screen.dart      # Tencent RTC implementation
```

## Dependencies

```yaml
dependencies:
  agora_rtc_engine: ^6.3.2        # Agora RTC SDK
  tencent_trtc_cloud: ^2.9.5      # Tencent RTC SDK
  permission_handler: ^11.0.1      # Runtime permissions
  provider: ^6.1.1                 # State management
```

## Permissions

### Android (AndroidManifest.xml)
- INTERNET
- CAMERA
- RECORD_AUDIO
- MODIFY_AUDIO_SETTINGS
- ACCESS_NETWORK_STATE
- ACCESS_WIFI_STATE
- BLUETOOTH
- BLUETOOTH_ADMIN
- BLUETOOTH_CONNECT

### iOS (Info.plist)
- NSCameraUsageDescription
- NSMicrophoneUsageDescription
- NSLocalNetworkUsageDescription

## Platform Requirements

### Android
- Minimum SDK: 21 (Android 5.0)
- Target SDK: Latest

### iOS
- Minimum iOS: 11.0
- Xcode: Latest stable version

## Troubleshooting

### Android Build Issues
1. Make sure `minSdkVersion` is set to 21 or higher
2. Clean and rebuild: `flutter clean && flutter pub get`
3. Check that all permissions are added to AndroidManifest.xml

### iOS Build Issues
1. Run `pod install` in the ios directory
2. Open Xcode and update signing certificates
3. Check that all permissions are added to Info.plist
4. Ensure deployment target is iOS 11.0 or higher

### Camera/Microphone Not Working
1. Check that permissions are granted in device settings
2. Verify App IDs and tokens are configured correctly
3. Check console logs for permission errors

### Connection Issues
1. Verify your App IDs are correct
2. For production, ensure tokens/UserSig are generated properly
3. Check network connectivity
4. Verify firewall settings allow RTC traffic

## Testing with Multiple Devices

To test video streaming between devices:

1. **Agora**: Use the same channel name on both devices
2. **Tencent**: Use the same room ID on both devices
3. Ensure both devices have valid credentials configured

## Production Checklist

Before deploying to production:

- [ ] Implement server-side token generation (Agora)
- [ ] Implement server-side UserSig generation (Tencent)
- [ ] Add proper error handling and logging
- [ ] Implement network quality monitoring
- [ ] Add analytics and crash reporting
- [ ] Test on various devices and network conditions
- [ ] Implement proper user authentication
- [ ] Add recording capabilities if needed
- [ ] Configure CDN streaming if required
- [ ] Review and optimize video quality settings

## Resources

### Agora Documentation
- [Agora Flutter SDK](https://docs.agora.io/en/video-calling/get-started/get-started-sdk)
- [API Reference](https://api-ref.agora.io/en/flutter/6.x/API/rtc_api_overview.html)

### Tencent Documentation
- [TRTC Flutter SDK](https://cloud.tencent.com/document/product/647/32689)
- [Quick Start Guide](https://cloud.tencent.com/document/product/647/32396)

## License

This project is for demonstration purposes.

## Support

For issues and questions:
- Agora Support: [https://agora.io/en/support/](https://agora.io/en/support/)
- Tencent Support: [https://cloud.tencent.com/document/product/647](https://cloud.tencent.com/document/product/647)

## Notes

- This is a demo application showcasing both Agora and Tencent RTC SDKs
- Replace placeholder App IDs with your actual credentials
- For production use, implement proper server-side authentication
- Test thoroughly on both iOS and Android devices
- Monitor bandwidth and optimize video quality settings based on your use case

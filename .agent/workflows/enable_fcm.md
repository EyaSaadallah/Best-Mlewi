---
description: How to enable and configure Firebase Cloud Messaging (FCM) in the Firebase Console
---

# Enable Firebase Cloud Messaging (FCM)

Follow these steps to configure FCM for your project in the Firebase Console.

## 1. Access Firebase Console
1. Go to [console.firebase.google.com](https://console.firebase.google.com/).
2. Select your project (**bestmlewi2**).

## 2. Verify Cloud Messaging API
FCM is usually enabled by default. To verify and get your credentials:
1. Click the **Gear icon** (Project Settings) in the top left sidebar.
2. Select **Project settings**.
3. Go to the **Cloud Messaging** tab.
4. Ensure the **Firebase Cloud Messaging API (V1)** is enabled. If not, there will be a link to enable it in the Google Cloud Console.

## 3. Configure Platform Specifics

### For Android
1. In **Project settings**, go to the **General** tab.
2. Scroll down to **Your apps**.
3. If you haven't added an Android app yet, click **Add app** (Android icon).
   - Register the app with your package name (e.g., `com.example.bestmlewi2`).
   - Download the `google-services.json` file.
   - Place this file in your Flutter project at `android/app/google-services.json`.

### For iOS (Requires Apple Developer Account)
1. In **Project settings**, go to the **General** tab.
2. If you haven't added an iOS app yet, click **Add app** (iOS icon).
   - Register the app with your Bundle ID.
   - Download `GoogleService-Info.plist`.
   - Place this file in your Flutter project at `ios/Runner/GoogleService-Info.plist` (using Xcode).
3. Go back to the **Cloud Messaging** tab.
4. Under **Apple app configuration**, upload your **APNs Authentication Key** (p8 file) from your Apple Developer account.

## 4. Flutter Project Setup
After configuring the console, you need to add the dependency to your project:

```bash
flutter pub add firebase_messaging
```

And ensure your `android/build.gradle` and `android/app/build.gradle` are configured for the Google Services plugin (usually done automatically if you used `flutterfire configure`).

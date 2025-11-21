# Firebase Integration Checklist

## Pre-Setup
- [ ] Google account created
- [ ] Firebase project name decided: `bestmiawi-project`
- [ ] Flutter project ready at `d:\devFlutter\Flutter_apps\bestmlewi2`

## Step 1: Firebase Project Creation
- [ ] Go to [Firebase Console](https://console.firebase.google.com/)
- [ ] Click "Add project"
- [ ] Enter project name: `bestmiawi-project`
- [ ] Accept Google Analytics terms
- [ ] Create project
- [ ] Wait for project initialization (2-3 minutes)

## Step 2: App Registration

### Android
- [ ] In Firebase Console, click "Add app" → Android
- [ ] Enter package name: `com.example.bestmlewi2`
- [ ] Download `google-services.json`
- [ ] Place in: `android/app/google-services.json`
- [ ] Click "Next" and follow on-screen instructions
- [ ] Click "Continue to console"

### iOS
- [ ] In Firebase Console, click "Add app" → iOS
- [ ] Enter bundle ID: `com.example.bestmlewi2`
- [ ] Download `GoogleService-Info.plist`
- [ ] Open Xcode: `ios/Runner.xcworkspace`
- [ ] Drag `GoogleService-Info.plist` into Xcode
- [ ] Select "Copy items if needed"
- [ ] Click "Finish"

### Web (Optional)
- [ ] In Firebase Console, click "Add app" → Web
- [ ] Copy Firebase config
- [ ] Update `lib/config/firebase_options.dart` with web credentials

## Step 3: Update Credentials

### Get Credentials from Firebase Console
1. Go to Project Settings (gear icon)
2. Select your app
3. Copy the following values:

**For Android/iOS:**
- [ ] API Key
- [ ] App ID
- [ ] Messaging Sender ID
- [ ] Project ID
- [ ] Database URL
- [ ] Storage Bucket

**Update `lib/config/firebase_options.dart`:**
```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',
  appId: '1:YOUR_PROJECT_NUMBER:android:YOUR_APP_ID',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'bestmiawi-project',
  databaseURL: 'https://bestmiawi-project.firebaseio.com',
  storageBucket: 'bestmiawi-project.appspot.com',
);
```

## Step 4: Enable Firebase Services

### Authentication
- [ ] Go to Firebase Console → Authentication
- [ ] Click "Get started"
- [ ] Click "Email/Password"
- [ ] Enable "Email/Password"
- [ ] Click "Save"
- [ ] (Optional) Enable "Anonymous" sign-in

### Firestore Database
- [ ] Go to Firebase Console → Firestore Database
- [ ] Click "Create database"
- [ ] Select region: `europe-west1` (or nearest)
- [ ] Start in **Test mode** (for development)
- [ ] Click "Enable"
- [ ] Wait for database creation

### Storage
- [ ] Go to Firebase Console → Storage
- [ ] Click "Get started"
- [ ] Start in **Test mode**
- [ ] Select region: `europe-west1`
- [ ] Click "Done"

## Step 5: Configure Security Rules

### Firestore Rules
- [ ] Go to Firestore → Rules
- [ ] Replace with rules from `FIREBASE_SETUP.md`
- [ ] Click "Publish"

### Storage Rules
- [ ] Go to Storage → Rules
- [ ] Configure appropriate access rules
- [ ] Click "Publish"

## Step 6: Install Dependencies

```bash
cd d:\devFlutter\Flutter_apps\bestmlewi2
flutter pub get
```

- [ ] Dependencies installed successfully
- [ ] No build errors

## Step 7: Test Firebase Connection

### Run the app
```bash
flutter run
```

- [ ] App starts without Firebase errors
- [ ] Firebase initialization completes
- [ ] No "Firebase not initialized" errors

### Test Authentication
- [ ] Create test user account
- [ ] Login with test credentials
- [ ] Verify user appears in Firebase Console

### Test Firestore
- [ ] Create test data via app
- [ ] Verify data appears in Firestore Console
- [ ] Query data from app

## Step 8: Create Test Data

### Create Test Users
```dart
final authService = FirebaseAuthService();
await authService.register(
  'client@test.com',
  'password123',
  'Test',
  'Client',
  '+33612345678',
);
```

- [ ] Client user created
- [ ] Gerant user created
- [ ] Livreur user created

### Create Test Menu
```dart
final menuRepo = MenuRepository();
await menuRepo.create(testMenu);
```

- [ ] Menu created in Firestore
- [ ] Dishes visible in console

### Create Test Orders
```dart
final commandeRepo = CommandeRepository();
await commandeRepo.create(testOrder);
```

- [ ] Order created in Firestore
- [ ] Order status trackable

## Step 9: Verify All Features

### Authentication
- [ ] Register new user works
- [ ] Login works
- [ ] Logout works
- [ ] Password reset works
- [ ] User data saved to Firestore

### User Management
- [ ] Get all users works
- [ ] Get user by email works
- [ ] Get users by role works
- [ ] Update user works
- [ ] Delete user works

### Order Management
- [ ] Create order works
- [ ] Get all orders works
- [ ] Get orders by status works
- [ ] Update order status works
- [ ] Delete order works

### Menu Management
- [ ] Create menu works
- [ ] Get all menus works
- [ ] Get available dishes works
- [ ] Update menu works
- [ ] Delete menu works

## Step 10: Production Preparation

### Security
- [ ] Update Firestore security rules for production
- [ ] Disable Test mode
- [ ] Enable authentication requirements
- [ ] Set up role-based access control
- [ ] Review and restrict storage access

### Monitoring
- [ ] Enable Firebase Analytics
- [ ] Enable Crashlytics
- [ ] Set up error reporting
- [ ] Configure alerts

### Backup
- [ ] Enable Firestore backups
- [ ] Test backup restoration
- [ ] Document backup procedure

### Documentation
- [ ] Document all Firestore collections
- [ ] Document security rules
- [ ] Document API usage
- [ ] Create runbook for operations

## Troubleshooting

### Build Issues
- [ ] `google-services.json` present in `android/app/`
- [ ] `GoogleService-Info.plist` added to Xcode
- [ ] Firebase dependencies in `pubspec.yaml`
- [ ] Run `flutter clean && flutter pub get`

### Runtime Issues
- [ ] Firebase project ID correct in `firebase_options.dart`
- [ ] Firebase services enabled in console
- [ ] Internet connection available
- [ ] Firestore security rules allow operations
- [ ] User authenticated before database operations

### Connection Issues
- [ ] Check Firebase console for errors
- [ ] Verify project ID matches
- [ ] Check network connectivity
- [ ] Review Firestore rules
- [ ] Check app credentials

## Testing Checklist

### Unit Tests
- [ ] Test authentication service
- [ ] Test user repository
- [ ] Test order repository
- [ ] Test menu repository

### Integration Tests
- [ ] Test complete login flow
- [ ] Test order creation flow
- [ ] Test menu retrieval flow
- [ ] Test user management flow

### Manual Testing
- [ ] Test on Android device
- [ ] Test on iOS device
- [ ] Test on web browser
- [ ] Test offline scenarios
- [ ] Test error handling

## Deployment Checklist

### Before Production
- [ ] All tests passing
- [ ] Security rules configured
- [ ] Error handling implemented
- [ ] Logging configured
- [ ] Performance optimized
- [ ] Backup strategy in place

### Deployment
- [ ] Update security rules
- [ ] Disable Test mode
- [ ] Enable production settings
- [ ] Monitor for errors
- [ ] Test all features post-deployment

### Post-Deployment
- [ ] Monitor Firebase console
- [ ] Check error logs
- [ ] Verify user data integrity
- [ ] Test critical flows
- [ ] Document any issues

## Quick Reference

### Firebase Console URLs
- **Project**: https://console.firebase.google.com/project/bestmiawi-project
- **Authentication**: https://console.firebase.google.com/project/bestmiawi-project/authentication
- **Firestore**: https://console.firebase.google.com/project/bestmiawi-project/firestore
- **Storage**: https://console.firebase.google.com/project/bestmiawi-project/storage

### Key Files
- Configuration: `lib/config/firebase_config.dart`
- Options: `lib/config/firebase_options.dart`
- Auth Service: `lib/services/firebase_auth_service.dart`
- Repositories: `lib/repositories/`
- Setup Guide: `FIREBASE_SETUP.md`

### Common Commands
```bash
# Install dependencies
flutter pub get

# Run app
flutter run

# Clean build
flutter clean

# Check for errors
flutter analyze

# Run tests
flutter test
```

## Support Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter Firebase](https://firebase.flutter.dev/)
- [Firestore Guide](https://firebase.google.com/docs/firestore)
- [Authentication Guide](https://firebase.google.com/docs/auth)
- [Security Rules](https://firebase.google.com/docs/firestore/security/start)

## Notes

- **Project ID**: `bestmiawi-project`
- **Region**: `europe-west1`
- **Development Mode**: Test mode (all reads/writes allowed)
- **Production Mode**: Security rules enforced

---

**Status**: Ready to begin Firebase setup

**Next Step**: Start with Step 1 - Firebase Project Creation

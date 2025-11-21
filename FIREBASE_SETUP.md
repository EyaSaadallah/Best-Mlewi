# Firebase Integration Setup Guide

## Overview
BestMiawi has been integrated with Firebase for authentication, real-time database, and cloud storage. This guide walks you through the complete setup process.

## What's Been Added

### Dependencies (pubspec.yaml)
- `firebase_core: ^3.1.0` - Firebase core functionality
- `firebase_auth: ^5.1.0` - Authentication
- `cloud_firestore: ^5.1.0` - Real-time database
- `firebase_storage: ^12.1.0` - Cloud storage
- `provider: ^6.2.0` - State management

### New Files Created

**Configuration:**
- `lib/config/firebase_config.dart` - Firebase initialization
- `lib/config/firebase_options.dart` - Platform-specific Firebase options

**Repository Layer:**
- `lib/repositories/firebase_repository.dart` - Base repository with CRUD operations
- `lib/repositories/utilisateur_repository.dart` - User management
- `lib/repositories/commande_repository.dart` - Order management
- `lib/repositories/menu_repository.dart` - Menu management

**Services:**
- `lib/services/firebase_auth_service.dart` - Firebase authentication

## Step-by-Step Setup

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: `bestmiawi-project`
4. Accept terms and create project
5. Wait for project creation to complete

### Step 2: Register Your App

#### For Android:
1. In Firebase Console, click "Add app" → Android
2. Enter package name: `com.example.bestmlewi2`
3. Download `google-services.json`
4. Place it in `android/app/` directory

#### For iOS:
1. In Firebase Console, click "Add app" → iOS
2. Enter bundle ID: `com.example.bestmlewi2`
3. Download `GoogleService-Info.plist`
4. Open iOS project in Xcode and add the file

#### For Web:
1. In Firebase Console, click "Add app" → Web
2. Copy the Firebase config
3. Update `lib/config/firebase_options.dart` with web credentials

### Step 3: Update Firebase Options

Replace placeholder credentials in `lib/config/firebase_options.dart`:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY',
  appId: '1:YOUR_PROJECT_NUMBER:android:YOUR_APP_ID',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'bestmiawi-project',
  databaseURL: 'https://bestmiawi-project.firebaseio.com',
  storageBucket: 'bestmiawi-project.appspot.com',
);
```

Get these values from Firebase Console → Project Settings → Your App

### Step 4: Enable Firebase Services

In Firebase Console:

#### Authentication:
1. Go to Authentication → Sign-in method
2. Enable "Email/Password"
3. Enable "Anonymous" (optional)

#### Firestore Database:
1. Go to Firestore Database
2. Click "Create database"
3. Start in **Test mode** (for development)
4. Choose region: `europe-west1` (or nearest)
5. Click "Enable"

#### Storage:
1. Go to Storage
2. Click "Get started"
3. Start in **Test mode**
4. Choose region: `europe-west1`
5. Click "Done"

### Step 5: Set Firestore Security Rules

In Firestore → Rules, replace with:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write their own data
    match /utilisateurs/{userId} {
      allow read, write: if request.auth != null;
    }
    
    // Allow reading menus
    match /menus/{menuId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.token.role == 'gerant';
    }
    
    // Allow managing commands
    match /commandes/{commandeId} {
      allow read, write: if request.auth != null;
    }
    
    // Default deny all
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### Step 6: Install Dependencies

```bash
cd d:\devFlutter\Flutter_apps\bestmlewi2
flutter pub get
```

### Step 7: Update main.dart

Update `lib/main.dart` to initialize Firebase:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'config/firebase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initialize();
  runApp(const MyApp());
}
```

### Step 8: Run the App

```bash
flutter run
```

## Firestore Database Structure

### Collections

#### `utilisateurs` Collection
```
{
  id: int,
  nom: string,
  prenom: string,
  email: string,
  motDePasse: string,
  telephone: string,
  dateInscription: timestamp,
  role: string (client, gerant, coordinateur, livreur, collaborateur, visiteur)
}
```

#### `menus` Collection
```
{
  id: int,
  titre: string,
  plats: [
    {
      id: int,
      nom: string,
      description: string,
      prix: number,
      categorie: string,
      disponible: boolean
    }
  ]
}
```

#### `commandes` Collection
```
{
  id: int,
  dateCreation: timestamp,
  total: number,
  statut: string (cree, enPreparation, prete, enLivraison, livree, annulee),
  lignes: [
    {
      id: int,
      quantite: int,
      prixUnitaire: number,
      sousTotal: number,
      plat: { ... }
    }
  ],
  livraison: {
    id: int,
    adresseLivraison: string,
    dateHeureEstimee: timestamp,
    notes: string
  }
}
```

## Using Firebase Services

### Authentication

```dart
import 'services/firebase_auth_service.dart';

final authService = FirebaseAuthService();

// Register
await authService.register(
  'email@example.com',
  'password123',
  'Dupont',
  'Jean',
  '+33612345678',
);

// Login
await authService.login('email@example.com', 'password123');

// Logout
await authService.logout();

// Check authentication
if (authService.isAuthenticated()) {
  print('User: ${authService.currentUser?.prenom}');
}
```

### User Management

```dart
import 'repositories/utilisateur_repository.dart';

final userRepo = UtilisateurRepository();

// Get all users
final users = await userRepo.getAll();

// Get user by email
final user = await userRepo.getByEmail('email@example.com');

// Get users by role
final clients = await userRepo.getByRole(Role.client);

// Create user
final userId = await userRepo.create(utilisateur);

// Update user
await userRepo.update(userId, updatedUtilisateur);

// Delete user
await userRepo.delete(userId);
```

### Order Management

```dart
import 'repositories/commande_repository.dart';

final commandeRepo = CommandeRepository();

// Get all orders
final orders = await commandeRepo.getAll();

// Get orders by status
final preparing = await commandeRepo.getByStatus(StatusCommande.enPreparation);

// Get orders by date range
final orders = await commandeRepo.getByDateRange(startDate, endDate);

// Create order
final orderId = await commandeRepo.create(commande);

// Update order status
await commandeRepo.updateStatus(orderId, StatusCommande.livree);
```

### Menu Management

```dart
import 'repositories/menu_repository.dart';

final menuRepo = MenuRepository();

// Get all menus
final menus = await menuRepo.getAll();

// Get menu by title
final menu = await menuRepo.getByTitle('Menu Principal');

// Get available dishes
final dishes = await menuRepo.getAvailableDishes(menuId);

// Create menu
final menuId = await menuRepo.create(menu);
```

## Testing Firebase Locally

### Firebase Emulator Suite

1. Install Firebase CLI:
```bash
npm install -g firebase-tools
```

2. Initialize emulator:
```bash
firebase init emulator
```

3. Start emulator:
```bash
firebase emulators:start
```

4. Connect app to emulator (in firebase_config.dart):
```dart
await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
```

## Troubleshooting

### Build Errors

**Error: `google-services.json` not found**
- Solution: Download from Firebase Console and place in `android/app/`

**Error: Pod install fails (iOS)**
- Solution: Run `cd ios && pod install && cd ..`

### Runtime Errors

**Error: Permission denied on Firestore**
- Solution: Check security rules in Firebase Console
- For development, use Test mode (allows all reads/writes)

**Error: Authentication fails**
- Solution: Ensure Email/Password is enabled in Firebase Console

### Connection Issues

**Error: Cannot connect to Firebase**
- Solution: Check internet connection
- Verify Firebase project ID in firebase_options.dart
- Check if Firebase services are enabled in console

## Security Best Practices

1. **Never commit credentials** - Add `google-services.json` to `.gitignore`
2. **Use environment variables** for sensitive data
3. **Enable authentication** before going to production
4. **Set proper Firestore rules** - Don't use Test mode in production
5. **Enable Firebase Security Rules** to restrict data access
6. **Use custom claims** for role-based access control

## Production Checklist

- [ ] Update Firestore security rules
- [ ] Enable Email verification
- [ ] Set up password reset
- [ ] Enable HTTPS only
- [ ] Configure CORS for web
- [ ] Set up backups
- [ ] Enable monitoring and logging
- [ ] Test all authentication flows
- [ ] Test all database operations
- [ ] Set up error reporting

## Next Steps

1. **Implement Provider** for state management
2. **Add real-time listeners** for live updates
3. **Implement offline persistence**
4. **Add push notifications** with Firebase Cloud Messaging
5. **Set up analytics** with Firebase Analytics
6. **Configure crash reporting** with Crashlytics

## Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter Firebase Plugin](https://firebase.flutter.dev/)
- [Firestore Best Practices](https://firebase.google.com/docs/firestore/best-practices)
- [Firebase Security Rules](https://firebase.google.com/docs/firestore/security/start)

## Support

For issues:
1. Check Firebase Console logs
2. Review Firestore security rules
3. Check app credentials in firebase_options.dart
4. Enable Firebase debug logging
5. Check Flutter Firebase documentation

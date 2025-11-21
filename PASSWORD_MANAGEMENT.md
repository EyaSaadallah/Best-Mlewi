# Password Management in BestMiawi

## Overview
Passwords are **NOT stored in Firestore**. Firebase Authentication is the single source of truth for all password management.

## Why This Approach?

1. **Security**: Firebase Auth uses industry-standard encryption and security practices
2. **Simplicity**: No need to sync passwords between systems
3. **Best Practice**: Never store passwords in your database - let the auth provider handle it
4. **Password Reset**: Firebase's password reset link automatically updates the password in Firebase Auth

## How It Works

### User Registration
```
1. User enters email, password, and personal info
2. Firebase Auth creates user account with email/password
3. Firestore stores user profile with EMPTY motDePasse field
4. User can now login
```

### User Login
```
1. User enters email and password
2. Firebase Auth validates credentials (NOT Firestore)
3. If valid, fetch user profile from Firestore
4. User is authenticated
```

### Password Reset (Forgot Password)
```
1. User clicks "Forgot Password?"
2. Enter email address
3. Firebase sends password reset email with link
4. User clicks link in email (external to app)
5. User enters new password on Firebase's page
   ⚠️ Firebase's reset page has NO password strength requirements
   ⚠️ You can set ANY password (e.g., "password123")
6. Firebase Auth updates password automatically
7. User can login with new password immediately
   ✓ Login only validates that password is not empty
   ✓ Firebase Auth validates the actual password
```

### Password Change (In-App)
```
1. User is logged in
2. Call: authService.updatePassword(newPassword)
3. Firebase Auth updates password
4. User remains logged in
```

## Firestore Schema

```
Collection: utilisateurs
Document fields:
  - id: int
  - nom: string
  - prenom: string
  - email: string
  - motDePasse: "" (ALWAYS EMPTY - for compatibility only)
  - telephone: string
  - dateInscription: timestamp
  - role: string (client, gerant, etc.)
```

## Important Notes

⚠️ **DO NOT:**
- Store passwords in Firestore
- Try to sync passwords between Firebase Auth and Firestore
- Compare passwords from Firestore for login
- Enforce strict password requirements on login (Firebase Auth handles it)

✅ **DO:**
- Always use Firebase Auth for password operations
- Keep `motDePasse` field empty in Firestore
- Use `FirebaseAuthService.login()` which validates via Firebase Auth
- Use `FirebaseAuthService.resetPassword()` for password recovery
- Use `FirebaseAuthService.updatePassword()` for in-app password changes
- Enforce strict password requirements ONLY on signup
- Allow ANY password on login (Firebase Auth validates it)

## API Reference

### FirebaseAuthService Methods

#### `register(email, password, nom, prenom, telephone)`
Creates new user account and Firestore profile.
- Stores empty `motDePasse` in Firestore
- Password managed by Firebase Auth

#### `login(email, password)`
Authenticates user via Firebase Auth.
- Validates credentials against Firebase Auth (NOT Firestore)
- Fetches user profile from Firestore
- Returns true if successful

#### `resetPassword(email)`
Sends password reset email.
- User clicks link in email
- Changes password on Firebase's page
- Password automatically updated in Firebase Auth

#### `updatePassword(newPassword)`
Updates password for currently logged-in user.
- Requires user to be authenticated
- Updates only in Firebase Auth
- User remains logged in

## Testing Password Reset

1. Create account via sign-up
2. Click "Forgot Password?" on login screen
3. Enter your email
4. Check your email for reset link
5. Click link and set new password
6. Return to app and login with new password
7. Should work immediately (no Firestore sync needed)

## Migration Notes

If you have existing accounts with stored passwords:
1. Set all `motDePasse` fields to empty string
2. Users can use "Forgot Password" to set new passwords
3. Or manually update passwords via Firebase Console

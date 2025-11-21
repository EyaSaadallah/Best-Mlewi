# Gerant (Super User) Setup Guide

## Overview
A **Gerant** is the super user/administrator role in BestMiawi. This guide explains how to create and manage gerant accounts.

## Quick Setup

### Method 1: Using Setup Screen (Recommended)

1. Open the app and go to the Login screen
2. Click **"Admin? Setup Gerant"** link at the bottom
3. Click **"Create Gerant Account"** button
4. Account will be created with these credentials:
   - **Email:** benjdidiaomar@gmail.com
   - **Password:** Omar1998*
   - **Name:** Omar BenJdidia
   - **Role:** Gerant

### Method 2: Manual Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: `bestmlewi-8691c`
3. Go to **Authentication** → **Users**
4. Click **Add User**
5. Enter email and password
6. Go to **Firestore** → **Collections** → **utilisateurs**
7. Add new document with:
   ```
   {
     "id": 1,
     "nom": "BenJdidia",
     "prenom": "Omar",
     "email": "benjdidiaomar@gmail.com",
     "motDePasse": "",
     "telephone": "+216",
     "dateInscription": (current timestamp),
     "role": "gerant"
   }
   ```

## Gerant Account Details

```
Name:     Omar BenJdidia
Email:    benjdidiaomar@gmail.com
Password: Omar1998*
Role:     Gerant (Super User)
```

## Login as Gerant

1. Open app and go to Login screen
2. Enter email: `benjdidiaomar@gmail.com`
3. Enter password: `Omar1998*`
4. Click **Login**
5. You'll be logged in as Gerant with full access

## Gerant Permissions

As a Gerant, you have access to:
- ✅ View all users
- ✅ View all orders
- ✅ View all menus
- ✅ Manage staff availability
- ✅ System administration features

## Creating Additional Gerants

To create more gerant accounts:

### Via Code (Programmatic)
```dart
import 'package:bestmiawi/utils/seed_data.dart';

await SeedData.createGerantAccount(
  email: 'newgerant@example.com',
  password: 'SecurePass123*',
  nom: 'LastName',
  prenom: 'FirstName',
  telephone: '+216XXXXXXXX',
);
```

### Via Firebase Console
1. Create user in Authentication
2. Create matching document in `utilisateurs` collection with `role: "gerant"`

## Password Requirements

Gerant passwords must meet these requirements:
- ✅ At least 8 characters
- ✅ At least 1 uppercase letter (A-Z)
- ✅ At least 1 lowercase letter (a-z)
- ✅ At least 1 digit (0-9)
- ✅ At least 1 special character (@$!%*?&)

**Example valid passwords:**
- `Omar1998*`
- `Admin@2024`
- `Secure$Pass123`

## Troubleshooting

### Account Already Exists
If you try to create an account that already exists:
- The system will skip creation
- You can still login with existing credentials
- To update, use Firebase Console

### Can't Login
- Check email spelling
- Verify password (case-sensitive)
- Ensure account exists in both Firebase Auth and Firestore
- Check internet connection

### Wrong Role
If account was created but role is not "gerant":
1. Go to Firebase Console
2. Find the user in `utilisateurs` collection
3. Edit the `role` field to `"gerant"`
4. Save and try logging in again

## Security Notes

⚠️ **Important:**
- Never share gerant credentials
- Change default password after first login
- Use strong, unique passwords
- Regularly audit gerant accounts
- Remove gerant access when no longer needed

## Development vs Production

### Development
- Use the Setup Screen to quickly create test accounts
- Default gerant account provided for testing

### Production
- Create gerants via Firebase Console only
- Implement proper access control
- Audit all gerant activities
- Use strong, unique passwords
- Enable 2FA if available

## Related Files

- `lib/utils/seed_data.dart` - Gerant creation utility
- `lib/screens/setup_screen.dart` - Setup UI
- `lib/models/gerant.dart` - Gerant model
- `lib/models/enums.dart` - Role enum definition

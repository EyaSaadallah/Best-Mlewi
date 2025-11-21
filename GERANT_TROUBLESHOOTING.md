# Gerant Account Creation - Troubleshooting

## Common Issues & Solutions

### Issue 1: "Email already in use"
**Error Message:** `Email already in use: benjdidiaomar@gmail.com`

**Causes:**
- Account was already created in a previous attempt
- Email exists in Firebase Authentication

**Solutions:**
1. **Option A:** Use a different email address
   - Edit `lib/screens/setup_screen.dart` line 27
   - Change email to something like `benjdidiaomar2@gmail.com`

2. **Option B:** Delete existing account from Firebase
   - Go to [Firebase Console](https://console.firebase.google.com)
   - Select project: `bestmlewi-8691c`
   - Go to **Authentication** → **Users**
   - Find and delete the user
   - Also delete from **Firestore** → **utilisateurs** collection
   - Try creating again

3. **Option C:** Use forgot password
   - Go to login screen
   - Click "Forgot Password?"
   - Enter the email
   - Reset password via email link
   - Then login with new password

---

### Issue 2: "Password is too weak"
**Error Message:** `Password is too weak. Use: uppercase, lowercase, digit, special char`

**Causes:**
- Password doesn't meet Firebase requirements
- Missing uppercase, lowercase, digit, or special character

**Solution:**
- Password must have:
  - ✅ At least 8 characters
  - ✅ At least 1 uppercase letter (A-Z)
  - ✅ At least 1 lowercase letter (a-z)
  - ✅ At least 1 digit (0-9)
  - ✅ At least 1 special character (@$!%*?&)

- Current password `Omar1998*` is valid
- If you want to change it, edit `lib/screens/setup_screen.dart` line 28

---

### Issue 3: "Failed to create Firebase Auth user"
**Error Message:** `Failed to create Firebase Auth user`

**Causes:**
- Firebase Authentication service not initialized
- Network connectivity issue
- Firebase project not configured

**Solutions:**
1. Check internet connection
2. Verify Firebase is initialized:
   - Check `lib/config/firebase_config.dart`
   - Ensure `firebase_core` is added to `pubspec.yaml`
3. Verify Firebase credentials in `lib/config/firebase_options.dart`
4. Check Firebase Console for any errors

---

### Issue 4: "Error creating gerant account: ..."
**Error Message:** Generic error with details

**Causes:**
- Firestore not accessible
- Repository error
- Unknown Firebase error

**Solutions:**
1. Check console logs for detailed error
2. Verify Firestore is enabled in Firebase Console
3. Check Firestore security rules allow writes
4. Ensure `utilisateurs` collection exists in Firestore

---

### Issue 5: Account Created but Can't Login
**Problem:** Setup says success but login fails

**Causes:**
- Account created in Firebase Auth but not in Firestore
- Role not set to "gerant"
- Email mismatch

**Solutions:**
1. Check Firebase Console:
   - **Authentication** → **Users** - should see the email
   - **Firestore** → **utilisateurs** - should see the document with `role: "gerant"`

2. If missing from Firestore:
   - Manually create document in Firestore
   - Use same email and set `role: "gerant"`

3. If role is wrong:
   - Edit the document
   - Change `role` field to `"gerant"`

---

## Debugging Steps

### Step 1: Check Console Logs
When you click "Create Gerant Account", check the console (Run → View → Debug Console) for messages like:
```
Starting gerant account creation...
✓ Gerant account created successfully!
  Email: benjdidiaomar@gmail.com
  Name: Omar BenJdidia
```

### Step 2: Check Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select project: `bestmlewi-8691c`
3. Check **Authentication** → **Users**:
   - Should see `benjdidiaomar@gmail.com`
   - Check creation date/time

4. Check **Firestore** → **utilisateurs** collection:
   - Should see document with email `benjdidiaomar@gmail.com`
   - Check `role` field is `"gerant"`
   - Check all fields are populated

### Step 3: Manual Verification
```
Expected Firestore Document:
{
  id: 1700000000000 (timestamp)
  nom: "BenJdidia"
  prenom: "Omar"
  email: "benjdidiaomar@gmail.com"
  motDePasse: "" (empty)
  telephone: "+216"
  dateInscription: (current timestamp)
  role: "gerant"
}
```

---

## Manual Account Creation (If Automated Fails)

If the setup screen doesn't work, create manually:

### Via Firebase Console:

1. **Create Auth User:**
   - Go to [Firebase Console](https://console.firebase.google.com)
   - Select `bestmlewi-8691c`
   - Go to **Authentication** → **Users**
   - Click **Add User**
   - Email: `benjdidiaomar@gmail.com`
   - Password: `Omar1998*`
   - Click **Create User**

2. **Create Firestore Document:**
   - Go to **Firestore Database**
   - Click **utilisateurs** collection
   - Click **Add Document**
   - Document ID: auto-generate
   - Add fields:
     ```
     id: 1700000000000
     nom: "BenJdidia"
     prenom: "Omar"
     email: "benjdidiaomar@gmail.com"
     motDePasse: ""
     telephone: "+216"
     dateInscription: (current timestamp)
     role: "gerant"
     ```
   - Click **Save**

3. **Test Login:**
   - Go back to app
   - Login screen
   - Email: `benjdidiaomar@gmail.com`
   - Password: `Omar1998*`
   - Should login successfully

---

## Getting Help

If you still can't create the account:

1. **Check logs:** Look at console output for specific error
2. **Verify Firebase:** Ensure project is properly configured
3. **Check permissions:** Ensure Firestore security rules allow writes
4. **Try manual creation:** Use Firebase Console directly
5. **Check network:** Ensure internet connection is stable

---

## Related Files

- `lib/utils/seed_data.dart` - Account creation logic
- `lib/screens/setup_screen.dart` - Setup UI
- `lib/config/firebase_options.dart` - Firebase credentials
- `GERANT_SETUP.md` - Setup guide

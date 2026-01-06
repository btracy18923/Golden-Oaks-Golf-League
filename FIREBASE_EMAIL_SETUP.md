# Firebase Email Extension Setup Guide

This guide walks you through setting up automatic email sending for the Golden Oaks Golf League app using Firebase Extensions and Gmail SMTP.

## Overview

- **Solution:** Firebase "Trigger Email" Extension + Gmail SMTP
- **Cost:** $0/month (completely free, no trial periods)
- **Time to Set Up:** ~40 minutes (including creating dedicated email account)
- **Emails Sent:** ~32/week (ProShop + Players + Admins)
- **Daily Limit:** 500 emails/day (you use ~5/day - plenty of headroom!)

---

## Step 1: Create Dedicated Gmail Account (Optional but Recommended) (10 minutes)

**Why create a dedicated account?**
- Professional appearance (e.g., goldenoaksgolf@gmail.com vs personal email)
- Separates league business from personal email
- Easy to share access with other league administrators
- Same free tier and limits as personal Gmail

### 1.1 Create New Gmail Account
1. Go to https://accounts.google.com/signup
2. Fill out the registration form:
   - **Name:** Golden Oaks Golf League
   - **Username:** Choose an available address like:
     - `goldenoaksgolf@gmail.com`
     - `goldenoaksgolfleague@gmail.com`
     - `goldenoaksleague@gmail.com`
   - **Password:** Strong password (save it securely!)
3. Complete phone verification
4. Skip optional recovery email (or add one)
5. Accept Terms of Service
6. **Save the email and password** - you'll need them for Step 2

### 1.2 Note Your Email Address
Write down your new email address here for reference:
```
Email: ___________________________@gmail.com
```

**If you prefer to use your personal email (btracy18923@gmail.com), skip this step and proceed to Step 2.**

---

## Step 2: Generate Gmail App Password (10 minutes)

### 2.1 Enable 2-Factor Authentication
1. Go to your Google Account: https://myaccount.google.com
2. Sign in with **your Gmail account** (the one from Step 1, or btracy18923@gmail.com if skipping Step 1)
3. Click **Security** in the left sidebar
4. Under "How you sign in to Google", find **2-Step Verification**
5. If not enabled:
   - Click **2-Step Verification**
   - Follow the setup wizard (phone verification)
   - Complete 2FA setup

### 2.2 Create App Password
1. Stay in **Security** settings
2. Under "How you sign in to Google", click **2-Step Verification**
3. Scroll to the bottom and click **App passwords**
   - If you don't see this option, ensure 2FA is fully enabled
4. Click **Select app** dropdown → Choose **Other (Custom name)**
5. Enter name: `Golden Oaks Golf App`
6. Click **Generate**
7. **IMPORTANT:** Copy the 16-character password immediately!
   - Format: `xxxx xxxx xxxx xxxx` (remove spaces when using)
   - Example: `abcd efgh ijkl mnop` becomes `abcdefghijklmnop`
8. Save it in a secure location (you'll need it in Step 3)
9. Click **Done**

**Note:** This App Password allows the golf app to send emails through your Gmail account without needing your actual Gmail password.

---

## Step 3: Install Firebase Extension (10 minutes)

### 3.1 Open Firebase Console
1. Go to https://console.firebase.google.com
2. Select your Golden Oaks Golf project
3. Click **Extensions** in the left sidebar (under "Build")

### 3.2 Install "Trigger Email" Extension
1. Click **Explore Extensions**
2. Search for "Trigger Email from Firestore"
3. Click on the extension (by Firebase)
4. Click **Install**
5. Review permissions and click **Next**

### 3.3 Configure Extension

You'll be asked several configuration questions:

**1. Cloud Firestore collection path:**
```
mail
```

**2. Email documents collection:**
```
mail
```

**3. SMTP connection URI:**
Paste your Gmail SMTP URI in this format:
```
smtps://YOUR_EMAIL@gmail.com:YOUR_APP_PASSWORD@smtp.gmail.com:465
```
Replace:
- `YOUR_EMAIL@gmail.com` with your Gmail address (from Step 1, or btracy18923@gmail.com)
- `YOUR_APP_PASSWORD` with the 16-character App Password from Step 2.2 (remove all spaces)

Example:
```
smtps://goldenoaksgolf@gmail.com:abcdefghijklmnop@smtp.gmail.com:465
```

**IMPORTANT:**
- Use **your Gmail address** (the one you set up 2FA on)
- Use the App Password WITHOUT spaces
- Use `smtp.gmail.com` as the SMTP server
- Use port `465` for secure SMTP

**4. Default FROM email address:**
```
YOUR_EMAIL@gmail.com
```
(Use the same email address from the SMTP URI above)

**5. Default REPLY-TO email address (optional):**
```
YOUR_EMAIL@gmail.com
```
(Use the same email address)

**6. Users collection (leave blank):**
```
(leave empty)
```

**7. Templates collection (leave blank):**
```
(leave empty)
```

### 3.4 Complete Installation
1. Click **Install Extension**
2. Wait 3-5 minutes for installation to complete
3. You'll see a green checkmark when done

---

## Step 4: Update Email Configuration in Flutter App (5 minutes)

**IMPORTANT:** You must update the app code to use your new email address.

### 4.1 Update Email Configuration File

Open the file `lib/config/email_config.dart` and update all email addresses to match your Gmail account:

```dart
/// Email configuration for the Golden Oaks Golf League app
class EmailConfig {
  /// ProShop email address
  static const String proShopEmail = 'YOUR_EMAIL@gmail.com';  // UPDATE THIS

  /// Administrator email addresses
  static const List<String> adminEmails = [
    'btracy18923@gmail.com',     // Keep your personal email for admin notifications
    'admin2@example.com',         // Replace with actual admin emails
    'admin3@example.com',         // Replace with actual admin emails
  ];

  /// Default fallback email (used when player has no email)
  static const String fallbackEmail = 'YOUR_EMAIL@gmail.com';  // UPDATE THIS

  /// Sender email (your Gmail account)
  static const String senderEmail = 'YOUR_EMAIL@gmail.com';  // UPDATE THIS

  /// Sender name
  static const String senderName = 'Golden Oaks Golf League';
}
```

**Example with dedicated Gmail:**
```dart
static const String proShopEmail = 'goldenoaksgolf@gmail.com';
static const String fallbackEmail = 'goldenoaksgolf@gmail.com';
static const String senderEmail = 'goldenoaksgolf@gmail.com';
```

**Example with personal Gmail:**
```dart
static const String proShopEmail = 'btracy18923@gmail.com';
static const String fallbackEmail = 'btracy18923@gmail.com';
static const String senderEmail = 'btracy18923@gmail.com';
```

---

## Step 5: Update Flutter App Dependencies (5 minutes)

### 5.1 Update pubspec.yaml

Open `pubspec.yaml` and ensure these dependencies exist:

```yaml
dependencies:
  cloud_firestore: ^5.4.4  # Already present
  firebase_core: ^3.15.2    # Already present
```

### 5.2 Install Dependencies
Run in terminal:
```bash
flutter pub get
```

---

## Step 6: Testing the Setup (15 minutes)

### 6.1 Test Email Sending (Console Test)

1. Go to Firebase Console → Firestore Database
2. Click **Start Collection**
3. Collection ID: `mail`
4. Click **Next**
5. Add a test document:
   - **Document ID:** Auto-ID
   - Add fields:
     - `to`: (array) [`YOUR_EMAIL@gmail.com`] (use your Gmail address)
     - `message`: (map)
       - `subject`: (string) `Test Email`
       - `text`: (string) `This is a test email from Firebase Extensions`

6. Click **Save**
7. Watch the document - it should update with a `delivery` field within 30 seconds
8. Check your Gmail inbox for the test email

### 6.2 Verify Extension Status

1. Go to Firebase Console → Extensions
2. Click on "Trigger Email from Firestore"
3. Click **View in Cloud Functions**
4. Check function logs for any errors
5. You should see successful execution logs

### 6.3 Troubleshooting

**If email doesn't arrive:**
- Check spam/junk folder
- Verify Gmail App Password is correct in extension config (no spaces)
- Verify 2FA is enabled on your Gmail account
- Verify you're using the correct Gmail address in the SMTP URI
- Check Firebase Functions logs for errors

**Common Issues:**
- **535 Authentication Failed:** App Password is incorrect or has spaces
- **534 Please log in via web browser:** 2FA not enabled, or using regular password instead of App Password
- **Extension not triggering:** Check Firestore collection name is exactly `mail`
- **Username/Password not accepted:** Make sure you're using the App Password, not your regular Gmail password

---

## Step 7: Flutter App Implementation (Completed)

The Flutter app code has been updated with:
- `BackendEmailService` class for sending emails via Firestore
- Updated Wednesday results screen with automatic email sending
- Updated ProShop email functionality
- Fallback to btracy18923@gmail.com for players without email addresses

**Files Modified:**
- `lib/services/backend_email_service.dart` (NEW)
- `lib/config/email_config.dart` (NEW)
- `lib/screens/wednesday/wednesday_results_screen.dart`
- `pubspec.yaml`

---

## Usage After Setup

### Sending Wednesday Results
1. User completes entering scores
2. Results screen displays
3. User clicks **"Email Results"** button
4. App automatically sends emails to:
   - ProShop (1 email)
   - All selected players (or fallback if no email)
   - All administrators (3 emails)
5. User sees success confirmation
6. No manual "Send" button needed - fully automatic!

### Sending ProShop Player List
1. User selects players
2. User clicks **"Email ProShop"** button
3. App automatically sends email to ProShop
4. User sees success confirmation

---

## Monitoring & Maintenance

### Gmail Account
- Check your Gmail "Sent" folder to see all sent emails
- Monitor for any bounce notifications
- Daily usage: ~5 emails (well under 500/day limit)

### Firebase Console
- Monitor extension function executions
- Check for errors in function logs
- View email delivery status in Firestore documents

### Monthly Costs
- **Gmail SMTP:** $0 (completely free, 500 emails/day limit)
- **Firebase Extensions:** $0 (125K function calls/month free)
- **Firestore:** $0 (writes are minimal)
- **TOTAL: $0/month**

---

## Security Notes

1. **App Password Protection:** Gmail App Password is stored securely in Firebase Extension config (not in app code)
2. **2-Factor Authentication:** Your Gmail account is protected by 2FA, and the app uses a dedicated App Password
3. **Firestore Rules:** Consider adding security rules to restrict who can write to the `mail` collection
4. **Rate Limiting:** Gmail SMTP has 500 emails/day limit (your usage is ~5/day - 100x safety margin)

### Recommended Firestore Security Rule

Add to your `firestore.rules`:

```javascript
match /mail/{document} {
  // Only authenticated users can create email documents
  allow create: if request.auth != null;
  // Nobody can read or update email documents (extension handles this)
  allow read, update, delete: if false;
}
```

---

## Next Steps

1. ✅ Complete Steps 1-3 above to create Gmail account (optional) and set up Firebase Extension
2. ✅ Update email addresses in `lib/config/email_config.dart` (Step 4)
3. ✅ Test email sending using Step 6
4. ✅ Update admin emails in `lib/config/email_config.dart` if needed
5. ✅ Deploy app and test in production
6. ✅ Monitor Gmail sent folder for first week

---

## Support

- **Gmail App Passwords Help:** https://support.google.com/accounts/answer/185833
- **Firebase Extensions Docs:** https://firebase.google.com/products/extensions/firestore-send-email
- **Extension Issues:** Check Firebase Console → Extensions → View Logs

---

## Summary

Once set up (40 minutes one-time setup):
- ✅ Fully automatic email sending via Gmail
- ✅ No manual "Send" button needed
- ✅ Free forever (500 emails/day limit, you use ~5/day)
- ✅ Professional email delivery through Google infrastructure
- ✅ Option to use dedicated league email (goldenoaksgolf@gmail.com) or personal email
- ✅ Delivery tracking via Firebase logs
- ✅ Reliable and scalable
- ✅ More generous limits than SendGrid (500/day vs 100/day)

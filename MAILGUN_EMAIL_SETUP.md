# MailGun Email Setup Guide

This guide walks you through setting up automatic email sending for the Golden Oaks Golf League app using Firebase Extensions and MailGun.

## Overview

- **Solution:** Firebase "Trigger Email" Extension + MailGun API
- **Cost:** $0/month (completely free, no trial periods)
- **Time to Set Up:** ~25 minutes
- **Emails Sent:** ~32/week (ProShop + Players + Admins)
- **Daily Limit:** 100 emails/day (you use ~5/day - 20x headroom!)
- **Advantages:** No Gmail passkeys/2FA hassle, professional delivery, API-based (not SMTP)

---

## Step 1: Create Free MailGun Account (5 minutes)

### 1.1 Sign Up for MailGun
1. Go to https://signup.mailgun.com/new/signup
2. Fill out the registration form:
   - **Email:** Your email address (btracy18923@gmail.com or any email)
   - **Password:** Create a strong password
   - **First Name:** Your name
   - **Last Name:** Your last name
   - **Company Name:** Golden Oaks Golf League
3. Click **"Create Account"**
4. Check your email for verification link
5. Click the verification link to activate your account

### 1.2 Verify Your Email
1. MailGun will send a verification email
2. Click the verification link
3. You'll be redirected to the MailGun dashboard

---

## Step 2: Get MailGun API Key and Domain (10 minutes)

### 2.1 Access MailGun Dashboard
1. Log in to https://app.mailgun.com
2. You'll see the MailGun dashboard

### 2.2 Get Your API Key
1. Click **"Settings"** in the left sidebar
2. Click **"API Keys"**
3. Find **"Private API key"** section
4. Click the **eye icon** to reveal your API key
5. **IMPORTANT:** Copy this key and save it securely!
   - Format: `key-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
   - Example: `key-1234567890abcdef1234567890abcdef`
6. You'll need this in Step 3

### 2.3 Use Sandbox Domain (Recommended for Testing)
MailGun provides a free sandbox domain for testing. This is the easiest option to start with.

1. Click **"Sending"** in the left sidebar
2. Click **"Domains"**
3. You'll see a **sandbox domain** already created:
   - Format: `sandboxXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.mailgun.org`
4. Click on the sandbox domain
5. **IMPORTANT:** Copy the domain name and save it!
6. Scroll down to **"Authorized Recipients"**
7. Click **"Add Recipient"**
8. Add these email addresses (one at a time):
   - `btracy18923@gmail.com` (your admin email)
   - Any other admin/player emails you want to test with
   - ProShop email if you have one
9. Each recipient will receive a verification email - have them click the verification link

**Note:** Sandbox domains can only send to authorized recipients. This is perfect for testing! Once you're ready for production, you can verify a custom domain (see Optional Step 2.4).

### 2.4 (Optional) Verify Custom Domain for Production
If you want to send to ANY email address (not just authorized recipients), you'll need to verify a custom domain. **Skip this for now** and use the sandbox domain for testing.

1. Click **"Add New Domain"** in the Domains section
2. Enter a domain you own (e.g., `goldenoaksgolf.com`)
3. Follow MailGun's DNS verification instructions
4. Add the required DNS records to your domain registrar
5. Wait for verification (can take up to 48 hours)

**For now, stick with the sandbox domain!**

---

## Step 3: Install Firebase MailGun Extension (5 minutes)

### 3.1 Open Firebase Console
1. Go to https://console.firebase.google.com
2. Select your Golden Oaks Golf project
3. Click **"Extensions"** in the left sidebar (under "Build")

### 3.2 Install "Trigger Email" Extension
1. Click **"Explore Extensions"**
2. Search for **"Trigger Email from Firestore"**
3. Click on the extension (by Firebase)
4. Click **"Install"**
5. Review permissions and click **"Next"**

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
This is where you use MailGun instead of Gmail!

Paste your MailGun SMTP URI in this format:
```
smtps://postmaster@YOUR_MAILGUN_DOMAIN:YOUR_MAILGUN_API_KEY@smtp.mailgun.org:465
```

Replace:
- `YOUR_MAILGUN_DOMAIN` with your sandbox domain from Step 2.3 (e.g., `sandbox123abc.mailgun.org`)
- `YOUR_MAILGUN_API_KEY` with your Private API Key from Step 2.2 (e.g., `key-1234567890abcdef`)

**Example:**
```
smtps://postmaster@sandbox123abc456def.mailgun.org:key-1234567890abcdef1234567890abcdef@smtp.mailgun.org:465
```

**IMPORTANT:**
- Use `postmaster@` as the username prefix
- Use your **Private API Key** (starts with `key-`)
- Use `smtp.mailgun.org` as the SMTP server
- Use port `465` for secure SMTP

**4. Default FROM email address:**
```
noreply@YOUR_MAILGUN_DOMAIN
```

Example: `noreply@sandbox123abc456def.mailgun.org`

**5. Default REPLY-TO email address (optional):**
```
btracy18923@gmail.com
```
(Use your personal email so recipients can reply to you)

**6. Users collection (leave blank):**
```
(leave empty)
```

**7. Templates collection (leave blank):**
```
(leave empty)
```

### 3.4 Complete Installation
1. Click **"Install Extension"**
2. Wait 3-5 minutes for installation to complete
3. You'll see a green checkmark when done

---

## Step 4: Update Email Configuration in Flutter App (2 minutes)

The Flutter app code is already set up! You just need to verify the email addresses.

### 4.1 Verify Email Configuration File

Open the file `lib/config/email_config.dart` and update if needed:

```dart
/// Email configuration for the Golden Oaks Golf League app
class EmailConfig {
  /// ProShop email address
  static const String proShopEmail = 'btracy18923@gmail.com';  // Must be authorized in MailGun sandbox

  /// Administrator email addresses
  static const List<String> adminEmails = [
    'btracy18923@gmail.com',     // Must be authorized in MailGun sandbox
    // Add other admin emails here (must be authorized in sandbox)
  ];

  /// Default fallback email (used when player has no email)
  static const String fallbackEmail = 'btracy18923@gmail.com';  // Must be authorized in MailGun sandbox

  /// Sender email (uses MailGun domain)
  static const String senderEmail = 'noreply@YOUR_MAILGUN_DOMAIN';  // UPDATE THIS!

  /// Sender name
  static const String senderName = 'Golden Oaks Golf League';
}
```

**IMPORTANT: Update `senderEmail` to match your MailGun domain:**
```dart
static const String senderEmail = 'noreply@sandbox123abc456def.mailgun.org';  // Use YOUR sandbox domain
```

**IMPORTANT: All recipient emails must be authorized in your MailGun sandbox** (from Step 2.3) until you verify a custom domain.

---

## Step 5: Testing the Setup (10 minutes)

### 5.1 Test Email Sending (Console Test)

1. Go to Firebase Console → Firestore Database
2. Click **"Start Collection"** (or add to existing collection)
3. Collection ID: `mail`
4. Click **"Next"**
5. Add a test document:
   - **Document ID:** Auto-ID
   - Add fields:
     - `to`: (array) [`btracy18923@gmail.com`] (must be authorized recipient)
     - `message`: (map)
       - `subject`: (string) `MailGun Test Email`
       - `text`: (string) `This is a test email from MailGun via Firebase Extensions`

6. Click **"Save"**
7. Watch the document - it should update with a `delivery` field within 30 seconds
8. Check your email inbox for the test email

### 5.2 Verify Extension Status

1. Go to Firebase Console → Extensions
2. Click on "Trigger Email from Firestore"
3. Click **"View in Cloud Functions"**
4. Check function logs for any errors
5. You should see successful execution logs

### 5.3 Check MailGun Logs

1. Go to MailGun Dashboard: https://app.mailgun.com
2. Click **"Sending"** → **"Logs"**
3. You should see your test email delivery
4. Check the status (should be "Delivered")

### 5.4 Troubleshooting

**If email doesn't arrive:**
- ✅ Check spam/junk folder
- ✅ Verify recipient email is authorized in MailGun sandbox (Step 2.3)
- ✅ Verify recipient clicked the authorization email from MailGun
- ✅ Verify MailGun API key is correct in extension config
- ✅ Verify MailGun domain is correct in extension config
- ✅ Check Firebase Functions logs for errors
- ✅ Check MailGun logs for delivery status

**Common Issues:**
- **"Recipient not authorized":** Add the recipient email in MailGun sandbox and verify
- **"Authentication Failed":** API key is incorrect or missing `key-` prefix
- **"550 Requested action not taken":** Sender email doesn't match MailGun domain
- **Extension not triggering:** Check Firestore collection name is exactly `mail`

---

## Step 6: Flutter App Implementation (Already Completed)

The Flutter app code has been updated with:
- `BackendEmailService` class for sending emails via Firestore
- Updated Wednesday results screen with automatic email sending
- Updated ProShop email functionality
- Fallback to btracy18923@gmail.com for players without email addresses

**Files Already Modified:**
- `lib/services/backend_email_service.dart` (NEW)
- `lib/config/email_config.dart` (NEW - just update senderEmail)
- `lib/screens/wednesday/wednesday_results_screen.dart`
- `pubspec.yaml`

**Only change needed:** Update `senderEmail` in `lib/config/email_config.dart` to match your MailGun domain!

---

## Usage After Setup

### Sending Wednesday Results
1. User completes entering scores
2. Results screen displays
3. User clicks **"Email Results"** button
4. App automatically sends emails to:
   - ProShop (1 email) - must be authorized in sandbox
   - All selected players (or fallback if no email) - must be authorized in sandbox
   - All administrators (typically 1-3 emails) - must be authorized in sandbox
5. User sees success confirmation
6. No manual "Send" button needed - fully automatic!

### Sending ProShop Player List
1. User selects players
2. User clicks **"Email ProShop"** button
3. App automatically sends email to ProShop
4. User sees success confirmation

---

## Monitoring & Maintenance

### MailGun Dashboard
- View all sent emails in **Sending → Logs**
- Monitor delivery rates
- Check for bounces or failures
- Daily usage: ~5 emails (well under 100/day limit)

### Firebase Console
- Monitor extension function executions
- Check for errors in function logs
- View email delivery status in Firestore documents

### Monthly Costs
- **MailGun Free Tier:** $0 (100 emails/day limit)
- **Firebase Extensions:** $0 (125K function calls/month free)
- **Firestore:** $0 (writes are minimal)
- **TOTAL: $0/month**

---

## Moving from Sandbox to Production (Optional - Future)

When you're ready to send emails to ANY recipient (not just authorized ones):

### Option 1: Verify a Custom Domain
1. Own a domain (e.g., `goldenoaksgolf.com`)
2. Add domain in MailGun dashboard
3. Add DNS records to your domain registrar (TXT, MX, CNAME records)
4. Wait for verification (up to 48 hours)
5. Update `senderEmail` in `lib/config/email_config.dart` to use custom domain
6. Update Firebase Extension config to use custom domain
7. No more recipient authorization needed!

### Option 2: Upgrade to MailGun Flex Plan
- **Cost:** Pay-as-you-go ($0.80 per 1,000 emails)
- **Benefit:** No sandbox restrictions, can send to any email
- **Your cost:** ~$0.004/day (5 emails/day × $0.0008/email) = **~$0.12/month**
- Still very affordable, but free tier works fine for now!

### Recommendation:
**Stick with the free sandbox tier until you need to send to more recipients.** Just authorize all league members' emails in the sandbox (they'll get a one-time verification email). This is free forever!

---

## Security Notes

1. **API Key Protection:** MailGun API key is stored securely in Firebase Extension config (not in app code)
2. **Sandbox Restrictions:** Sandbox domain only sends to authorized recipients (good for security)
3. **Firestore Rules:** Consider adding security rules to restrict who can write to the `mail` collection
4. **Rate Limiting:** MailGun has 100 emails/day limit on free tier (your usage is ~5/day - 20x safety margin)

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

1. ✅ Complete Steps 1-3 to create MailGun account and set up Firebase Extension
2. ✅ Authorize all recipient emails in MailGun sandbox (Step 2.3)
3. ✅ Update `senderEmail` in `lib/config/email_config.dart` (Step 4)
4. ✅ Test email sending using Step 5
5. ✅ Deploy app and test in production
6. ✅ Monitor MailGun logs for first week
7. ⏳ (Optional) Verify custom domain when ready to scale

---

## Support

- **MailGun Documentation:** https://documentation.mailgun.com
- **MailGun Support:** https://help.mailgun.com
- **Firebase Extensions Docs:** https://firebase.google.com/products/extensions/firestore-send-email
- **Extension Issues:** Check Firebase Console → Extensions → View Logs

---

## Comparison: MailGun vs Gmail SMTP

| Feature | MailGun | Gmail SMTP |
|---------|---------|------------|
| Setup complexity | ✅ Easy | ❌ Hard (passkey issues) |
| Free tier | 100 emails/day | 500 emails/day |
| Your usage | ~5/day (20x margin) | ~5/day (100x margin) |
| 2FA required | ❌ No | ✅ Yes |
| App Passwords | ❌ Not needed | ✅ Required |
| API-based | ✅ Yes | ❌ No (SMTP) |
| Professional logs | ✅ Yes | ⚠️ Basic |
| Deliverability | ✅ Excellent | ✅ Excellent |
| Passkey conflicts | ✅ None | ❌ Blocks setup |

**Winner: MailGun** (easier setup, no passkey issues, professional features)

---

## Summary

Once set up (25 minutes one-time setup):
- ✅ Fully automatic email sending via MailGun
- ✅ No Gmail passkey/2FA hassle
- ✅ Free forever (100 emails/day limit, you use ~5/day)
- ✅ Professional email delivery through MailGun infrastructure
- ✅ Delivery tracking via MailGun dashboard
- ✅ Reliable and scalable
- ✅ API-based (cleaner than SMTP)
- ✅ Easy to authorize recipients in sandbox
- ✅ Option to upgrade to custom domain when ready

**Total setup time: ~25 minutes (vs fighting Gmail passkeys indefinitely!)**

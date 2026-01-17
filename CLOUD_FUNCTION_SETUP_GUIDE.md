# Firebase Cloud Functions + Mailgun API Setup Guide

## Overview

This setup uses:
- **Firebase Cloud Functions** (NOT the Extension - that was causing issues)
- **Mailgun API** (NOT SMTP - like your successful Python test)
- **Mailgun Sandbox** (perfect for 35 players)
- **Cost**: $0/month forever

## Architecture

```
Flutter App → Firestore 'mail' collection → Cloud Function → Mailgun API → Email sent
```

## What We've Created

✅ `functions/` directory with Cloud Function code
✅ `functions/index.js` - Cloud Function that calls Mailgun API
✅ `functions/package.json` - Node.js dependencies
✅ `firebase.json` - Firebase configuration
✅ `.firebaserc` - Your project settings

**Your Mailgun credentials are already configured in the code!**

---

## Step 1: Install Prerequisites

### 1.1 Install Node.js (if not already installed)

Check if you have Node.js:
```bash
node --version
```

If not installed:
1. Download from https://nodejs.org
2. Install the **LTS version** (Long Term Support)
3. Restart your terminal after installation

### 1.2 Install Firebase CLI

```bash
npm install -g firebase-tools
```

Verify installation:
```bash
firebase --version
```

---

## Step 2: Deploy Cloud Function

### 2.1 Log in to Firebase

```bash
firebase login
```

This will open a browser window. Sign in with your Google account that has access to the Firebase project.

### 2.2 Install Dependencies

Navigate to the functions directory and install packages:
```bash
cd functions
npm install
cd ..
```

### 2.3 Deploy the Cloud Function

```bash
firebase deploy --only functions
```

This will:
- Upload your Cloud Function to Firebase
- Make it live and ready to process emails
- Takes about 2-3 minutes

**Expected output:**
```
✔  functions: Finished running predeploy script.
✔  functions[sendMailgunEmail(us-central1)]: Successful create operation.
✔  Deploy complete!
```

---

## Step 3: Add Authorized Recipients in Mailgun

**IMPORTANT**: Your Mailgun sandbox can only send to authorized recipients!

### 3.1 Log in to Mailgun
1. Go to https://app.mailgun.com
2. Sign in to your account

### 3.2 Add Recipients
1. Click **"Sending"** → **"Domains"**
2. Click on your sandbox domain: `sandbox1fa84ccb0aab4d71b8d6ceaeab6b71cc.mailgun.org`
3. Scroll to **"Authorized Recipients"**
4. Click **"Add Recipient"**
5. Add each league member's email (one at a time)
6. Each person will receive a verification email from Mailgun
7. They must click the verification link

**Add these emails:**
- btracy18923@gmail.com (your admin email)
- All 35 league member emails
- ProShop email if you have one

---

## Step 4: Test Email Sending

### 4.1 Test via Firebase Console

1. Go to https://console.firebase.google.com
2. Select your project: **golf-league-b0bb2**
3. Click **Firestore Database** in left sidebar
4. Click **"Start collection"** (or add to existing)
5. Collection ID: **mail**
6. Click **"Next"**
7. Create a test document:
   - **Document ID**: Auto-ID
   - Add fields:
     ```
     to: (array)
       - btracy18923@gmail.com

     message: (map)
       subject: (string) "Test Email from Cloud Function"
       text: (string) "This is a test email using Mailgun API via Firebase Cloud Functions!"
     ```
8. Click **"Save"**

### 4.2 Watch for Success

Within 10-30 seconds:
1. The Firestore document will update with a `delivery` field
2. Check the `delivery.state` field - should be **"SUCCESS"**
3. Check your email inbox (btracy18923@gmail.com)
4. You should receive the test email!

### 4.3 Check Logs (if something goes wrong)

View Cloud Function logs:
```bash
firebase functions:log
```

Or in Firebase Console:
1. Go to **Functions** section
2. Click on **sendMailgunEmail**
3. Click **"Logs"** tab
4. Look for errors or success messages

---

## Step 5: Update Your Flutter App (if needed)

Check if you have `lib/services/backend_email_service.dart` and `lib/config/email_config.dart`.

If YES, you're already set up! The app should work as-is.

If NO, let me know and I'll create these files for you.

---

## How It Works

### From Your Flutter App:

```dart
// Example: Send email
await FirebaseFirestore.instance.collection('mail').add({
  'to': ['player@example.com'],
  'message': {
    'subject': 'Wednesday Results',
    'text': 'Here are the results...',
    'html': '<h1>Results</h1><p>Here are the results...</p>',
  },
  'from': 'Golden Oaks Golf League <noreply@sandbox1fa84ccb0aab4d71b8d6ceaeab6b71cc.mailgun.org>',
  'replyTo': 'btracy18923@gmail.com',
});
```

### What Happens:

1. ✅ Flutter app writes document to `mail` collection
2. ✅ Cloud Function automatically triggered
3. ✅ Function calls Mailgun API (like your Python script!)
4. ✅ Mailgun sends email
5. ✅ Function updates document with delivery status
6. ✅ Done!

---

## Troubleshooting

### Email Not Received

**Check 1: Is recipient authorized in Mailgun?**
- Log in to Mailgun → Sending → Domains → Sandbox
- Verify the recipient email is in "Authorized Recipients"
- Verify they clicked the confirmation email from Mailgun

**Check 2: Check Cloud Function logs**
```bash
firebase functions:log
```

Look for:
- ✅ "Email sent successfully" = Good!
- ❌ "Mailgun API error" = Check error message
- ❌ "Missing required fields" = Check document structure

**Check 3: Check Mailgun logs**
- Go to https://app.mailgun.com
- Click **Sending** → **Logs**
- Find your email and check delivery status

### Common Errors

**"Recipient not authorized"**
- Solution: Add recipient in Mailgun sandbox and have them verify

**"Invalid API key"**
- Solution: Verify API key in `functions/index.js` matches your Mailgun key

**"Domain not found"**
- Solution: Verify domain in `functions/index.js` matches your sandbox domain

**Function not triggering**
- Solution: Verify collection name is exactly `mail` (lowercase)

---

## Monitoring & Usage

### Daily Usage Estimate
- Monday league: ~2-3 emails/week
- Wednesday league: ~2-3 emails/week
- ProShop emails: ~1-2 emails/week
- **Total: ~5-8 emails/week** (well under limits!)

### Mailgun Limits (Sandbox)
- 100 emails/day
- Unlimited authorized recipients (your 35 players)
- Free forever

### Firebase Limits (Free Tier)
- 125,000 function invocations/month
- 40 GB network egress/month
- Your usage: ~35 invocations/month (way under limit!)

### Costs
- **Mailgun**: $0/month
- **Firebase Functions**: $0/month
- **Firestore**: $0/month
- **TOTAL: $0/month** 🎉

---

## Advantages Over Firebase Extension + SMTP

| Feature | Cloud Function + API | Extension + SMTP |
|---------|---------------------|------------------|
| Setup complexity | ✅ Easy | ❌ SMTP issues |
| Uses Mailgun API | ✅ Yes (like Python) | ❌ No (uses SMTP) |
| Your test worked | ✅ Yes | ❌ No |
| Debugging | ✅ Easy (function logs) | ⚠️ Harder |
| Control | ✅ Full control | ⚠️ Limited |
| Cost | ✅ Free | ✅ Free |

---

## Security Notes

### ⚠️ API Key in Code

**Current setup**: API key is hardcoded in `functions/index.js`

**For production, move to environment config**:

1. Remove API key from code
2. Set as environment variable:
```bash
firebase functions:config:set mailgun.api_key="your-api-key"
firebase functions:config:set mailgun.domain="your-domain"
```

3. Update `functions/index.js`:
```javascript
const MAILGUN_API_KEY = functions.config().mailgun.api_key;
const MAILGUN_DOMAIN = functions.config().mailgun.domain;
```

4. Redeploy:
```bash
firebase deploy --only functions
```

**For now, the hardcoded key is fine** since:
- It's only in the Cloud Function (not in Flutter app)
- Cloud Function code is not accessible to users
- Mailgun sandbox is restricted to authorized recipients anyway

---

## Next Steps

1. ✅ Install Node.js and Firebase CLI (Step 1)
2. ✅ Deploy Cloud Function (Step 2)
3. ✅ Add all 35 league members as authorized recipients in Mailgun (Step 3)
4. ✅ Test email sending (Step 4)
5. ✅ Verify Flutter app has email service code (Step 5)
6. ✅ Test from Flutter app
7. ✅ Deploy to tablets and enjoy automatic emails!

---

## Support

- **Firebase Functions Docs**: https://firebase.google.com/docs/functions
- **Mailgun API Docs**: https://documentation.mailgun.com/en/latest/api-intro.html
- **View Function Logs**: `firebase functions:log`
- **View Firebase Console**: https://console.firebase.google.com

---

## Summary

✅ **Cloud Function created** - Uses Mailgun API like your Python test
✅ **Mailgun configured** - Your API key and sandbox domain already set
✅ **Cost: $0/month** - Free tier covers your usage
✅ **Perfect for 35 players** - Sandbox supports all your recipients
✅ **Automatic emails** - Triggered by Firestore writes
✅ **Easy debugging** - Function logs show everything

**Ready to deploy!** Follow Steps 1-2 above to go live.

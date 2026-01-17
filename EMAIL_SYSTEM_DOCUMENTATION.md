# Golden Oaks Golf League - Email System Documentation

**Last Updated:** January 6, 2026
**Status:** Production Ready ✅

---

## Overview

The Golden Oaks Golf League app uses a fully automatic email system powered by:
- **Firebase Cloud Functions** - Server-side email processing
- **Mailgun API** - Professional email delivery service
- **Custom Domain** - Emails sent from `noreply@goldenoaks.golf`
- **Cloudflare DNS** - Domain name system management

**Key Feature:** Emails are sent automatically from the app with zero user interaction required!

---

## How It Works

### Architecture Flow

```
Flutter App → Firestore 'mail' Collection → Cloud Function → Mailgun API → Email Delivered
```

### Step-by-Step Process

1. **User completes action in app** (enters scores, selects players, etc.)
2. **App writes email data to Firestore** `mail` collection
3. **Cloud Function automatically triggered** by new Firestore document
4. **Cloud Function calls Mailgun API** to send email
5. **Mailgun delivers email** to recipients
6. **Cloud Function updates Firestore** with delivery status
7. **Done!** Recipients receive email in their inbox

**Time from app to inbox:** 10-30 seconds

---

## System Components

### 1. Flutter App (Client-Side)

**Location:** `lib/services/backend_email_service.dart`

**Purpose:** Creates email documents in Firestore

**Key Methods:**
- `sendWednesdayResultsEmail()` - Sends league results to players/admins
- `sendProShopEmail()` - Sends player lists to ProShop
- `sendCustomEmail()` - Sends custom emails to specified recipients

**Configuration:** `lib/config/email_config.dart`
- Sender email: `noreply@goldenoaks.golf`
- ProShop email: `btracy18923@gmail.com`
- Admin emails: List of administrator addresses
- Fallback email: Used when player has no email address

### 2. Firebase Cloud Function (Server-Side)

**Location:** `functions/index.js`

**Purpose:** Processes email documents and sends via Mailgun API

**Trigger:** Firestore document creation in `mail` collection

**What it does:**
1. Validates email document structure
2. Extracts recipient addresses, subject, body
3. Calls Mailgun API with email data
4. Updates document with delivery status (SUCCESS or ERROR)

**Environment:**
- Node.js 20
- Firebase Functions (1st Gen)
- Region: us-central1

### 3. Mailgun (Email Service)

**Domain:** `goldenoaks.golf`
**API Key:** Configured in `functions/index.js`
**Region:** US

**Features:**
- Professional email delivery
- SPF and DKIM authentication
- Delivery tracking and logs
- Free tier: 1,000 emails/month

**Dashboard:** https://app.mailgun.com
- View sent emails
- Check delivery status
- Monitor bounce rates
- View error logs

### 4. Cloudflare (DNS Management)

**Domain:** `goldenoaks.golf`
**Nameservers:** clayton.ns.cloudflare.com, meera.ns.cloudflare.com

**DNS Records:**
- A record: `@` → `75.2.60.5` (Netlify website)
- CNAME: `www` → `goldenoaks.netlify.app`
- TXT: `@` → SPF record for Mailgun
- TXT: `mailo._domainkey` → DKIM record for Mailgun
- CNAME: `email` → `mailgun.org`
- MX: `@` → `mxb.mailgun.org` (optional)
- TXT: `_dmarc` → DMARC record

**Dashboard:** https://dash.cloudflare.com

---

## Usage in Flutter App

### Sending Wednesday Results

```dart
import 'package:golf_app_v4/services/backend_email_service.dart';

final emailService = BackendEmailService();

// Send results email
await emailService.sendWednesdayResultsEmail(
  subject: 'Wednesday League Results - ${DateTime.now()}',
  body: resultsText,
  playerEmails: ['player1@example.com', 'player2@example.com'],
);
```

**What happens:**
- Email sent to ProShop
- Email sent to all player addresses (or fallback if no email)
- Email sent to all administrators
- Duplicates automatically removed
- Fully automatic - no user interaction needed

### Sending ProShop Player List

```dart
final emailService = BackendEmailService();

// Send player list to ProShop
await emailService.sendProShopEmail(
  subject: 'Player List - ${DateTime.now()}',
  body: playerListText,
);
```

**What happens:**
- Email sent to ProShop email address
- Optional: Can specify different recipient email

### Sending Custom Email

```dart
final emailService = BackendEmailService();

// Send custom email
await emailService.sendCustomEmail(
  to: ['recipient1@example.com', 'recipient2@example.com'],
  subject: 'Custom Subject',
  body: 'Plain text body',
  htmlBody: '<h1>HTML body</h1><p>Optional HTML version</p>',
);
```

---

## Email Document Structure

When the Flutter app creates a Firestore document, it has this structure:

```javascript
{
  // Required fields
  to: ['email1@example.com', 'email2@example.com'],  // Array of recipient emails
  message: {
    subject: 'Email Subject',  // Email subject line
    text: 'Plain text body',   // Plain text version (required)
    html: '<p>HTML body</p>'   // HTML version (optional)
  },

  // Optional fields
  from: 'Golden Oaks Golf League <noreply@goldenoaks.golf>',
  replyTo: 'btracy18923@gmail.com',

  // Metadata (automatically added)
  createdAt: Timestamp,
  type: 'wednesday_results' | 'proshop_players' | 'custom',

  // Delivery status (added by Cloud Function)
  delivery: {
    state: 'SUCCESS' | 'ERROR',
    startTime: Timestamp,
    endTime: Timestamp,
    info: {
      messageId: '<mailgun-message-id>',
      response: 'Queued. Thank you.'
    },
    error: 'Error message if failed'
  }
}
```

---

## Configuration Files

### Email Configuration

**File:** `lib/config/email_config.dart`

```dart
class EmailConfig {
  // ProShop email address
  static const String proShopEmail = 'btracy18923@gmail.com';

  // Administrator email addresses
  static const List<String> adminEmails = [
    'btracy18923@gmail.com',
  ];

  // Default fallback email (used when player has no email)
  static const String fallbackEmail = 'btracy18923@gmail.com';

  // Sender email (custom domain)
  static const String senderEmail = 'noreply@goldenoaks.golf';

  // Sender name
  static const String senderName = 'Golden Oaks Golf League';
}
```

**To Update:**
1. Change email addresses as needed
2. Hot restart Flutter app (no rebuild needed)

### Cloud Function Configuration

**File:** `functions/index.js`

**Mailgun Settings:**
```javascript
const MAILGUN_API_KEY = 'your-api-key-here';
const MAILGUN_DOMAIN = 'goldenoaks.golf';
```

**To Update:**
1. Edit `functions/index.js`
2. Redeploy: `firebase deploy --only functions`

---

## Deployment

### Deploy Cloud Function

```bash
# Navigate to project directory
cd C:\Users\Acer\AndroidStudioProjects\golf_app_v4

# Deploy Cloud Function
firebase deploy --only functions
```

**Expected output:**
```
✔  functions[sendMailgunEmail(us-central1)]: Successful update operation.
✔  Deploy complete!
```

### Deploy Flutter App

```bash
# Build Android APK
flutter build apk --release

# Or build App Bundle
flutter build appbundle --release
```

Then install APK on tablets or upload App Bundle to Google Play.

---

## Monitoring & Troubleshooting

### Check Email Delivery Status

#### Method 1: Firestore Console

1. Go to https://console.firebase.google.com/project/golf-league-b0bb2/firestore
2. Open `mail` collection
3. Click on email document
4. Check `delivery.state` field:
   - ✅ `SUCCESS` - Email sent successfully
   - ❌ `ERROR` - Email failed (check `delivery.error` field)

#### Method 2: Mailgun Dashboard

1. Go to https://app.mailgun.com
2. Click **"Sending"** → **"Logs"**
3. View all sent emails
4. Check delivery status, opens, clicks, bounces

#### Method 3: Cloud Function Logs

```bash
# View logs in terminal
firebase functions:log
```

Or in Firebase Console:
1. Go to https://console.firebase.google.com
2. Select project **golf-league-b0bb2**
3. Click **"Functions"** in left sidebar
4. Click **sendMailgunEmail**
5. Click **"Logs"** tab

### Common Issues

#### Issue: Email Not Sending

**Symptoms:** Firestore document shows no `delivery` field

**Causes:**
1. Cloud Function not deployed
2. Cloud Function error (check logs)
3. Firestore collection name wrong (must be `mail`)

**Solutions:**
1. Deploy Cloud Function: `firebase deploy --only functions`
2. Check logs: `firebase functions:log`
3. Verify collection name is exactly `mail` (lowercase)

#### Issue: Email Shows ERROR Status

**Symptoms:** `delivery.state = 'ERROR'`

**Causes:**
1. Invalid recipient email address
2. Mailgun API key incorrect
3. Domain not verified in Mailgun
4. Missing required fields (to, subject, text)

**Solutions:**
1. Check `delivery.error` field for specific error message
2. Verify Mailgun API key in `functions/index.js`
3. Verify domain in Mailgun dashboard
4. Check email document has all required fields

#### Issue: Email Goes to Spam

**Symptoms:** Email delivered but in spam folder

**Causes:**
1. SPF/DKIM not verified
2. Domain reputation low (new domain)
3. Email content triggers spam filters

**Solutions:**
1. Verify SPF and DKIM in Mailgun dashboard
2. Wait 24-48 hours for domain reputation to build
3. Have recipients mark as "Not Spam" to train filters
4. Avoid spam trigger words in subject/body

#### Issue: Cloud Function Timeout

**Symptoms:** Function logs show timeout error

**Causes:**
1. Mailgun API slow to respond
2. Network issues

**Solutions:**
1. Check Mailgun status: https://status.mailgun.com
2. Retry sending email (create new document)
3. Check Cloud Function timeout setting (default: 60 seconds)

---

## Cost & Usage Limits

### Current Usage (Estimated)

- **Monday League:** ~5 emails/week
- **Wednesday League:** ~35 emails/week
- **ProShop:** ~2 emails/week
- **Total:** ~42 emails/week = ~180 emails/month

### Free Tier Limits

**Mailgun:**
- Limit: 1,000 emails/month
- Usage: ~180/month
- Headroom: **5.5x**
- Cost: **$0/month**

**Firebase Cloud Functions:**
- Limit: 125,000 invocations/month
- Usage: ~180 invocations/month
- Headroom: **694x**
- Cost: **$0/month**

**Firebase Firestore:**
- Limit: 50,000 reads/day, 20,000 writes/day
- Usage: ~180 writes/month
- Headroom: **Massive**
- Cost: **$0/month**

**Cloudflare DNS:**
- Limit: Unlimited DNS queries
- Cost: **$0/month**

**Domain Registration:**
- Cost: Already owned
- Renewal: ~$20-40/year (varies by registrar)

**Total Monthly Cost: $0** 🎉

---

## Maintenance

### Regular Tasks

#### Weekly (Optional)
- Check Mailgun dashboard for bounce rates
- Monitor delivery success rate

#### Monthly
- Review Mailgun logs for any issues
- Check usage is within free tier limits

#### Yearly
- Renew domain registration (goldenoaks.golf)
- Review and update admin email addresses if needed

### Updates & Changes

#### Update Recipient Email Addresses

**File:** `lib/config/email_config.dart`

1. Edit email addresses
2. Save file
3. Hot restart Flutter app (Command+R or Ctrl+R)
4. No rebuild or redeployment needed!

#### Update Email Templates

**Files:**
- `lib/screens/wednesday/wednesday_results_screen.dart`
- `lib/screens/monday/monday_results_screen.dart`

1. Edit email body generation code
2. Save file
3. Hot restart Flutter app
4. Test by sending email

#### Update Mailgun API Key

**File:** `functions/index.js`

1. Edit `MAILGUN_API_KEY` constant
2. Save file
3. Redeploy: `firebase deploy --only functions`
4. Wait 2-3 minutes for deployment
5. Test by sending email

#### Update Sender Domain

**Files:**
- `functions/index.js` - Update `MAILGUN_DOMAIN`
- `lib/config/email_config.dart` - Update `senderEmail`

**Steps:**
1. Add new domain to Mailgun
2. Configure DNS records in Cloudflare
3. Verify domain in Mailgun
4. Update both files above
5. Redeploy Cloud Function
6. Hot restart Flutter app
7. Test by sending email

---

## Security & Best Practices

### API Key Security

**Current Setup:**
- Mailgun API key is hardcoded in `functions/index.js`
- This is acceptable because:
  - Cloud Function code is not accessible to users
  - Cloud Function runs server-side only
  - API key never exposed to client/tablets

**Better Setup (Optional):**

Move API key to environment variables:

```bash
# Set environment variables
firebase functions:config:set mailgun.api_key="your-key"
firebase functions:config:set mailgun.domain="goldenoaks.golf"

# Deploy
firebase deploy --only functions
```

Update `functions/index.js`:
```javascript
const MAILGUN_API_KEY = functions.config().mailgun.api_key;
const MAILGUN_DOMAIN = functions.config().mailgun.domain;
```

### Email Validation

The Cloud Function validates:
- ✅ Required fields present (to, message, subject, text)
- ✅ Email addresses in array format
- ✅ Subject and body are not empty

**No additional validation needed** - Mailgun handles email address validation.

### Rate Limiting

**Mailgun Limits:**
- Free tier: 1,000 emails/month
- No hourly/daily limits
- No rate limiting on free tier

**Firebase Limits:**
- Cloud Functions: 125,000 invocations/month
- No rate limiting needed for your usage

**App-Level Protection:**
- No duplicate emails sent (handled by Flutter app logic)
- Emails only sent on user actions (scores entered, etc.)
- No automated/scheduled emails

---

## Testing

### Test Email Sending

#### Method 1: Via Firestore Console (Quick Test)

1. Go to https://console.firebase.google.com/project/golf-league-b0bb2/firestore
2. Open `mail` collection
3. Click **"Add document"**
4. Use Auto-ID
5. Add fields:
   ```
   to: (array) ["your-email@example.com"]
   message: (map)
     subject: (string) "Test Email"
     text: (string) "This is a test email"
   ```
6. Click **"Save"**
7. Wait 10-30 seconds
8. Check email inbox
9. Verify document shows `delivery.state = 'SUCCESS'`

#### Method 2: Via Flutter App (Production Test)

1. Open app on tablet/emulator
2. Complete Wednesday/Monday league scores
3. Click email button
4. Check recipient inbox
5. Verify email received

#### Method 3: Via Cloud Function Logs

```bash
# Send test email via Firestore Console
# Then check logs:
firebase functions:log

# Look for:
# - "Processing email document: [ID]"
# - "Email sent successfully"
# - "Email document [ID] updated with delivery status"
```

### Verify Domain Configuration

#### Check DNS Records

1. Go to https://dnschecker.org
2. Enter domain: `goldenoaks.golf`
3. Check each record type:
   - **A record**: Should show `75.2.60.5`
   - **TXT record**: Should show SPF and DKIM
   - **CNAME record** (email.goldenoaks.golf): Should show `mailgun.org`

#### Check Mailgun Verification

1. Go to https://app.mailgun.com
2. Click **"Sending"** → **"Domains"**
3. Click **goldenoaks.golf**
4. Verify status:
   - ✅ SPF: Verified
   - ✅ DKIM: Verified
   - ✅ DMARC: Verified (optional)

---

## Support & Resources

### Dashboards

- **Firebase Console:** https://console.firebase.google.com/project/golf-league-b0bb2
- **Mailgun Dashboard:** https://app.mailgun.com
- **Cloudflare Dashboard:** https://dash.cloudflare.com

### Documentation

- **Mailgun API:** https://documentation.mailgun.com
- **Firebase Functions:** https://firebase.google.com/docs/functions
- **Flutter Cloud Firestore:** https://firebase.flutter.dev/docs/firestore/usage

### Command Line Tools

```bash
# Firebase CLI
firebase login               # Login to Firebase
firebase deploy --only functions  # Deploy Cloud Functions
firebase functions:log       # View function logs

# Flutter
flutter pub get             # Install dependencies
flutter run                 # Run app
flutter build apk           # Build APK

# Node.js (for Cloud Functions)
cd functions
npm install                 # Install dependencies
```

---

## Changelog

### January 6, 2026 - Production Launch
- ✅ Deployed Firebase Cloud Function with Mailgun API
- ✅ Verified custom domain: goldenoaks.golf
- ✅ Configured Cloudflare DNS
- ✅ Updated Flutter app to use automatic email
- ✅ Tested email delivery successfully
- ✅ System operational and ready for production use

### Previous Attempts (Deprecated)
- ❌ Firebase Extension + SMTP (had authentication issues)
- ❌ Gmail SMTP (passkey conflicts)
- ❌ Mailgun sandbox (emails went to spam)

### Current Solution
- ✅ Firebase Cloud Functions + Mailgun API + Custom Domain
- ✅ Professional email delivery
- ✅ Inbox delivery (not spam)
- ✅ Fully automatic
- ✅ Cost: $0/month

---

## Quick Reference

### Send Email from Flutter

```dart
import 'package:golf_app_v4/services/backend_email_service.dart';

final emailService = BackendEmailService();

// Wednesday results
await emailService.sendWednesdayResultsEmail(
  subject: 'Results',
  body: 'Body text',
  playerEmails: ['email@example.com'],
);

// ProShop
await emailService.sendProShopEmail(
  subject: 'Subject',
  body: 'Body text',
);
```

### Deploy Cloud Function

```bash
firebase deploy --only functions
```

### Check Logs

```bash
firebase functions:log
```

### Check Email Status

1. Firestore Console → `mail` collection → Document → `delivery.state`
2. Mailgun Dashboard → Sending → Logs

---

## Contact & Support

**Project Owner:** btracy18923@gmail.com
**Domain:** goldenoaks.golf
**Firebase Project:** golf-league-b0bb2

**For Issues:**
1. Check logs: `firebase functions:log`
2. Check Mailgun dashboard: https://app.mailgun.com
3. Check Firestore documents for error messages
4. Review this documentation

---

**Last Updated:** January 6, 2026
**Status:** ✅ Production Ready
**Version:** 1.0

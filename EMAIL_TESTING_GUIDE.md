# Email Testing Guide

This guide helps you test the automatic email functionality after setting up the Firebase Extension.

## Prerequisites

Before testing, ensure you have completed:
1. ✅ SendGrid account created and sender email verified
2. ✅ Firebase "Trigger Email" Extension installed and configured
3. ✅ Flutter app updated with latest code changes
4. ✅ `flutter pub get` run to install dependencies

---

## Test 1: Manual Firestore Test (Console)

**Purpose:** Verify Firebase Extension is working before testing from the app.

### Steps:

1. **Open Firebase Console**
   - Go to https://console.firebase.google.com
   - Select your Golden Oaks Golf project
   - Click **Firestore Database** in left sidebar

2. **Create Test Email Document**
   - Click **Start Collection** (or add to existing `mail` collection)
   - Collection ID: `mail`
   - Click **Next**

3. **Add Test Document Fields**
   - Document ID: Leave as **Auto-ID**
   - Add the following fields:

   ```
   Field: to
   Type: array
   Value: ["btracy18923@gmail.com"]

   Field: from
   Type: string
   Value: "btracy18923@gmail.com"

   Field: message
   Type: map
   └─ subject (string): "Test Email from Firebase Extension"
   └─ text (string): "This is a test email to verify the Firebase Extension is working correctly."

   Field: createdAt
   Type: timestamp
   Value: (current time)

   Field: type
   Type: string
   Value: "test"
   ```

4. **Click Save**

5. **Watch the Document**
   - The document should update within 30 seconds
   - You should see a new `delivery` field appear
   - `delivery.state` should show `"SUCCESS"`

6. **Check Email Inbox**
   - Open btracy18923@gmail.com inbox
   - Look for test email (check spam folder if not in inbox)
   - Subject should be "Test Email from Firebase Extension"

### Expected Results:
- ✅ Document in Firestore shows `delivery.state: "SUCCESS"`
- ✅ Email received in inbox within 1 minute
- ✅ Email sent from btracy18923@gmail.com

### Troubleshooting:
- **No delivery field appears:** Check Firebase Functions logs for errors
- **delivery.state is ERROR:** Check SendGrid API key in extension config
- **Email not received:** Check spam folder, verify sender email in SendGrid

---

## Test 2: ProShop Email (From App)

**Purpose:** Test automatic email sending from Wednesday Enter Scores screen.

### Steps:

1. **Run the App**
   ```bash
   flutter run
   ```

2. **Navigate to Wednesday League**
   - From main menu, select **Wednesday**
   - Tap **Enter Scores**

3. **Select Players**
   - Add at least 4-8 players to groups
   - Verify players are organized correctly

4. **Send ProShop Email**
   - Tap **Email ProShop** button
   - Wait for confirmation message

5. **Verify Success Message**
   - Should see green snackbar: "Player list emailed successfully to ProShop!"
   - If error, see troubleshooting below

6. **Check Firestore (Optional)**
   - Open Firebase Console → Firestore → `mail` collection
   - Find newest document (type: "proshop_players")
   - Verify `delivery.state: "SUCCESS"`

7. **Check Email Inbox**
   - Open btracy18923@gmail.com inbox
   - Look for email with subject: "Golden Oaks Wed. Players - [DATE]"
   - Verify email contains:
     - Player names grouped correctly
     - Player numbers formatted as 0001, 0002, etc.
     - Total player count
     - Generated timestamp

### Expected Results:
- ✅ Button tap shows success message
- ✅ Email received within 1 minute
- ✅ Email contains all selected players
- ✅ Players organized by groups

### Troubleshooting:
- **Red error message:** Check Firebase console logs
- **No email received:** Check Firestore `mail` collection for delivery status
- **Wrong email content:** Review player selection in app

---

## Test 3: Wednesday Results Email (From App)

**Purpose:** Test automatic email sending from Wednesday Results screen.

### Steps:

1. **Complete a Full Wednesday Workflow**
   - Select players (minimum 8 for testing)
   - Enter scores for all players
   - Tap **Calculate** to generate results
   - Navigate to Results screen

2. **Review Results**
   - Verify all data displays correctly:
     - League setup (ante, closest pin, mulligans)
     - Individual winners
     - Group winners
     - Consolidated payout table

3. **Send Results Email**
   - Tap **Email Results** button (blue button)
   - Button should show "Sending..." briefly
   - Wait for confirmation message

4. **Verify Success Message**
   - Should see green snackbar: "Results emailed successfully to ProShop and administrators!"
   - If error, see troubleshooting below

5. **Check Email Inbox**
   - Open btracy18923@gmail.com inbox
   - Look for email with subject: "Wednesday League Results - [DATE]"
   - Verify email contains:
     - Date and golf course
     - League setup details
     - Closest pin winners (if any)
     - Individual winners and amounts
     - Group winners and amounts
     - Consolidated payout table
     - Generated timestamp

### Expected Results:
- ✅ Button shows "Sending..." then returns to "Email Results"
- ✅ Success message appears
- ✅ Email received within 1 minute
- ✅ Email contains complete results data
- ✅ All dollar amounts are correct
- ✅ Email sent to ProShop + 3 admins (currently all btracy18923@gmail.com)

### Troubleshooting:
- **Button stays disabled:** Check for JavaScript errors in console
- **Red error message:** Check Firebase Firestore permissions
- **Email missing data:** Review results screen display

---

## Test 4: Multiple Recipients

**Purpose:** Verify emails are sent to all configured recipients.

### Prerequisites:
- Update admin emails in `lib/config/email_config.dart` if different emails available

### Steps:

1. **Open Email Config**
   ```dart
   // lib/config/email_config.dart
   static const List<String> adminEmails = [
     'admin1@example.com',  // Replace with real email for testing
     'admin2@example.com',  // Replace with real email for testing
     'admin3@example.com',  // Replace with real email for testing
   ];
   ```

2. **Update Emails** (optional)
   - Replace with actual test email addresses
   - Save file
   - Re-run app: `flutter run`

3. **Send Results Email**
   - Complete Test 3 steps above
   - Tap **Email Results**

4. **Verify All Recipients Received Email**
   - Check ProShop inbox: btracy18923@gmail.com
   - Check all admin inboxes
   - All should receive identical email

### Expected Results:
- ✅ ProShop email received
- ✅ All 3 admin emails received
- ✅ All emails have identical content
- ✅ Total of 4 emails sent per results email

---

## Test 5: Error Handling

**Purpose:** Verify app handles email failures gracefully.

### Test 5a: No Internet Connection

1. **Disable Device Internet**
   - Turn off WiFi and mobile data on test device
   - Or use airplane mode

2. **Try Sending Email**
   - Tap **Email Results** or **Email ProShop**
   - App should show error message

3. **Expected Result:**
   - ❌ Red snackbar: "Failed to send email" or "Error sending email"
   - ✅ App doesn't crash
   - ✅ User can retry after restoring connection

### Test 5b: Invalid SendGrid API Key

1. **Temporarily Break Configuration**
   - Go to Firebase Console → Extensions
   - Edit "Trigger Email" extension config
   - Change SMTP URI to invalid value
   - Redeploy extension

2. **Try Sending Email**
   - From app, tap email button
   - Wait for response

3. **Expected Result:**
   - ✅ Email document created in Firestore
   - ❌ delivery.state shows "ERROR"
   - ✅ Error details in delivery.error field

4. **Restore Configuration**
   - Fix SMTP URI in extension config
   - Redeploy extension

---

## Monitoring & Logs

### Viewing Firebase Logs

1. **Go to Firebase Console**
2. **Click Functions** in left sidebar
3. **Click on function name** (ext-firestore-send-email-processQueue)
4. **Click Logs tab**
5. **View execution logs:**
   - Successful sends: "Successfully sent email..."
   - Errors: Stack traces and error messages

### Viewing SendGrid Dashboard

1. **Log in to SendGrid**
2. **Go to Activity** in left sidebar
3. **View email activity:**
   - Sent emails
   - Delivery status
   - Bounce/spam reports
4. **Filters:**
   - Filter by date
   - Filter by recipient
   - Filter by subject

### Checking Firestore Documents

1. **Go to Firestore Database**
2. **Open `mail` collection**
3. **Click on any document**
4. **Review fields:**
   - `to`: Recipients list
   - `from`: Sender
   - `message`: Email content
   - `delivery.state`: SUCCESS or ERROR
   - `delivery.error`: Error details if failed
   - `delivery.info`: Delivery information

---

## Common Issues & Solutions

### Issue: Email not received

**Possible Causes:**
- Spam folder
- SendGrid sender not verified
- Invalid recipient email
- SendGrid daily limit exceeded (100/day for free tier)

**Solutions:**
1. Check spam/junk folder
2. Verify sender in SendGrid dashboard
3. Check Firestore delivery status
4. Check SendGrid activity dashboard

### Issue: "Failed to send email" error

**Possible Causes:**
- No internet connection
- Firebase not initialized
- Firestore permissions issue

**Solutions:**
1. Check device internet connection
2. Verify Firebase is initialized in app
3. Check Firestore security rules
4. Review Firebase console for errors

### Issue: Email sent but content is wrong

**Possible Causes:**
- Bug in email body building logic
- Data not passed correctly to service

**Solutions:**
1. Review results screen data display
2. Check debug logs for email body content
3. Verify all data fields are populated

### Issue: Emails sent to wrong recipients

**Possible Causes:**
- Incorrect configuration in email_config.dart
- Player emails not set up

**Solutions:**
1. Review `lib/config/email_config.dart`
2. Update admin email addresses
3. Verify ProShop email is correct

---

## Performance Metrics

### Expected Performance:
- **Email Creation:** < 1 second
- **Email Delivery:** 5-30 seconds
- **Total Time:** < 1 minute from button tap to inbox

### Monitoring:
- Firebase Functions dashboard shows execution times
- SendGrid activity shows delivery times
- Firestore timestamps show processing duration

---

## Daily Usage Limits

### SendGrid Free Tier:
- **100 emails/day**
- Your usage: ~32 emails/week (ProShop + players + admins)
- **Daily average: ~5 emails**
- ✅ Well within free tier limits

### Firebase Free Tier:
- **125,000 function invocations/month**
- Your usage: ~139 invocations/month
- ✅ Well within free tier limits

---

## Next Steps After Testing

Once all tests pass:

1. ✅ Update admin emails in `lib/config/email_config.dart`
2. ✅ Add player email addresses to database (future enhancement)
3. ✅ Monitor SendGrid dashboard for first few weeks
4. ✅ Set up email templates for improved formatting (optional)
5. ✅ Consider adding HTML email support (optional)

---

## Support Resources

- **Firebase Extensions Docs:** https://firebase.google.com/products/extensions/firestore-send-email
- **SendGrid Docs:** https://docs.sendgrid.com
- **Firebase Support:** https://firebase.google.com/support

---

## Summary

After successful testing, you should have:
- ✅ Fully automatic email sending (no manual "Send" tap needed)
- ✅ ProShop receives player list when requested
- ✅ ProShop + admins receive results after each Wednesday league
- ✅ Professional email delivery via SendGrid
- ✅ Monitoring via Firebase and SendGrid dashboards
- ✅ $0/month cost with current usage levels

The system is now production-ready! 🎉

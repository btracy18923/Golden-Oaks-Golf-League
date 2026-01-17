# Custom Domain Setup Guide: goldenoaks.golf

This guide walks you through setting up `goldenoaks.golf` for both:
- **Email** (Mailgun) - Professional email delivery to inbox
- **Website** (Netlify) - Custom domain instead of goldenoaks.netlify.app

---

## Overview

**What we're doing:**
1. Add domain to Mailgun
2. Get DNS records from Mailgun
3. Add domain to Netlify
4. Get DNS records from Netlify
5. Configure all DNS records at your domain registrar
6. Update Cloud Function code
7. Update Flutter app config
8. Test email sending

**Time required:** 30-45 minutes
**Cost:** $0 (you already own the domain)

---

## Part 1: Add Domain to Mailgun (10 minutes)

### 1.1 Add Domain in Mailgun

1. Go to https://app.mailgun.com
2. Sign in
3. Click **"Sending"** in left sidebar
4. Click **"Domains"**
5. Click **"Add New Domain"** button
6. Enter domain name: `goldenoaks.golf`
7. Select region: **US** (recommended)
8. Domain type: **Sending**
9. Click **"Add Domain"**

### 1.2 Get Mailgun DNS Records

After adding the domain, Mailgun will show DNS records you need to add. You'll see:

#### **TXT Record (SPF - Sender Policy Framework)**
```
Type: TXT
Name: goldenoaks.golf (or @)
Value: v=spf1 include:mailgun.org ~all
```

#### **TXT Record (DKIM - Domain Keys)**
```
Type: TXT
Name: [something like] k1._domainkey.goldenoaks.golf
Value: [long string starting with "k=rsa; p=..."]
```

#### **CNAME Record (Tracking)**
```
Type: CNAME
Name: email.goldenoaks.golf
Value: mailgun.org
```

#### **MX Record (Optional - only if receiving email)**
```
Type: MX
Name: goldenoaks.golf (or @)
Value: mxa.mailgun.org
Priority: 10

Type: MX
Name: goldenoaks.golf (or @)
Value: mxb.mailgun.org
Priority: 10
```

**IMPORTANT:** Copy these exact values - you'll need them in Step 2!

**Keep this page open** - you'll need these values in the next step.

---

## Part 2: Add Domain to Netlify (5 minutes)

### 2.1 Add Domain in Netlify

1. Go to https://app.netlify.com
2. Sign in
3. Select your site: **goldenoaks**
4. Click **"Domain settings"** (or "Set up a custom domain")
5. Click **"Add custom domain"**
6. Enter: `goldenoaks.golf`
7. Click **"Verify"**
8. Click **"Add domain"**
9. Also add: `www.goldenoaks.golf` (repeat steps 5-8)

### 2.2 Get Netlify DNS Records

Netlify will show you DNS records. You'll see either:

#### **Option A: Netlify DNS (Easiest)**
If using Netlify's nameservers:
```
Type: NS (Nameserver)
Use Netlify's nameservers (they'll provide 4 nameserver addresses)
```

#### **Option B: External DNS (Most Common)**
If using your registrar's DNS:
```
Type: A
Name: goldenoaks.golf (or @)
Value: 75.2.60.5

Type: CNAME
Name: www
Value: [your-site-name].netlify.app
```

**Copy these values** - you'll need them in the next step.

---

## Part 3: Configure DNS Records at Your Domain Registrar (15 minutes)

Now you need to add ALL the DNS records (from Mailgun AND Netlify) to your domain registrar.

### 3.1 Find Your DNS Settings

**Where did you register goldenoaks.golf?** Common registrars:
- GoDaddy
- Namecheap
- Google Domains
- Cloudflare
- Hover

**Steps (varies by registrar):**
1. Log in to your domain registrar
2. Find "DNS Management" or "DNS Settings" for goldenoaks.golf
3. Look for options to add/edit DNS records

### 3.2 Add All DNS Records

Add the records from BOTH Mailgun (Part 1.2) and Netlify (Part 2.2):

#### From Mailgun:
- ✅ TXT record (SPF)
- ✅ TXT record (DKIM)
- ✅ CNAME record (email tracking)
- ⚠️ MX records (optional - only if you want to receive email at this domain)

#### From Netlify:
- ✅ A record (apex domain - goldenoaks.golf)
- ✅ CNAME record (www subdomain)

**IMPORTANT NOTES:**
- Some registrars use `@` for the root domain, others use blank or `goldenoaks.golf`
- TTL (Time to Live) can be left as default (usually 3600 or Auto)
- DNS propagation takes 10 minutes to 48 hours (usually 1-2 hours)

### 3.3 Verify DNS Records

After adding records, you can verify with these tools:

**Check DNS propagation:**
- https://dnschecker.org
- Enter: `goldenoaks.golf`
- Check: A, TXT, CNAME, MX records

**Or use command line:**
```bash
# Check A record (Netlify)
nslookup goldenoaks.golf

# Check TXT records (Mailgun SPF/DKIM)
nslookup -type=TXT goldenoaks.golf

# Check CNAME record
nslookup email.goldenoaks.golf
```

---

## Part 4: Verify Domain in Mailgun (5 minutes)

### 4.1 Wait for DNS Propagation

Wait at least 15-30 minutes after adding DNS records.

### 4.2 Verify in Mailgun

1. Go back to https://app.mailgun.com
2. Click **"Sending"** → **"Domains"**
3. Click on **goldenoaks.golf**
4. Click **"Verify DNS Settings"** button
5. Wait for verification to complete

**Status should show:**
- ✅ **SPF**: Verified
- ✅ **DKIM**: Verified
- ✅ **Tracking**: Verified (optional)

**If not verified yet:**
- Wait another 30 minutes for DNS propagation
- Check DNS records are correct at your registrar
- Try "Verify DNS Settings" again

---

## Part 5: Update Cloud Function Code (2 minutes)

Now update your Cloud Function to use the custom domain instead of sandbox.

### 5.1 Update functions/index.js

I'll update this file for you with the new domain. The changes:
- Remove hardcoded API key (move to config)
- Update domain from sandbox to goldenoaks.golf
- Make it easier to maintain

**I'll create the updated file now...**

---

## Part 6: Update Flutter App Config (1 minute)

Update your Flutter app to use the new domain.

### 6.1 Update lib/config/email_config.dart

I'll update this file to change:
```dart
// Old (sandbox):
static const String senderEmail = 'noreply@sandbox1fa84ccb0aab4d71b8d6ceaeab6b71cc.mailgun.org';

// New (custom domain):
static const String senderEmail = 'noreply@goldenoaks.golf';
```

---

## Part 7: Deploy Updated Cloud Function (3 minutes)

After updating the code, redeploy:

```bash
firebase deploy --only functions
```

---

## Part 8: Test Email Sending (5 minutes)

### 8.1 Send Test Email via Firestore

1. Go to https://console.firebase.google.com/project/golf-league-b0bb2/firestore
2. Go to **mail** collection
3. Create new document:

```
to: ["btracy18923@gmail.com"]
message: {
  subject: "Test from goldenoaks.golf",
  text: "This email is from our custom domain!"
}
```

4. Save and wait 10-30 seconds
5. **Check your email inbox** - should arrive in INBOX, not spam!

### 8.2 Verify Delivery

Check the Firestore document:
- `delivery.state` should be "SUCCESS"
- Check your email - should be in **Inbox** (not spam!)

---

## Part 9: Add Email Addresses (Optional)

With a verified custom domain, you can send to ANY email address (not just authorized recipients).

**But you may want to keep sandbox for testing:**
- Keep sandbox active alongside custom domain
- Use sandbox for testing
- Use goldenoaks.golf for production emails

---

## Troubleshooting

### Email Still Goes to Spam

**Wait 24-48 hours:**
- New domains need to build reputation
- First few emails might still go to spam
- After a few successful sends, Gmail/etc will trust the domain

**Check DNS records are verified:**
- SPF and DKIM must be verified in Mailgun
- These prevent spam filtering

### DNS Not Verifying

**Common issues:**
- DNS propagation takes time (wait 1-2 hours)
- Wrong record type (TXT vs CNAME)
- Wrong record name (@ vs goldenoaks.golf vs blank)
- Missing records (need both SPF and DKIM)

**Solution:**
- Use https://dnschecker.org to verify records are live
- Check records match exactly what Mailgun specified
- Wait longer (up to 48 hours for full propagation)

### Website Not Loading

**Check Netlify DNS:**
- A record must point to Netlify's IP
- CNAME for www must point to your-site.netlify.app
- Check in https://dnschecker.org

**SSL Certificate:**
- Netlify auto-provisions SSL (takes 24 hours)
- Site might show "Not Secure" for first day
- Will automatically resolve

---

## Summary

Once complete, you'll have:

✅ **Professional email**: `noreply@goldenoaks.golf`
✅ **Custom website**: `https://goldenoaks.golf`
✅ **Inbox delivery**: Emails go to inbox, not spam
✅ **Verified domain**: SPF/DKIM configured
✅ **No recipient limits**: Can email anyone (not just authorized)
✅ **Free**: Still $0/month for Mailgun (under 1,000 emails/month)

---

## What's Your Domain Registrar?

Let me know where you registered `goldenoaks.golf` and I can provide specific instructions for adding the DNS records!

Common registrars:
- GoDaddy
- Namecheap
- Google Domains
- Cloudflare
- Hover
- Other?

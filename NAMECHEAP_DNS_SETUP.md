# Namecheap DNS Setup for goldenoaks.golf

Step-by-step guide to configure DNS records in Namecheap for both Mailgun (email) and Netlify (website).

---

## Step 1: Add Domain to Mailgun (Get DNS Records)

### 1.1 Add Domain in Mailgun

1. Go to 
2. Sign in
3. Click **"Sending"** → **"Domains"**
4. Click **"Add New Domain"**
5. Enter: `goldenoaks.golf`
6. Region: **US**
7. Click **"Add Domain"**

### 1.2 Copy Mailgun DNS Records

Mailgun will show you DNS records. **Write these down** or keep the tab open:

**Example of what you'll see:**

**TXT Record (SPF):**
```
Type: TXT
Host: @ (or goldenoaks.golf)
Value: v=spf1 include:mailgun.org ~all
```

**TXT Record (DKIM):**
```
Type: TXT
Host: k1._domainkey (or similar)
Value: k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GN... (long string)
```

**CNAME Record:**
```
Type: CNAME
Host: email
Value: mailgun.org
```

**MX Records (optional - only if receiving email):**
```
Type: MX
Host: @
Value: mxa.mailgun.org
Priority: 10

Type: MX
Host: @
Value: mxb.mailgun.org
Priority: 10
```

**Keep this page open!** You'll add these to Namecheap in Step 3.

---

## Step 2: Add Domain to Netlify (Get DNS Records)

### 2.1 Add Domain in Netlify

1. Go to https://app.netlify.com
2. Sign in
3. Select your site (goldenoaks)
4. Click **"Domain management"** or **"Domain settings"**
5. Click **"Add custom domain"**
6. Enter: `goldenoaks.golf`
7. Click **"Verify"** → **"Add domain"**
8. Also add: `www.goldenoaks.golf` (repeat steps 5-7)

### 2.2 Copy Netlify DNS Records

Netlify will show you these records:

**A Record:**
```
Type: A
Host: @ (or goldenoaks.golf)
Value: 75.2.60.5
```

**CNAME Record:**
```
Type: CNAME
Host: www
Value: [your-site-name].netlify.app
```

**Keep this page open too!** You'll add these to Namecheap in Step 3.

---

## Step 3: Add DNS Records in Namecheap (The Main Part!)

### 3.1 Log in to Namecheap

1. Go 
2. Sign in
3. Click **"Domain List"** in left sidebar
4. Find **goldenoaks.golf**
5. Click **"Manage"** button next to it

### 3.2 Access Advanced DNS Settings

1. Click the **"Advanced DNS"** tab at the top
2. You'll see a list of DNS records (might be empty or have some default records)

### 3.3 Add Netlify Records (Website)

Click **"Add New Record"** and add these:

#### **A Record (for goldenoaks.golf)**
- **Type**: A Record
- **Host**: `@`
- **Value**: `75.2.60.5` (Netlify's IP)
- **TTL**: Automatic

Click **✓ (checkmark)** to save

#### **CNAME Record (for www.goldenoaks.golf)**
- **Type**: CNAME Record
- **Host**: `www`
- **Value**: `goldenoaks.netlify.app` (or your actual Netlify site name)
- **TTL**: Automatic

Click **✓ (checkmark)** to save

### 3.4 Add Mailgun Records (Email)

Click **"Add New Record"** for each of these:

#### **TXT Record #1 (SPF)**
- **Type**: TXT Record
- **Host**: `@`
- **Value**: `v=spf1 include:mailgun.org ~all`
- **TTL**: Automatic

Click **✓ (checkmark)** to save

#### **TXT Record #2 (DKIM)**
- **Type**: TXT Record
- **Host**: `k1._domainkey` (or whatever Mailgun showed you)
- **Value**: `k=rsa; p=MIGfMA0GCS...` (copy the ENTIRE long string from Mailgun)
- **TTL**: Automatic

Click **✓ (checkmark)** to save

**IMPORTANT**: The DKIM value is very long - make sure you copy the entire thing!

#### **CNAME Record (Email Tracking)**
- **Type**: CNAME Record
- **Host**: `email`
- **Value**: `mailgun.org`
- **TTL**: Automatic

Click **✓ (checkmark)** to save

#### **MX Records (Optional - only if you want to receive email)**

**MX Record #1:**
- **Type**: MX Record
- **Host**: `@`
- **Value**: `mxa.mailgun.org`
- **Priority**: `10`
- **TTL**: Automatic

Click **✓ (checkmark)** to save

**MX Record #2:**
- **Type**: MX Record
- **Host**: `@`
- **Value**: `mxb.mailgun.org`
- **Priority**: `10`
- **TTL**: Automatic

Click **✓ (checkmark)** to save

### 3.5 Remove Default Records (If Needed)

Namecheap might have added some default parking page records. You can delete:
- Any existing A records pointing to Namecheap's parking page
- Any CNAME records for `www` pointing to parking pages

**Keep any email-related records you need!**

### 3.6 Save Changes

Click **"Save All Changes"** button at the bottom if there is one.

---

## Step 4: Wait for DNS Propagation (30-120 minutes)

DNS changes take time to propagate worldwide.

**Typical timing:**
- Namecheap: 30 minutes
- Full propagation: 1-2 hours
- Maximum: 48 hours (rare)

**Check propagation:**
1. Go to https://dnschecker.org
2. Enter: `goldenoaks.golf`
3. Select record type: A, TXT, CNAME
4. Check if records are showing up globally

---

## Step 5: Verify Domain in Mailgun (After DNS Propagates)

### 5.1 Verify DNS Settings

1. Go back to https://app.mailgun.com
2. Click **"Sending"** → **"Domains"**
3. Click on **goldenoaks.golf**
4. Click **"Verify DNS Settings"** button
5. Wait for verification

**Expected result:**
- ✅ SPF: Verified
- ✅ DKIM: Verified
- ✅ Tracking: Verified (optional)

**If not verified:**
- Wait 30 more minutes
- Check DNS records in Namecheap are correct
- Use dnschecker.org to verify records are live
- Try "Verify DNS Settings" again

---

## Step 6: Verify Website in Netlify

### 6.1 Check Domain Status

1. Go to https://app.netlify.com
2. Select your site
3. Go to **"Domain management"**
4. Check status of `goldenoaks.golf`

**Status should be:**
- ✅ Domain verified
- ✅ HTTPS certificate provisioning (might take 24 hours)

### 6.2 Test Website

1. Open browser
2. Go to: `http://goldenoaks.golf`
3. Should load your Netlify site!
4. Also try: `http://www.goldenoaks.golf`

**HTTPS/SSL:**
- Netlify auto-provisions SSL certificates
- Might show "Not Secure" for first 24 hours
- Will automatically resolve

---

## Step 7: Deploy Updated Cloud Function

Once Mailgun domain is verified, deploy your updated Cloud Function:

```bash
cd C:\Users\Acer\AndroidStudioProjects\golf_app_v4
firebase deploy --only functions
```

**Expected output:**
```
✔  functions[sendMailgunEmail(us-central1)]: Successful update operation.
✔  Deploy complete!
```

---

## Step 8: Test Email Sending

### 8.1 Send Test Email

1. Go to https://console.firebase.google.com/project/golf-league-b0bb2/firestore
2. Open **mail** collection
3. Create new document:

```
to: ["btracy18923@gmail.com"]
message: {
  subject: "Test from goldenoaks.golf!",
  text: "This email is sent from our custom domain. Should go to inbox!"
}
```

4. Save and wait 10-30 seconds

### 8.2 Check Results

**In Firestore:**
- Check `delivery.state` = "SUCCESS"

**In Email:**
- Check **btracy18923@gmail.com** inbox (NOT spam folder!)
- Email should be from: `noreply@goldenoaks.golf`
- Should go to **Inbox**, not spam!

### 8.3 Check Mailgun Logs

1. Go to https://app.mailgun.com
2. Click **"Sending"** → **"Logs"**
3. You should see your test email
4. Status should be: **Delivered**

---

## Namecheap DNS Summary

Here's what your Namecheap Advanced DNS should look like after setup:

| Type | Host | Value | TTL |
|------|------|-------|-----|
| A Record | @ | 75.2.60.5 | Automatic |
| CNAME | www | goldenoaks.netlify.app | Automatic |
| CNAME | email | mailgun.org | Automatic |
| TXT | @ | v=spf1 include:mailgun.org ~all | Automatic |
| TXT | k1._domainkey | k=rsa; p=MIGf... | Automatic |
| MX | @ | mxa.mailgun.org (Priority: 10) | Automatic |
| MX | @ | mxb.mailgun.org (Priority: 10) | Automatic |

---

## Troubleshooting

### DNS Not Propagating

**Problem:** Records not showing in dnschecker.org after 2 hours

**Solutions:**
- Check records in Namecheap are saved correctly
- Try different DNS record type (some registrars need `@` vs blank vs domain name)
- Clear browser cache
- Wait longer (can take up to 48 hours)

### Mailgun Not Verifying

**Problem:** "Verify DNS Settings" still shows unverified

**Common issues:**
1. **DKIM value incomplete** - Copy entire long string
2. **Host field wrong** - Should be exactly what Mailgun shows (e.g., `k1._domainkey`)
3. **TTL too high** - Use "Automatic"
4. **DNS not propagated yet** - Wait longer

**Check with command line:**
```bash
nslookup -type=TXT goldenoaks.golf
nslookup -type=TXT k1._domainkey.goldenoaks.golf
```

### Email Still Goes to Spam

**Possible reasons:**
1. **Domain too new** - Wait 24-48 hours for domain reputation to build
2. **SPF/DKIM not verified** - Check Mailgun shows both as verified
3. **First few emails** - Send 5-10 emails, then check spam rate

**Solutions:**
- Mark first few emails as "Not Junk"
- Wait 24-48 hours for domain reputation
- Verify SPF and DKIM are green in Mailgun

### Website Not Loading

**Problem:** goldenoaks.golf shows "Not Found" or Namecheap parking page

**Solutions:**
1. **Check A record** - Must be `75.2.60.5` (Netlify IP)
2. **Check host field** - Should be `@` not blank
3. **Clear browser cache** - Try incognito/private mode
4. **Wait for DNS** - Can take 1-2 hours

---

## Next Steps After Setup

Once everything is working:

1. ✅ **Test thoroughly** - Send emails to different providers (Gmail, Outlook, Yahoo)
2. ✅ **Add league members** - Now you can send to ANY email (not just authorized)
3. ✅ **Update marketing** - Use `goldenoaks.golf` in communications
4. ✅ **Monitor deliverability** - Check Mailgun logs for bounce rates
5. ✅ **Set up email addresses** - Consider adding `proshop@goldenoaks.golf`, `admin@goldenoaks.golf`

---

## Cost Summary

- **Domain (goldenoaks.golf)**: You already own it
- **Mailgun**: $0/month (free up to 1,000 emails/month)
- **Netlify**: $0/month (free plan)
- **Firebase**: $0/month (free tier)
- **Total**: **$0/month** 🎉

---

## Support

**Namecheap DNS Help:**
- https://www.namecheap.com/support/knowledgebase/article.aspx/319/2237/how-can-i-set-up-an-a-address-record-for-my-domain/

**Mailgun Verification:**
- https://documentation.mailgun.com/en/latest/user_manual.html#verifying-your-domain

**Netlify Custom Domains:**
- https://docs.netlify.com/domains-https/custom-domains/

---

**Ready to start?** Begin with Step 1 (adding domain to Mailgun) and work through each step in order!

# Domain Change Plan: goldenoaks.golf → goldenoaks27.golf

Planned 2026-10-02. Not yet started.

## Strategy: A New Domain Every Year
To avoid the high `.golf` renewal fees, the domain changes every year:
`goldenoaks27.golf` → `goldenoaks28.golf` → `goldenoaks29.golf` → ...
Members know about this and expect the change.

To make the yearly change easy, the **first switch** includes some one-time setup (Part A). After that, each year only needs the short checklist in Part B.

### Key Ideas
1. **The app uses the netlify.app URL for email.** It calls `https://goldenoaks.netlify.app/.netlify/functions/send-email`, which never changes. No APK rebuild is needed when the domain changes.
2. **The sender address lives in one place.** The Netlify function reads the domain from a Netlify environment variable (`SENDER_DOMAIN`), so the yearly change is a dashboard setting, not a code edit.
3. **Members bookmark `goldenoaks.netlify.app`.** It always works, so nobody ends up with a dead link after a switch. The custom domain is just the nicer-looking name on top.

---

# Part A: First Switch (goldenoaks.golf → goldenoaks27.golf)

## Recommended Order
1. Registrar: register the new domain
2. Resend: add and verify the new domain
3. Netlify: add the new domain and make it primary
4. Firebase: check authorized domains and API key restrictions
5. One-time code changes → deploy with `.\deploy.bat` → rebuild the APK and install it on both phones (the last time a domain change should need this)
6. Retire `goldenoaks.golf` last, after everything works on the new domain

## 1. Domain Registrar (Namecheap)
- Register `goldenoaks27.golf`.
- Keep `goldenoaks.golf` active for a while after the switch, so the installed apps (which still use the old URL until they're updated) and old links keep working.

## 2. Resend
- **Domains → Add Domain → `goldenoaks27.golf`**
- Add the DNS records Resend shows you at the registrar:
  - SPF TXT record
  - DKIM TXT record (`resend._domainkey`)
  - MX record on the `send` subdomain
- Add a DMARC record at the registrar: TXT record named `_dmarc` with value `v=DMARC1; p=none;`. This helps delivery to Gmail and Yahoo.
- Wait until the domain shows **Verified**. Don't remove `goldenoaks.golf` until the new one is working.
- The API key is account-wide, so normally nothing changes. The exception is a key limited to sending from `goldenoaks.golf`. In that case, create a new key (with full sending access, so it works with future domains too) and update `RESEND_API_KEY` in Netlify (and in Firebase, if used).
- A brand-new domain has no sending history yet, so send test emails to Gmail, Yahoo and other addresses before you rely on it.

## 3. Netlify
- **Domain management → Add domain → `goldenoaks27.golf`** (and `www.goldenoaks27.golf`)
- Set it as the **primary domain**.
- DNS records at the registrar (or switch the domain to Netlify DNS instead):
  - A record `@` → `75.2.60.5`
  - CNAME `www` → `goldenoaks.netlify.app`
- Wait for the HTTPS certificate to be issued automatically.
- Leave `goldenoaks.golf` on the site as an alias so it redirects to the new domain.
- **Site configuration → Environment variables:** add `SENDER_DOMAIN` = `goldenoaks27.golf`

## 4. Firebase
- `authDomain` stays `golf-league-b0bb2.firebaseapp.com`, so no change there.
- If the website uses Firebase sign-in: add `goldenoaks27.golf` under **Authentication → Settings → Authorized domains**.
- If the Firebase web API key has website (HTTP referrer) restrictions in Google Cloud Console: add the new domain there (or add `goldenoaks.netlify.app` once, so it keeps working every year).
- If the Firebase email Cloud Function is still used: change its default from-address (see below) and redeploy it.

## 5. One-Time Code Changes
| File | Change |
|---|---|
| `lib/services/backend_email_service.dart:9` | **Most important.** Change `https://goldenoaks.golf/.netlify/functions/send-email` → `https://goldenoaks.netlify.app/.netlify/functions/send-email` (permanent, never needs changing again) |
| `netlify/functions/send-email.js:20, 29, 62` | Build the from-address and unsubscribe address from `process.env.SENDER_DOMAIN` instead of hardcoding `goldenoaks.golf` |
| `lib/config/email_config.dart:21` | `senderEmail`: check whether it's still used; if so, update it or remove it so the Netlify function controls the from-address |
| `functions/index.js:45` | Default from-address (Firebase function): read from config/env, or update it if still in use |
| `deploy.bat:16` | Print `https://goldenoaks.netlify.app` (never needs changing) |
| `netlify_website/index.html` | 3 mentions in the recovery/help text: use `goldenoaks.netlify.app` or general wording so it doesn't need yearly edits |
| `test_resend_email.py` | From-address and Netlify URL (use the netlify.app URL) |

After the code changes:
- Deploy the website with `.\deploy.bat` (never drag-and-drop)
- Rebuild the APK and install it on both phones

**Do NOT change** the Android package name `com.goldenoaks.golf`. It's an app ID, not the website domain, and changing it would make it a different app.

## 6. Retire the Old Domain
- Only after email and the website are confirmed working on the new domain, and both phones have the updated app.
- Tell members to bookmark `goldenoaks.netlify.app`.
- Optional: update the old setup docs (`CUSTOM_DOMAIN_SETUP_GUIDE.md`, `NAMECHEAP_DNS_SETUP.md`, `EMAIL_SYSTEM_DOCUMENTATION.md`, `EMAIL_SYSTEM_MIGRATION_SUMMARY.md`).

---

# Part B: Yearly Checklist (after the first switch)
Example: `goldenoaks27.golf` → `goldenoaks28.golf`. Do this before the current domain expires, with enough time for DNS and Resend verification (allow a few days).

1. [ ] **Registrar:** register `goldenoaksNN.golf`
2. [ ] **Resend:** add the domain, add its DNS records (SPF, DKIM, MX) plus DMARC (`_dmarc` → `v=DMARC1; p=none;`), and wait for **Verified**
3. [ ] **Netlify:** add the domain (and `www.`), add the A record and the `www` CNAME, set it as **primary**, and wait for HTTPS
4. [ ] **Netlify:** update the `SENDER_DOMAIN` environment variable to the new domain
5. [ ] **Deploy:** run `.\deploy.bat` so the function picks up the new variable
6. [ ] **Firebase:** add the new domain to Authorized domains or API key restrictions (only if needed, see Part A step 4)
7. [ ] **Test:** send test emails to Gmail, Yahoo and other addresses, and load the website on the new domain
8. [ ] **Tell members:** the new website name and the new sender address (ask them to add it to their contacts)
9. [ ] **Old domain:** let it expire and remove it from Resend and Netlify

No code changes and no APK rebuild should be needed.

## Drawbacks to Keep in Mind
- **Each new domain starts with no sending history.** The first few emails each year are a little more likely to land in spam. Ask members to add the new sender address to their contacts or mark it "Not spam."
- **Anyone can buy an expired domain.** The risk is low for a golf league, but someone could pose as you with an old name. Don't link to old domains anywhere, and point everything permanent at `goldenoaks.netlify.app`.

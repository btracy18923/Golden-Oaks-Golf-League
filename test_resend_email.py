"""
Test script for Resend email API.
Sends a test email directly to the Resend REST API, bypassing Netlify functions entirely.
Run: python test_resend_email.py

Requires: pip install requests
"""

import json
import requests

# ── Configuration ────────────────────────────────────────────────────────────

RESEND_API_KEY = "re_Ha5ovv4P_LDuiouUtRhRof2nfbVaXkh85"
RESEND_URL     = "https://api.resend.com/emails"

# The "from" address — the domain must be verified in your Resend account.
# If you haven't verified goldenoaks.golf, use the Resend shared domain below instead.
FROM_VERIFIED     = "Golden Oaks Golf League <noreply@goldenoaks.golf>"
FROM_RESEND_SHARE = "Golden Oaks Golf League <onboarding@resend.dev>"   # always works for testing

# Send to yourself so you can confirm delivery
TO_ADDRESS = "btracy18923@gmail.com"

# ── Test cases ───────────────────────────────────────────────────────────────

def send_email(from_addr: str, to: str, subject: str, text: str) -> None:
    print(f"\n{'='*60}")
    print(f"FROM : {from_addr}")
    print(f"TO   : {to}")
    print(f"SUBJ : {subject}")
    print(f"{'='*60}")

    payload = {
        "from":    from_addr,
        "to":      [to],
        "subject": subject,
        "text":    text,
    }

    response = requests.post(
        RESEND_URL,
        headers={
            "Authorization": f"Bearer {RESEND_API_KEY}",
            "Content-Type":  "application/json",
        },
        data=json.dumps(payload),
        timeout=15,
    )

    print(f"HTTP status : {response.status_code}")
    try:
        body = response.json()
        print(f"Response    : {json.dumps(body, indent=2)}")
    except Exception:
        print(f"Response    : {response.text}")

    if response.status_code == 200:
        print("\n✅  SUCCESS — check your inbox at", to)
    elif response.status_code == 401:
        print("\n❌  UNAUTHORIZED — the API key is invalid or expired.")
        print("    → Log in to resend.com, go to API Keys, and verify the key.")
    elif response.status_code == 403:
        print("\n❌  FORBIDDEN — the API key doesn't have permission to send email.")
    elif response.status_code == 404:
        print("\n❌  NOT FOUND — Resend doesn't recognise this endpoint or the API key.")
        print("    → This usually means the API key is wrong or the 'from' domain")
        print("      is not yet verified in your Resend account.")
    elif response.status_code == 422:
        print("\n❌  UNPROCESSABLE ENTITY — likely the 'from' domain is not verified.")
        print("    → Log in to resend.com → Domains, and add/verify goldenoaks.golf.")
        print("    → Until the domain is verified, use the shared domain test below.")
    else:
        print(f"\n❌  UNEXPECTED STATUS {response.status_code}")


# ── Test 1: CORS preflight (OPTIONS request — exactly what the browser sends first) ──
print("\n>>> TEST 1: CORS preflight (OPTIONS)")
print("    The browser sends this before every cross-origin POST.")
print("    Resend must reply with Access-Control-Allow-Origin or the browser blocks the call.")

preflight = requests.options(
    RESEND_URL,
    headers={
        "Origin":                         "http://localhost:8000",
        "Access-Control-Request-Method":  "POST",
        "Access-Control-Request-Headers": "authorization, content-type",
    },
    timeout=15,
)

print(f"HTTP status  : {preflight.status_code}")
print(f"CORS headers :")
for h in ["Access-Control-Allow-Origin", "Access-Control-Allow-Headers",
          "Access-Control-Allow-Methods"]:
    print(f"  {h}: {preflight.headers.get(h, '(not present)')}")

if preflight.headers.get("Access-Control-Allow-Origin"):
    print("\n✅  Preflight OK — Resend allows cross-origin requests.")
else:
    print("\n❌  Preflight FAILED — Resend does not return CORS headers.")
    print("    The browser will block the POST before it's even sent.")
    print("    → Option 2 (direct browser call) will not work.")
    print("    → We need to use the Netlify CLI (Option 1) instead.")

# ── Test 2: Normal server-side POST (confirm API still works) ────────────────
print("\n>>> TEST 2: Server-side POST (confirm API key / domain still valid)")
send_email(
    from_addr = FROM_VERIFIED,
    to        = TO_ADDRESS,
    subject   = "TEST 2 — Server-side POST",
    text      = "Confirming the Resend API key and domain are still working.",
)

print("\nDone.")
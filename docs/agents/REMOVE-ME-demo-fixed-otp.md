# REMOVE ME — fixed demo Mobile OTP (`123456`)

Temporary shortcut so Mobile OTP sign-in works without reading SMS logs.

**Code:** `123456`  
**When it works:** `DEMO_PHONE_OTP` is non-empty (default in code is `123456`). Works with mock **or** Msg91.  
**When it does not:** `DEMO_PHONE_OTP` set to empty, **or** the **backend** on Railway is an older deploy that never had this bypass.

`localreview.co.in` only picks this up after a **backend** redeploy. The frontend login UI can be new while the API still rejects `123456`.

Still click **Send SMS code**, then enter `123456`. Merchant demo phone is `9000000001` (admin is `9000000000`).

## Delete later

1. Default/env `DEMO_PHONE_OTP` in `backend/app/config.py`, `docker-compose.yml`, `backend/.env.example`
2. Demo bypass in `backend/app/services/phone_otp.py::consume_otp`
3. README demo-accounts note and env-table row
4. `backend/tests/test_phone_otp.py` tests named `demo_fixed_otp`
5. This file

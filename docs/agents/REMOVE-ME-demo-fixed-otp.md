# REMOVE ME — fixed demo Mobile OTP (`123456`)

Temporary shortcut so local/demo sign-in does not require reading Compose logs.

**Code:** `123456`  
**When it works:** `SMS_PROVIDER=mock` **and** `DEMO_PHONE_OTP=123456` (Compose sets both).  
**When it does not:** production Msg91, or env unset (default).

Still click **Send SMS code**, then enter `123456`. Use the seeded phone for that role (merchant `9000000001`, not the admin `9000000000`).

## Delete later

1. `DEMO_PHONE_OTP` from `docker-compose.yml`, `backend/.env.example`, `backend/app/config.py`
2. Demo bypass in `backend/app/services/phone_otp.py::consume_otp`
3. README demo-accounts note and env-table row for `DEMO_PHONE_OTP`
4. `backend/tests/test_phone_otp.py` tests named `demo_fixed_otp`
5. This file

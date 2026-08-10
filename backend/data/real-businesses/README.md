# US seed listings (packaged)

Canonical copy of the Fremont / Union City / Brandon / Dallas JSON used by
[`scripts/seed_us.py`](../../scripts/seed_us.py).

This directory is inside the backend image (`Dockerfile` `COPY . .`), so Railway
and other backend-only builds can seed without a Compose volume mount.

Schema and collection notes: [`../../../data/real-businesses/README.md`](../../../data/real-businesses/README.md).
Keep both trees in sync when editing listings.

# Changelog

## 0.2.7 — 2026-08-05
- **Security:** the API key fields no longer render their value. `password_field_tag`
  with a value emits `<input type="password" value="THE_REAL_KEY">` — `type="password"`
  masks the key visually only, and it was fully readable via Inspect element or
  View source. Both fields (`ws_api_key`, `service_api_key`) are now always
  rendered empty; only the last four characters are shown as a hint.
- Because the field is empty, an empty submit now means **"keep the stored key"**
  instead of wiping it. A separate **Remove key** checkbox does the deleting.
- Rotate the Worksheet key if it may have been read from the page source: it has
  broad scope, including salary fields.

## 0.2.6 — 2026-07-20
- Fix: unmapping an employee now persists. Name-based suggestions only pre-fill
  on first setup (before anything is saved); afterwards the saved state is
  respected, so "do not map" no longer reverts to a suggestion after Save. Use
  "Suggest all" to re-apply suggestions on demand.

## 0.2.5 — 2026-07-20
- Stricter matching: exactly a 5-digit issue number at the very start, optional
  leading hash. Rejects text before the number ("ID 55310"), 4-digit ("1234")
  and 6-digit ("123456") numbers.

## 0.2.4 — 2026-07-20
- The leading hash is now optional: both `#55310` and `55310` are accepted.

## 0.2.3 — 2026-07-20
- "Suggest all" button: fills the automatic name-based mapping guess for every
  not-yet-mapped employee (manual choices are kept). Complements "Unmap all".

## 0.2.2 — 2026-07-20
- "Unmap all" button aligned above the Redmine-user column, centered label.

## 0.2.1 — 2026-07-20
- "Unmap all" button in the mapping table (clears all selections; save to persist).

## 0.2.0 — 2026-07-20
- Concurrency-safe dedup: the import-log row is written first (as a lock via the
  unique index) inside a transaction, then the time entry — no more duplicate
  time entries on simultaneous runs.
- Ignore non-productive work types: `_Holiday`, `_Reciprocal service`, `Bonus`,
  `LDO`, `Sick Leave`, `Pension/Life Insurance`, `Public holiday`.
- Run history stored in DB with a CSV export (Administration → Worksheet sync).
- Activity fallback is now reported (when the configured activity is missing on
  a project, the entry is logged under the project's first activity instead of
  being dropped).
- Automated tests added (parser, finality rule, importer with a stubbed client).
- Client is now dependency-injectable for testing.

## 0.1.2 — 2026-07-20
- Import entries whose title is just `#<issue id>` with no comment (previously
  a comment was required). Empty comment is now allowed.

## 0.1.1 — 2026-07-20
- Added an in-UI explanation for the "Cron window (days back)" field.

## 0.1.0 — 2026-07-17
- Initial release.
- Central, admin-driven import of logged time from ws.previo.cz into Redmine.
- Parses `#<issue id> <comment>`; logs hours/date, activity Development.
- Time attributed to the real user (mapped), created by a configurable service user.
- Manual import (preview + import) and cron rake task (imports only locked days).
- Idempotent per worksheet entry id. Salary fields never read/stored (GDPR).
- Tested on Redmine 6.1.3.

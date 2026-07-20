# Changelog

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

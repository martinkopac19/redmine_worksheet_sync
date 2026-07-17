# Changelog

## 0.1.0 — 2026-07-17
- Initial release.
- Central, admin-driven import of logged time from ws.previo.cz into Redmine.
- Parses `#<issue id> <comment>`; logs hours/date, activity Development.
- Time attributed to the real user (mapped), created by a configurable service user.
- Manual import (preview + import) and cron rake task (imports only locked days).
- Idempotent per worksheet entry id. Salary fields never read/stored (GDPR).
- Tested on Redmine 6.1.3.

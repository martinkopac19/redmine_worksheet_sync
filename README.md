# Redmine Worksheet Sync

A Redmine plugin that imports logged time from the **Previo Worksheet** app
(`ws.previo.cz`) into Redmine. When a worksheet entry's text starts with
`#<issue id>`, the time is logged to that Redmine issue.

> **Previo-specific:** this plugin talks to the internal Worksheet API
> (`ws.previo.cz`). It is useful as-is only inside Previo, but the code is a
> clean reference for "external timesheet → Redmine time entries".

**Example:** a worksheet entry on 23 Jun, duration `3:00`, text
`#52291 Promotion update frequency` →
Redmine issue **#52291** gets **3 h**, activity **Development**, comment
*"Promotion update frequency"*.

## Model (central, admin-driven)

Regular users configure nothing. A Redmine **administrator** sets everything in
**Administration → Worksheet sync**:

- **One central Worksheet API key** (broad scope, reads everyone's worksheets).
- **Service user** — the Redmine account under which entries are *created*
  (`author`). Pick a user or paste that user's Redmine API key. Use a dedicated
  account, not a personal one.
- **Mapping** Worksheet employee → Redmine user (with automatic name-based
  suggestions). Only mapped employees are imported.

The logged time is attributed to the **real person** (`TimeEntry.user` = the
mapped Redmine user, so per-person reports are correct); the **service user** is
the `author`.

## Features

- Parses `#<id> <comment>` from the worksheet entry; logs `hours = minutes/60`,
  `spent_on = entry date`, activity **Development** (configurable).
- **Manual import** — pick a date range, **Preview** (writes nothing) then
  **Import**.
- **Automatic import (cron)** — a rake task that imports only **locked** days:
  a worksheet entry for day *D* can be edited until the next working day, so it
  is imported only once `next_working_day(D)` has passed (Wed → Fri, Thu → Mon,
  Fri → Tue). Weekends handled; public holidays not (v1).
- **Idempotent** — each worksheet entry (by its unique id) is imported once.
- **GDPR** — salary fields from the Worksheet API are dropped immediately and
  never read, stored or displayed.
- No core changes; writes via in-process ActiveRecord.

## Compatibility

Tested on **Redmine 6.1.3** (Ruby 3.4, Rails 7.2, PostgreSQL).
Declares `requires_redmine version_or_higher: '5.0'`.

## Installation

```bash
cd /path/to/redmine/plugins
git clone https://github.com/martinkopac19/redmine_worksheet_sync.git
cd /path/to/redmine
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
# restart Redmine
```

## Configuration

**Administration → Worksheet sync**: enter the Worksheet API key, choose the
service user, load employees, map them to Redmine users, pick the activity, and
(optionally) enable cron.

### Cron (automatic daily import)

```cron
# every day at 06:00 — imports locked days from the configured window
0 6 * * *  cd /path/to/redmine && bin/rails redmine:worksheet_sync RAILS_ENV=production
```

## Uninstall

```bash
cd /path/to/redmine
bundle exec rake redmine:plugins:migrate NAME=redmine_worksheet_sync VERSION=0 RAILS_ENV=production
rm -rf plugins/redmine_worksheet_sync
# restart Redmine
```

## License

GPL-2.0-or-later, matching Redmine. See [LICENSE](LICENSE).

## Credits

Built for [Previo](https://previo.cz).

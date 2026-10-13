# OZONE: product brief

Status: approved baseline, 13 Oct 2026. Design phase in progress (see [06-design-progress.md](06-design-progress.md)).

## What it is

OZONE is a private, offline, single-user mobile app that bundles three tools in one shell:

- **Finance**: Savings accounts, Gold holdings and Expenses
- **Library**: a reading library with ratings and stats
- **Notes**: rich notes with folders, tags and encrypted locked notes

These share a Home dashboard, global search, settings and an Excel workbook for backup and import.
There is no account, no server and no sync. All data stays on the phone.

Platform: Flutter, one codebase. Android is the primary device, and iOS is supported.

## Name and brand

Ozone (O₃) is three oxygen atoms bonded into one molecule. OZONE bonds three tools into one app.
Ozone is also a pale blue gas, which gives the brand its colour. Brand assets and rules are in
[../design/brand/README.md](../design/brand/README.md).

## Product principles

1. **Truthful numbers.** Every total shows what it's based on and as of when. Missing data is shown as missing, never invented.
2. **Fast entry.** Common records take three taps or fewer to start, with sensible defaults.
3. **Private by default.** Locked notes are encrypted, amounts can be hidden, and nothing leaves the phone unless you export it.
4. **Nothing lost silently.** Imports preview and never delete, deletes can be undone or go to the trash, and a safety export runs before any import.
5. **One product.** Every tool uses the same patterns, components and rules.

## Out of scope (by decision)

Budgeting, bank sync, cloud sync or multiple devices, live gold prices, multi-currency, sharing, handwriting and attachments.
Each would add a network dependency or a new kind of risk. They can be reconsidered later.

## Documents

| File | Contents |
|---|---|
| [02-requirements-baseline.md](02-requirements-baseline.md) | Confirmed requirements per tool |
| [03-decision-log.md](03-decision-log.md) | Every decision, with its date |
| [04-ux-architecture.md](04-ux-architecture.md) | Sitemap, navigation, flows, widgets, search, states, accessibility |
| [05-design-system.md](05-design-system.md) | Foundations, colours, type and component inventory |
| [06-design-progress.md](06-design-progress.md) | Design canvas, screens done, what's next |

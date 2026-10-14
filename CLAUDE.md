# OZONE: project guide for Claude

Personal, offline, local-only super app (Finance, Library, Notes), built in Flutter in `app/`.
**Current phase: build. M0–M3 approved (branches `build/m0`–`build/m3`); next M4 · Library on `build/m4`.**

## Read first

- `docs/06-design-progress.md`: where work stands and what's next
- `docs/02-requirements-baseline.md`: confirmed requirements (source of truth)
- `docs/03-decision-log.md`: every decision; don't reopen settled ones
- `docs/04-ux-architecture.md`, `docs/05-design-system.md`: UX rules and design tokens
- `design/brand/README.md`: logo and brand rules
- `docs/spec/README.md`: the approved build specification (data, behaviour, architecture, packages, tests, build order M0–M9)

Design canvas (all boards and the clickable prototype): https://claude.ai/artifact/S3CXJRBqxhXh27BtdUwjbS
Read its `project/canvas.json` before adding boards. Users may move boards by hand, so merge with what's there rather than overwriting it.

## Working rules

- Work in phases and wait for the owner's approval at each milestone. Ask focused questions in small batches, each with a recommended answer.
- Keep confirmed requirements, recommendations and open questions clearly separate.
- Never invent data or totals in specs. Sample data on the canvas is labelled as such.
- App shell neutral, colour per tool (Finance teal, Library blue, Notes violet). Bar = Home + up to 3 tools + Tools.
- Don't commit or push unless asked. Keep the docs in `docs/` up to date when decisions change.

## Build workflow

- Follow `docs/spec/` exactly; milestones are in `docs/spec/F3-04-build-order.md`. If the spec is missing or wrong, ask, then update it and `docs/03`.
- One branch per milestone (`build/mN`, from the previous one). Commit only when the owner asks; never push unless asked.
- Before handing over an APK: `app/tool/release_check.ps1` must pass (lockfile, analyzer, tests, osv-scanner, secret scan, permissions, signature, size).
- Test on the emulator `OZONE_A03_API33` (PIN 1234), then record the result in the build log in `docs/06-design-progress.md`.
- Packages: follow the safety procedure in `docs/spec/F3-02-packages.md` §4 before adding or updating any package.
- App notes and known gotchas: `app/README.md`.

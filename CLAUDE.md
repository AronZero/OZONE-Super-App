# OZONE: project guide for Claude

Personal, offline, local-only super app (Finance, Library, Notes), built in Flutter in `app/`.
**Current phase: M0–M9 approved (OZONE 1.0.0, branches `build/m0`–`build/m9`). UI refresh in progress on `build/m10-ui`: step 1 (bar and icons) approved and committed; step 2 (Monochrome, build 13) approved and committed; step 3 (micro-animations, build 14) approved and committed. Recipe tool: M11 approved and committed on `build/m11` (1.2.0 build 15); M12 (scanning, build 16) approved and committed on `build/m12`; M13 (What can I cook?, build 17) approved and committed on `build/m13`; splash (UR4-1, build 18) approved and committed on `build/ur4-splash`; M14 (Finish, build 19) approved and committed on `build/m14`: OZONE 1.2.0 complete, see `docs/06-design-progress.md`.**

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
- Commit as soon as the owner approves a milestone (owner rule, 15 Oct 2026); otherwise only when asked. Never push unless asked. Keep the docs in `docs/` up to date when decisions change.

## Build workflow

- Follow `docs/spec/` exactly; milestones are in `docs/spec/F3-04-build-order.md`. If the spec is missing or wrong, ask, then update it and `docs/03`.
- One branch per milestone (`build/mN`, from the previous one). Commit when the owner approves the milestone; never push unless asked.
- Before handing over an APK: `app/tool/release_check.ps1` must pass (lockfile, analyzer, tests, osv-scanner, secret scan, permissions, signature, size).
- Test on the emulator `OZONE_A03_API33` (PIN 1234), then record the result in the build log in `docs/06-design-progress.md`.
- Packages: follow the safety procedure in `docs/spec/F3-02-packages.md` §4 before adding or updating any package.
- App notes and known gotchas: `app/README.md`.

# OZONE: project guide for Claude

Personal, offline, local-only super app (Finance, Library, Notes) to be built later in Flutter.
**Current phase: specification done (Task F approved 14 Oct 2026). PC set up (Flutter 3.47.5 at C:/dev/flutter). M0 built 14 Oct, awaiting owner check; next M1.** App code: `app/` (see app/README.md). Build rules: `docs/spec/`.

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

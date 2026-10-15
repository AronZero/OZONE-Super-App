# Design system: Soft Utility

Approved 13 Oct 2026. Logo and brand rules are in [../design/brand/README.md](../design/brand/README.md).

## Core rule

**The app shell is neutral, and colour belongs to the tools.** Home, Tools, Search and Settings use ink-coloured main buttons.
Inside a tool, its main actions and active states use that tool's accent.

## Colour tokens

| Token | Light | Dark | Use |
|---|---|---|---|
| canvas | `#F3F5F2` | `#0F1412` | Screen background |
| surface | `#FFFFFF` | `#1A221E` | Cards, sheets, list groups |
| surface-sunken | `#E6EAE5` | `#1F2925` | Inputs, icon buttons |
| bar | `#E9EDE8` | `#161D1A` | Bottom bar |
| bar-active | `#D3DBD5` | `#2E3A34` | Active tab on shell screens |
| outline | `#C9D0CA` | `#34413A` | Dividers |
| ink | `#15201B` | `#E7EEEA` | Text, shell main buttons |
| ink-muted | `#4C5A53` | `#A9B7B0` | Secondary text |
| gain | `#1B6B3E` | `#7FD6A0` | Always with ▲ and a + sign |
| loss | `#A3361F` | `#F59B85` | Always with ▼ and a − sign |
| attention bg / ink | `#FBE3C6` / `#7E410B` | `#3A2A17` / `#F2C38B` | Needs attention, stale data |
| danger | `#A3361F` | `#F59B85` | Destructive buttons |

Spending changes use ink-muted (neither good nor bad). Carried months use a dashed outline. Refunded amounts are struck through and tagged.

### Tool tints (accent / tile)

| Tool | Light | Dark |
|---|---|---|
| Finance (teal) | `#16676A` / `#DFF1F1` | `#86D4D2` / `#17302F` |
| Library (ozone blue) | `#1F5A8F` / `#E2ECF7` | `#9CC5F2` / `#1C2A3A` |
| Notes (violet) | `#5B3E99` / `#ECE7F5` | `#C2AEF0` / `#2A2438` |
| Future pool | green `#1F6B4F`, amber `#8A5216`, rose `#8E2F4A`, olive `#565F14`, coral `#963F1E`, slate `#3E4A5C`, plum `#7A3270` | see canvas board E4 |

The Finance chart's mid tint is `#8CC9C7` (dark `#3A6E6C`). Brand pale `#E2ECF7` is used only for the app icon, splash and first run.

## Type: Manrope (SIL OFL 1.1), tabular figures for all numbers

| Token | Size / line height · weight |
|---|---|
| amount-xl | 34/40 · 800 |
| title-xl | 28/34 · 800 |
| amount-l | 24/30 · 800 |
| section | 20/26 · 800 |
| title | 16/22 · 700 |
| body | 15/22 · 500 (note editor body: 17/26) |
| body-s | 13/18 · 600 |
| label | 12/16 · 700 |
| caption | 11.5/14 · 600 (bar labels and chart axes only) |

## Spacing, shape, depth

- 4 dp base: 4, 8, 12, 16, 20, 24, 32, 40. Screen margin 16, gap between cards 12, list rows ≥ 56, touch targets ≥ 48.
- Corner radius: cards 22, tiles and inputs 14, sheets 28 (top only), add button 20, buttons and chips fully rounded. Main buttons are 48–52 tall.
- Flat tonal surfaces with no card borders. Shadows only on sheets; the bar and the add buttons are flat (owner, 15 Oct 2026). In dark mode, raised surfaces get lighter instead of using shadows.

## Formats

`₱1,234.56` · hidden `₱ ••••` · compact `₱1.28M` (chart axes only) · `13 Oct 2026` (`13 Oct` within the current year) ·
`82.400 g` · `18K` · `842 KB / 12.4 MB / 1.2 GB` · `★ 3.5` / "Not rated" · `17.5%`

## Icons, charts, motion

- Icons: Material Symbols Rounded (Apache-2.0), bundled as a variable font, 24 dp, optical size 24, weight 400. Outline by default; solid only for an active or selected state (UR1-2). Every icon is listed in `lib/core/ui/theme/oz_icons.dart`.
- Charts: bars with rounded tops. The current period uses the tool accent and past periods the mid tint. Carried months are dashed and missing months are gaps. Each chart has a table view.
- Motion (UR1-3): press 120 ms, icon fill 240, screen change 260 (fade in, rise 10 dp), hide on scroll 280, bar label 300, bar pill 340 with slight overshoot, icon pop 380. Nothing moves when Reduce motion is on. All durations come from `lib/core/ui/motion.dart`. Focus ring: 2 dp ink, offset 2.
- Bottom bar (UR1-1): floating pill 64 dp, radius 32, 16 dp from the edges, max 440 dp wide, bar fill only: no border and no shadow (owner, 15 Oct 2026). The active item is a 52 dp pill in the tool accent (ink on shell screens) with the solid icon and its label.

## Component inventory

- **Shell:** bottom bar (neutral and tinted), top bars (main, detail, editor), Finance tabs, buttons (shell, tool, secondary, text, danger, disabled), add buttons, quick-add menu, dialog, sheet, undo message.
- **Data:** amounts (xl, l, row, hidden), change badges, month markers, status and tag chips, refunded, attention banner, list rows, summary card with chart, star rating, empty state, skeleton.
- **Inputs:** text, amount, date, vendor autocomplete, switch, single-choice chips, rating input, search with scope chips, filter chips and sort.
- **Notes and security:** note cards (pinned, locked), formatting bar, text colour and highlight palettes, checklist, vault unlock sheet, password strength, recovery code.
- **Widgets:** widget frame, arrange rows.

Both themes are drawn on the canvas boards "Step 3 · Components · Light/Dark".

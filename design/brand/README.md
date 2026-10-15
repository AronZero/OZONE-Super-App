# OZONE brand sheet

Approved 13 Oct 2026. Concept C "The Bond" with the P1 "Ozone Triad" palette.

## Idea

Ozone (O₃) is three oxygen atoms bonded into one molecule, and a pale blue gas.
OZONE bonds three tools into one app. Each atom is a tool; each pair overlap
blends two tools; the centre, where all three meet, is the **ozone core**: the
app as a whole.

## Files

| File | Use |
|---|---|
| `ozone-mark.svg` | Full-colour mark on light backgrounds |
| `ozone-mark-dark.svg` | Full-colour mark on dark backgrounds |
| `ozone-mark-outline.svg` | One-colour outline: print, emboss, themed icons |
| `ozone-mark-silhouette.svg` | One-colour solid, core knocked out: anything below 32 px |
| `ozone-lockup-horizontal.svg` | Mark + wordmark (live text; outline the text before external use) |
| `android/ic_launcher_foreground.svg` | Adaptive icon foreground (108 dp canvas, mark inside 66 dp safe zone) |
| `android/ic_launcher_background.svg` | Adaptive icon background (`#E2ECF7`) |
| `android/ic_launcher_monochrome.svg` | Themed icon layer (Android 13+) |
| `android/ic_stat_ozone.svg` | Status-bar notification icon (white silhouette) |
| `ios/AppIcon-1024-light.svg` | iOS icon master, opaque |
| `ios/AppIcon-1024-dark.svg` | iOS 18+ dark appearance, transparent background |
| `ios/AppIcon-1024-tinted.svg` | iOS 18+ tinted appearance, greyscale |

Every overlap is a flat, separate shape: no clipping, masks or transparency.
PNG exports and Android vector drawables are generated during Flutter
setup (Task F).

## Geometry

Three circles, radius 24, centres on an equilateral triangle with 24.2 sides,
in a 100 × 100 box: Library (50, 39.52), Notes (62.1, 60.478), Finance
(37.9, 60.478). The bounding box is centred in the frame.

## Colours

| Region | Light | Dark |
|---|---|---|
| Finance atom | `#2E9C9A` | `#6CCFCB` |
| Library atom | `#3B7DC4` | `#8DBEF2` |
| Notes atom | `#7A5CC6` | `#B9A3EE` |
| Finance + Library | `#2A6FA0` | `#74B4DA` |
| Library + Notes | `#5150AE` | `#A4A2EC` |
| Notes + Finance | `#55669E` | `#A6B6DC` |
| Ozone core | `#1C3466` | `#EEF4FB` |
| Brand pale (icon/splash background) | `#E2ECF7` | n/a |

These are **logo-only** colours. The UI uses the AA-contrast tool accents:
Finance `#16676A`, Library `#1F5A8F`, Notes `#5B3E99`. The full token set is
on the design canvas (Foundations board and the scaling board's tint palette).

## Rules

- Clear space: half an atom's radius (12 units) on every side.
- Minimum size: 32 px for full colour; use the silhouette below that.
- In the app's Monochrome mode the mark is drawn in greys (decision UR2-3): on dark, the greys of
  `ios/AppIcon-1024-tinted.svg`; on light, greys matched to the light mark with a dark core (#363636).
- Wordmark: Manrope ExtraBold (800), all caps, +14% letter spacing. In the
  horizontal lockup the mark is 1.7× the cap height.
- Never stretch, rotate, recolour outside these versions, add effects, or
  place the full-colour mark on busy imagery.
- Brand moments only (splash, first run, About). The app shell stays neutral.

## Licences

- The mark is original artwork (plain circles), with no third-party assets.
- Manrope is licensed under the SIL Open Font License 1.1, which permits use
  in logos and modification. If the font file ships inside the app, include
  its OFL licence text in the app's third-party licences.
- "Ozone" is used by other products. Run a trademark search before any
  public app-store release.

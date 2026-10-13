# Design progress

Last updated: 13 Oct 2026.

## Design canvas

All boards and the clickable prototype are on one private design canvas:
**https://claude.ai/artifact/S3CXJRBqxhXh27BtdUwjbS**

Open it, find **W1 · Home** or **W2 · Welcome**, and press Play. Sample data only.

| Canvas row | Contents | Status |
|---|---|---|
| 1 | Discovery: overview, requirements, problem register, MVP, decisions, baseline | Done |
| 2 | Task D UX architecture: sitemap, flows, widgets and search, states and accessibility | Approved |
| 3 | Task E: plan, 3 visual directions, scaling to 8+ tools, foundations | Approved (B · Soft Utility) |
| 4 | Brand: logo concepts, final logo | Approved (The Bond × Ozone Triad) |
| 5 | Components, light and dark | Approved |
| 6 | Wave 1 screens (10) | Approved |
| 7 | Wave 2 screens (13, including 2 dark) | Reviewed; no changes requested |

## Screens done

**Wave 1:** Home · Savings overview · Update balances · Account detail · Note editor · Vault unlock ·
Vault setup (password) · Vault setup (recovery code) · Import preview · Settings › Data & backup

**Wave 2:** Welcome · Gold overview (light and dark) · Karat prices · Expenses · Add expense ·
Spending by year · Library · Add book · Library stats · Notes home (light and dark) · Global search

## Next: Wave 3 (last design wave)

1. Settings menu (all sections) and Appearance
2. Dashboard widget arrangement
3. Export flow (progress and finish)
4. App lock gate
5. Savings history report and archived accounts
6. Book detail and expense detail (mark refunded)
7. Notes: note menu sheet, folders and tags management, trash
8. Forgot vault password and vault reset
9. Tools launcher and Edit bar, in the final style
10. A states board: empty, error and confirmation examples in both themes

## After Wave 3: Task F (Flutter-ready specification, no app code)

Local storage and data model, workbook schema (sheets, columns, IDs, versioning), import and conflict rules,
locked-note encryption and key handling, search indexing, monthly derivation logic, reminders and platform limits,
the tool-registry architecture (so new tools can plug in), dependencies (well-known and pinned), tests and acceptance criteria.

## Brand files

Master SVGs, Android and iOS icon sources, and the brand sheet are in [../design/brand/](../design/brand/).
PNG exports are generated during Flutter setup.

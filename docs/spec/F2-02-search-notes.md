# F2-02 · Search, note editing, autosave and trash

Screens: W2 · Global search, W1 · Note editor, W3 · Note menu sheet, Folders & tags, Notes trash.

## 1. Search index

One SQLite FTS5 table, kept in step with the data **inside the same transaction** as every insert, update and delete
(drift triggers or repository code; F3 picks one):

```
search_index(tool, entity, record_id UNINDEXED, title, body, extra, label UNINDEXED)
tokenize = "unicode61 remove_diacritics 2"
```

| Entity | title | body | extra (numbers and words) | label |
|---|---|---|---|---|
| Savings account | name | platform, type, remarks | latest balance as `123456` and `1234.56` | Archived |
| Gold item | name | vendor, remarks | karat (`18k`), grams | Disposed |
| Expense | item | vendor, remarks | amount as `123456` and `1234.56` | Refunded |
| Book | title | author, remarks | year acquired | status |
| Note (unlocked, not trashed) | title | plain text | tag names | Pinned |

**Never indexed:** locked notes and notes in the trash. Locking or trashing a note deletes its index row in the same transaction.

**Query rules** (docs/04):

- Start after 2 characters, 150 ms after typing stops.
- Each word becomes a prefix term (`word*`), all terms must match (AND), and case and accents are ignored (`cafe` finds `Café`).
- A term that looks like an amount (`1299`, `1,299`, `1299.00`, `₱1,299`) also matches the amount **exactly**: it's
  normalised to centavos and compared with `extra`.
- Results are grouped by tool in bar order (then the other tools), with counts and the top 3 per group ranked by `bm25()`
  with title matches first; "See all" opens the full list. A tap opens the exact record.
- The footer "Locked notes aren't searched" is always shown.
- Recent searches: the last 5 submitted queries (settings `search.recent`), with "Clear".

Budget: under 100 ms per query on the reference phone with 20,000 indexed rows.
The index is rebuilt from scratch after an import and after a schema migration (shows "Updating search…").

**Build notes (M7).** The index is kept in step by SQLite triggers on every indexed table (and on `balance_updates`,
`note_tags` and tag renames), so each write and its index row share one transaction whichever code made it. A small
`search_keys` table gives each record a fixed rowid, so its index row is replaced without scanning (schema v2; the v1 → v2
migration builds the index for existing data). Queries are restricted to `title`, `body` and `extra`; typed quotes and
operators never reach FTS5 (only letters and digits do).

## 2. Note editor

- Package: `flutter_quill` (MIT, verified publisher; F3 pins the version). Content is stored as **Quill Delta JSON** in `notes.content`.
- Toolbar (W1 board): bold, italic, underline, heading, bulleted list, numbered list, checklist, highlight, text colour, undo.
  Highlight and text colour use the fixed palettes from the Components board. No images, links or fonts in v1:
  every save keeps only the formats the toolbar makes, typed web addresses stay plain text, and pasting from other apps
  brings plain text (decision M5-5). Colours are stored as their light-theme value and drawn with the dark value in dark mode.
- `plain_text` is created from the Delta on every save (checklist items as "☐ item" / "☑ item").
- Body text is 17/26 (docs/05). It respects the phone's text size up to 200%.

## 3. Autosave and drafts

| Moment | What happens |
|---|---|
| Typing stops for **1 s** | Save the note (content, plain text, `edited_at`, index), then show "Saved". |
| App goes to the background or the screen closes | Save immediately. |
| Between saves (every keystroke) | Write the title and Delta to `note_drafts` at most once per second, as JSON `{"title": …, "ops": […]}`. That's cheap and it survives a crash. |
| App starts with a row in `note_drafts` newer than the note's `edited_at` | Open a banner on that note: "Recovered unsaved changes", with **Keep** (default) and **Discard**. |
| A new note is left with no title and no text | Delete it silently (never trashed, no tombstone). |
| Locked note | The same rules, but the draft is encrypted with DK, and drafts are deleted when the vault relocks. |

Notes never ask "discard changes?" (docs/04).

## 4. Note menu, folders and tags (W3 boards)

- **Pin / Unpin** sets `is_pinned` and `pinned_at`. Pinned notes sort first, newest pinned first.
- **Move to folder:** a list of folders plus Unfiled, and "New folder".
- **Tags:** pick existing tags or type a new one (the rules are in F1-01).
- **Lock note:** set up the vault if needed (F2-01), otherwise lock at once.
- **Folders:** rename; delete moves its notes to Unfiled (one transaction, never deletes notes).
- **Tags:** rename (merges automatically if the new name exists, after a confirmation), merge into another tag, delete
  (removes the label only).

## 5. Trash

- **Move to trash:** sets `trashed_at` and removes the note from search and the dashboard. Undo for 5 s.
- The trash list shows days left = 30 − days since `trashed_at`, at least 1.
- **Restore:** clears `trashed_at` and re-indexes (locked notes return to the vault).
- **Delete forever** and **Empty trash:** confirmation dialog, then delete and write tombstones.
- **Auto-purge:** on app start and on return to the foreground, delete notes trashed more than 30 days ago.

## 6. Undo messages (finance and books)

Deleting shows "Expense deleted · Undo" for **5 s**. The row is hidden at once, and the real delete (plus tombstone) runs when
the message closes or the app goes to the background. Undo restores it untouched.

## Decisions

No new decisions. Everything here follows approved rules.

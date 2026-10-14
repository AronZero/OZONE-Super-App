# F1-04 · Calculations and reports

Every number on screen comes from these rules. They are pure functions over the database: no background jobs, no stored
totals, no invented values. Each one gets unit tests with the worked examples below (F3).

## 1. Money and rounding

- All sums use whole centavos (`int`). Rounding happens once, where a multiplication or division creates fractions,
  using **round half away from zero** to the nearest centavo.
- Display: `₱1,234.56`; negative `−₱1,234.56` (true minus sign); hidden `₱ ••••`; chart axes compact `₱1.28M` / `₱64.8k`.
- Percentages: one decimal, `17.5%`. When the base is 0, show `—`.
- Changes always carry a sign and an arrow: `▲ +₱18,420.00`, `▼ −₱2,000.00`. Zero is shown as `No change`.
- Typed amounts: digits with an optional `.` and at most 2 decimals; commas and `₱` are ignored. Anything else is
  rejected with a message in words.

## 2. Savings: monthly history

Definitions for account **A** and calendar month **M**, where `start(M)` is the first day and `end(M)` the last day:

- **Active in M:** the account has at least one update dated on or before `end(M)`, and (`archived_at` is empty or
  `archived_at ≥ start(M)`). The archive month itself still counts; later months don't.
- **U(A, M)** = the update with the latest `date ≤ end(M)` (only one per date exists).
- **Status:** no U → **No data**. U dated within M → **Recorded** (including `is_unchanged` updates). U dated before M → **Carried**.
- **Balance(A, M)** = U's balance, for Recorded and Carried.
- In the current month, `end(M)` is today. A Recorded current month is labelled "so far".

**Change for one account** (month M vs base month B, where B = M−1 for month-on-month or M−12 for year-on-year):

- Status of M is **Carried** → `Not counted` (no number).
- M has data but B is **No data** → `Start` (no number).
- Otherwise → `Balance(A, M) − Balance(A, B)`. B may be Carried; its carried value is a fair base.

**Totals for month M** (Savings card, History report, chart):

- `Total(M)` = sum of `Balance(A, M)` over accounts active in M with Recorded or Carried status. If no account has data,
  the month is **No data** (a gap in charts).
- The label counts Carried accounts: "1 account carried"; "All carried" when none is Recorded.
- `Change(M)` = the **sum of the counted account changes** above. Accounts that are Carried, Start, or archived before M add
  nothing. So opening a new account or archiving an old one is never shown as savings growth or loss.
  Because of this rule, `Change(M)` can differ from `Total(M) − Total(B)`. The History report notes:
  "Changes leave out new and archived accounts."

**Worked example** (from the W1 boards): Payroll Savings' last update is 30 Sep (₱312,400.00), so in October it is **Carried**,
its October change is Not counted, and it adds ₱312,400.00 to October's total. Emergency Fund updated on 12 Oct
(₱420,150.00 vs ₱414,000.00 at September's end) adds +₱6,150.00 to October's change.

**Chart range:** the last 12 months ending with the current month; History report up to 5 calendar years.
Carried months are drawn dashed and No data months are gaps.

## 3. Needs attention (Home widget)

| Item | Shows when | Opens |
|---|---|---|
| "[Account] needs a [Month] balance" | From the 25th, and through the following month (see Decisions) | Update balances |
| "Gold prices are N days old" | Any karat used by a held item has a current price older than `gold.stale_days` (30) | Karat prices |
| "No price for 21K" | A held item's karat has no price at all | Karat prices |
| "Last export was N days ago" / "Not backed up yet" | Last export older than `backup.reminder_days`, or never exported and the oldest record is more than 7 days old | Data & backup |

## 4. Gold

- `Value(item)` = `weight_mg × price_per_gram ÷ 1000`, rounded once per item (§1). Only **held** items count.
- Totals: weight = Σ `weight_mg` (shown `82.400 g`); cost = Σ cost; estimated value = Σ item values; gain = value − cost;
  gain % = gain ÷ cost.
- Items whose karat has **no price** are left out of value and gain, but kept in weight and cost. The card then says
  "Value leaves out 1 item with no 21K price".
- "Prices as of" shows the **oldest** current-price date among the karats in use, so the label is never more optimistic than the data.
- Karat prices screen: "New estimated value" previews totals with the typed prices before saving (as on W2 · Karat prices).

## 5. Expenses

- Refunded expenses are excluded from **every** total, count and chart, but still listed (struck through) and searchable.
- **This year so far** = Σ amounts dated from 1 Jan to today. **Same period last year** = 1 Jan to the same month and day
  last year. On 29 Feb, last year's end is 28 Feb.
- Change % = (this − last) ÷ last. Spending changes use the neutral muted colour (docs/05).
- **Spending by year:** the current year and the 4 before it. A year with no expenses shows `₱0.00`, not a gap, but only
  for years after the first expense ever. Before that, the year is not shown.
- Monthly bars: the 12 months of the selected year, with future months empty.

## 6. Library

- **Kindle storage** = Σ `size_kb` where `on_kindle` (books without a size count as 0, and the stat says "3 books have no size").
  Shown as `842 KB` under 1,024 KB, `12.4 MB` (1 decimal) under 1,024 MB, otherwise `1.38 GB` (2 decimals). 1 MB = 1,024 KB.
- **Spent on books** = Σ `amount` where acquisition is purchased.
- **Books per year** = count by the year of `acquired_date` for the last 5 years, with a status filter. Books with no date are
  counted in a "No date" note under the chart.
- **Average rating** = mean of `rating_half ÷ 2` over rated books only, one decimal; "44 rated · 22 not rated".
- Counts per status and per acquisition.

## 7. Dates and "today"

"Today" is the phone's local date when the screen is built. Screens refresh it when the app comes back to the foreground
and at midnight while open. Dates are shown as `13 Oct` within the current year and `13 Oct 2025` otherwise.

## Decisions (owner, 14 Oct 2026)

1. **"Needs a balance"** shows from the **25th** of the month for active accounts not yet Recorded this month. It also shows
   through the whole next month for a month that ended Carried, until a past-dated update fixes it.
   Example: on 3 Nov, "Payroll Savings needs an October balance".
2. When a month includes a new account's opening balance, a small note under the change says
   "Includes 1 new account, not counted" ("2 new accounts" for more).

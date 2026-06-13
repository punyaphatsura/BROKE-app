# Annual Expense Feature — Design Spec

**Date:** 2026-06-13  
**Status:** Approved

---

## Overview

Users can mark any expense transaction as "annual" to indicate it recurs once a year. The app then surfaces two things:
1. A **monthly burden** — the annual amount ÷ 12 — shown in HomeView as contextual info
2. An **Annual Expenses section** in AnalyticsView listing all annual transactions with their per-month equivalent

The original transaction is **not modified** — it still appears at full amount in the month it was paid. The annual section is a separate analytical layer.

---

## Decisions Made

| Question | Decision |
|---|---|
| How to model it? | `isAnnual: Bool = false` flag on `Transaction` (Approach A) |
| Where in real transaction? | Stays as `.expense` type, full amount in paid month |
| Monthly average behavior | Both: real transaction intact + monthly burden shown separately |
| Where in UI? | New card in AnalyticsView (expense tab only) + info row in HomeView |
| Card content | Summary header (total/year + avg/month) + list of items |

---

## Model Change

**File:** `BROKE/Models/Transaction.swift`

Add one property to `Transaction`:

```swift
var isAnnual: Bool = false
```

- Default `false` — no migration needed, existing transactions decode correctly
- Only meaningful when `type == .expense`

---

## AddTransactionView — Toggle

**File:** `BROKE/Views/AddTransactionView.swift`

- Show a `Toggle("Annual Expense", isOn: $isAnnual)` row in the form, **only when `type == .expense`**
- Below the toggle (when ON): hint label — *"จำนวนเต็มแสดงในเดือนที่จ่าย และนับเป็น ÷12/เดือน ใน Analytics"*
- State: `@State private var isAnnual: Bool = false`, reset to `false` when type changes away from `.expense`
- Pass `isAnnual` into the saved `Transaction`

---

## AnalyticsView — Annual Expenses Section

**File:** `BROKE/Views/AnalyticsView.swift`

### Placement

Added at the bottom of the expense tab, after `CategoryPerformanceList`:

```swift
if selectedTab == .expense {
    // ... existing cards ...
    AnnualExpensesSection(transactions: annualTransactions)
}
```

### Data

`annualTransactions` = all transactions from `transactionStore.getAllTransactions()` where:
- `type == .expense`
- `isAnnual == true`
- year of `transaction.date` == year of `currentDate`

Computed in `AnalyticsView` as a private var:

```swift
private var annualTransactions: [Transaction] {
    let year = Calendar.current.component(.year, from: currentDate)
    return transactionStore.getAllTransactions().filter {
        $0.type == .expense &&
        $0.isAnnual == true &&
        Calendar.current.component(.year, from: $0.date) == year
    }
}
```

### `AnnualExpensesSection` Component

**Inputs:** `transactions: [Transaction]`

**Layout:**
1. **Header row** — title "Annual Expenses" + year badge (e.g. "2025")
2. **Summary card** — two columns: "ยอดรวมทั้งปี" (sum) | "เฉลี่ยต่อเดือน" (sum ÷ 12)
3. **List rows** — one per transaction, sorted by `date` ascending
   - Category icon + color
   - Description (fallback to `category.displayName`)
   - Subtitle: `category.displayName · MonthName`
   - Right: full amount (red) + `≈ ÷12/เดือน` label (orange)
4. Hidden when `transactions.isEmpty`

---

## HomeView — Monthly Burden Info

**File:** `BROKE/Views/HomeView.swift`

`HomeViewModel` has no `TransactionStore` reference — `HomeView` accesses it directly via `@EnvironmentObject var transactionStore`. The burden is computed as a private var inside `HomeView`:

```swift
private var annualMonthlyBurden: Double {
    let currentYear = Calendar.current.component(.year, from: Date())
    let annualTotal = transactionStore.getAllTransactions()
        .filter { $0.type == .expense && $0.isAnnual && Calendar.current.component(.year, from: $0.date) == currentYear }
        .reduce(0.0) { $0 + $1.amount }
    return annualTotal / 12.0
}
```

### Display in HomeView

Add a small info row below the main balance summary:

- Only shown when `annualMonthlyBurden > 0`
- Text: *"Annual burden ≈ ฿X,XXX/mo"* in secondary text color with a calendar icon
- This is **informational only** — it does NOT add to the expense or balance totals

---

## Scope Explicitly Out

- No recurring auto-generation of monthly transactions
- No reminder/notification when an annual expense is due
- No multi-year tracking or year-over-year comparison
- No editing of `isAnnual` flag from the transaction list (only via AddTransactionView edit flow)

---

## Files Touched

| File | Change |
|---|---|
| `Models/Transaction.swift` | Add `isAnnual: Bool = false` |
| `Views/AddTransactionView.swift` | Add toggle + hint, wire to saved transaction |
| `Views/AnalyticsView.swift` | Add `AnnualExpensesSection` component + data filter |
| `Views/HomeView.swift` | Add `annualMonthlyBurden` computed var + burden info row |

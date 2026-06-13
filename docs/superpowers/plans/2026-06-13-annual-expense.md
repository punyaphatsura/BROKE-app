# Annual Expense Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow users to mark any expense as "annual", then surface a monthly burden view in HomeView and an Annual Expenses section card in AnalyticsView.

**Architecture:** Add `isAnnual: Bool = false` to `Transaction` (backward-compatible). Extract a pure `annualExpenses(from:year:)` helper (testable, reused by both views). `AnnualExpensesSection` is a new SwiftUI component added to `AnalyticsView`. HomeView computes the ÷12 burden inline using the same helper.

**Tech Stack:** Swift 5.9, SwiftUI, Swift Testing (`@Test` / `#expect`)

---

## Files Modified

| File | Change |
|---|---|
| `BROKE/Models/Transaction.swift` | Add `isAnnual: Bool = false` |
| `BROKE/Views/AddTransactionView.swift` | Add toggle + hint, wire to save + populate |
| `BROKE/Views/AnalyticsView.swift` | Add `annualExpenses()` helper, `AnnualExpensesSection` component, wire into body |
| `BROKE/Views/HomeView.swift` | Add `annualMonthlyBurden` computed var + info row |
| `BROKETests/BROKETests.swift` | Add `AnnualExpenseTests` struct |

---

## Task 1: Add `isAnnual` to Transaction model

**Files:**
- Modify: `BROKE/Models/Transaction.swift`
- Test: `BROKETests/BROKETests.swift`

- [ ] **Step 1: Write the failing test**

Open `BROKETests/BROKETests.swift`. Add a new test struct after the closing `}` of `AnalyticsHelpersTests`:

```swift
struct AnnualExpenseTests {

    private func makeAnnual(amount: Double, year: Int) -> Transaction {
        var components = DateComponents()
        components.year = year
        components.month = 6
        components.day = 1
        let date = Calendar.current.date(from: components)!
        return Transaction(amount: amount, description: "annual test", date: date, type: .expense, source: .manual, isAnnual: true)
    }

    private func makeRegular(amount: Double) -> Transaction {
        Transaction(amount: amount, description: "regular", date: Date(), type: .expense, source: .manual)
    }

    @Test func annualExpenses_filtersAnnualOnly() {
        let a = makeAnnual(amount: 12000, year: 2025)
        let r = makeRegular(amount: 500)
        let result = annualExpenses(from: [a, r], year: 2025)
        #expect(result.count == 1)
        #expect(result[0].amount == 12000)
    }

    @Test func annualExpenses_filtersCorrectYear() {
        let a2025 = makeAnnual(amount: 12000, year: 2025)
        let a2024 = makeAnnual(amount: 5000, year: 2024)
        let result = annualExpenses(from: [a2025, a2024], year: 2025)
        #expect(result.count == 1)
        #expect(result[0].amount == 12000)
    }

    @Test func annualExpenses_ignoresIncomeWithAnnualFlag() {
        var income = makeAnnual(amount: 100000, year: 2025)
        income.type = .income
        let result = annualExpenses(from: [income], year: 2025)
        #expect(result.isEmpty)
    }

    @Test func annualExpenses_emptyWhenNone() {
        let result = annualExpenses(from: [makeRegular(amount: 100)], year: 2025)
        #expect(result.isEmpty)
    }
}
```

- [ ] **Step 2: Run tests — expect compile failure**

```bash
xcodebuild test -scheme BROKE -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "error:|PASSED|FAILED" | head -20
```

Expected: compiler error — `'isAnnual' is not a member of 'Transaction'` and `cannot find 'annualExpenses' in scope`

- [ ] **Step 3: Add `isAnnual` to Transaction**

In `BROKE/Models/Transaction.swift`, add one line inside the `Transaction` struct, after `var subTransactions`:

```swift
var isAnnual: Bool = false
```

The struct now looks like:
```swift
struct Transaction: Identifiable, Codable {
    var id = UUID()
    var refId: String?
    var amount: Double
    var description: String
    var date: Date
    var sender: String?
    var receiver: String?
    var type: TransactionType
    var source: TransactionSource
    var categoryId: ExpenseCategory?
    var incomeCategoryId: IncomeCategory?
    var bank: Bank?
    var imagePath: String?
    var subTransactions: [SubTransaction]? = nil
    var isAnnual: Bool = false
}
```

No `CodingKeys` needed — `Codable` synthesis handles the new property and defaults to `false` for existing JSON that doesn't have the key.

- [ ] **Step 4: Add `annualExpenses` helper at the bottom of AnalyticsView.swift**

In `BROKE/Views/AnalyticsView.swift`, add this free function alongside the existing helpers (`expenseTotals`, `dailySpend`, `weekdayAverages`) at the bottom of the file (after the last helper function, before the closing of the file):

```swift
/// Returns all expense transactions that are marked as annual for the given calendar year.
func annualExpenses(from transactions: [Transaction], year: Int) -> [Transaction] {
    let calendar = Calendar.current
    return transactions.filter {
        $0.type == .expense &&
        $0.isAnnual &&
        calendar.component(.year, from: $0.date) == year
    }
}
```

- [ ] **Step 5: Run tests — expect all 4 new tests pass**

```bash
xcodebuild test -scheme BROKE -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "PASSED|FAILED|error:" | head -20
```

Expected: `annualExpenses_filtersAnnualOnly` PASSED, `annualExpenses_filtersCorrectYear` PASSED, `annualExpenses_ignoresIncomeWithAnnualFlag` PASSED, `annualExpenses_emptyWhenNone` PASSED

- [ ] **Step 6: Commit**

```bash
git add BROKE/Models/Transaction.swift BROKE/Views/AnalyticsView.swift BROKETests/BROKETests.swift
git commit -m "feat: add isAnnual flag to Transaction + annualExpenses() helper"
```

---

## Task 2: Annual toggle in AddTransactionView

**Files:**
- Modify: `BROKE/Views/AddTransactionView.swift`

- [ ] **Step 1: Add `isAnnual` state property**

In `BROKE/Views/AddTransactionView.swift`, add one `@State` property in the "State" block (after line 53, near the other `@State` vars):

```swift
@State private var isAnnual: Bool = false
```

- [ ] **Step 2: Add toggle section in the form body**

In `AddTransactionView.swift`, find the block:

```swift
                        // MARK: - Sub Transactions (Expense Only)

                        if type == .expense {
                            subTransactionsSection
                        }
```

Replace it with:

```swift
                        // MARK: - Sub Transactions (Expense Only)

                        if type == .expense {
                            subTransactionsSection

                            // MARK: - Annual Expense Toggle
                            VStack(spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Annual Expense")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(theme.textPrimary)
                                        Text("กระจายเป็น ÷12 ต่อเดือนใน Analytics")
                                            .font(.caption)
                                            .foregroundColor(theme.textSecondary)
                                    }
                                    Spacer()
                                    Toggle("", isOn: $isAnnual)
                                        .labelsHidden()
                                        .tint(theme.accent)
                                }
                                .padding()
                                .background(theme.cardBackground)
                                .cornerRadius(16)

                                if isAnnual, let amtValue = Double(amount), amtValue > 0 {
                                    HStack(spacing: 6) {
                                        Image(systemName: "calendar.badge.clock")
                                            .font(.caption)
                                        Text("฿\(amtValue.formattedCurrency) จะแสดงเต็มจำนวนในเดือนที่จ่าย และนับเป็น ≈ ฿\(Int(amtValue / 12).formattedWithSeparator)/เดือน ใน Analytics")
                                            .font(.caption)
                                    }
                                    .foregroundColor(theme.accent)
                                    .padding(.horizontal, 4)
                                }
                            }
                            .padding(.horizontal)
                        }
```

- [ ] **Step 3: Reset `isAnnual` when type changes away from expense**

Find the `TypeFilterTabs`-equivalent logic or any `.onChange(of: type)`. If none exists, add it inside the form's `VStack` (near the bottom of the body, before the closing `}` of the form `VStack`):

```swift
.onChange(of: type) { _, newType in
    if newType != .expense {
        isAnnual = false
    }
}
```

- [ ] **Step 4: Wire `isAnnual` into the new-transaction save path**

In `saveTransaction()`, find the `let transaction = Transaction(...)` block (around line 330). Add `isAnnual: isAnnual` to the initializer:

```swift
let transaction = Transaction(
    refId: refId.isEmpty ? nil : refId,
    amount: amountValue,
    description: description.isEmpty ? (type == .income ? "Income" : (type == .expense ? "Expense" : "Transfer")) : description,
    date: date,
    sender: sender.isEmpty ? nil : sender,
    receiver: receiver.isEmpty ? nil : receiver,
    type: type,
    source: slipData != nil ? .scan : .manual,
    categoryId: type == .expense ? selectedCategory : nil,
    incomeCategoryId: type == .income ? selectedIncomeCategory : nil,
    bank: selectedBank == .unknown ? nil : selectedBank,
    imagePath: nil,
    subTransactions: finalSubs,
    isAnnual: type == .expense ? isAnnual : false
)
```

- [ ] **Step 5: Wire `isAnnual` into the edit-transaction save path**

In the same `saveTransaction()`, in the `if var transaction = transactionToEdit` branch (around line 315), add one line after the `subTransactions` assignment:

```swift
transaction.subTransactions = finalSubs
transaction.isAnnual = type == .expense ? isAnnual : false
```

- [ ] **Step 6: Populate `isAnnual` when editing an existing transaction**

In `populateFromTransaction(_ transaction:)` (around line 273), add one line after the `refId` line:

```swift
refId = transaction.refId ?? ""
isAnnual = transaction.isAnnual
```

- [ ] **Step 7: Build and verify no compiler errors**

```bash
xcodebuild build -scheme BROKE -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 8: Commit**

```bash
git add BROKE/Views/AddTransactionView.swift
git commit -m "feat: add Annual Expense toggle to AddTransactionView"
```

---

## Task 3: AnnualExpensesSection in AnalyticsView

**Files:**
- Modify: `BROKE/Views/AnalyticsView.swift`

- [ ] **Step 1: Add `annualTransactions` computed var to AnalyticsView**

In `AnalyticsView`, add this private var after `private var previous3Months`:

```swift
private var annualTransactionsForYear: [Transaction] {
    let year = Calendar.current.component(.year, from: currentDate)
    return annualExpenses(from: transactionStore.getAllTransactions(), year: year)
}
```

- [ ] **Step 2: Wire into AnalyticsView body**

Find the expense-only section in `AnalyticsView.body`:

```swift
                if selectedTab == .expense {
                    // 4. When do I spend?
                    SpendingTimingCard(...)

                    // 5. Biggest hits
                    TopTransactionsList(...)

                    // 6. Category deep-dive
                    CategoryPerformanceList(...)
                }
```

Add the Annual section as the last item inside the `if selectedTab == .expense` block:

```swift
                if selectedTab == .expense {
                    SpendingTimingCard(
                        transactions: currentMonthTransactions,
                        currentDate: currentDate
                    )
                    TopTransactionsList(transactions: chartTransactions)
                    CategoryPerformanceList(
                        currentTransactions: chartTransactions,
                        previous3Months: previous3Months,
                        transactionStore: transactionStore
                    )

                    // 7. Annual expenses
                    if !annualTransactionsForYear.isEmpty {
                        AnnualExpensesSection(
                            transactions: annualTransactionsForYear,
                            year: Calendar.current.component(.year, from: currentDate)
                        )
                    }
                }
```

- [ ] **Step 3: Add `AnnualExpensesSection` component**

Add this new struct after `CategoryDetailView` (around line 765) and before `ExpenseTrendChart`:

```swift
struct AnnualExpensesSection: View {
    let transactions: [Transaction]
    let year: Int
    @EnvironmentObject var theme: ThemeManager

    private var total: Double { transactions.reduce(0.0) { $0 + $1.amount } }
    private var monthlyAverage: Double { total / 12.0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Text("Annual Expenses")
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)
                Spacer()
                Text(String(year))
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(theme.cardBackground)
                    .cornerRadius(8)
            }

            // Summary
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ยอดรวมทั้งปี")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                    Text(total.formattedCurrency)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(theme.expense)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("เฉลี่ยต่อเดือน")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                    Text(monthlyAverage.formattedCurrency)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(theme.accent)
                }
            }
            .padding()
            .background(theme.cardBackground)
            .cornerRadius(12)

            // List
            let sorted = transactions.sorted { $0.date < $1.date }
            ForEach(Array(sorted.enumerated()), id: \.element.id) { index, tx in
                let cat = tx.categoryId ?? .others
                HStack(spacing: 12) {
                    Image(systemName: cat.icon)
                        .foregroundColor(cat.color)
                        .font(.subheadline)
                        .frame(width: 38, height: 38)
                        .background(cat.color.opacity(0.12))
                        .cornerRadius(10)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(tx.description.isEmpty ? cat.displayName : tx.description)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(theme.textPrimary)
                            .lineLimit(1)
                        Text("\(cat.displayName) · \(tx.date.formatted(.dateTime.month(.abbreviated)))")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(tx.amount.formattedCurrency)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.expense)
                        Text("≈ \((tx.amount / 12).formattedCurrency)/เดือน")
                            .font(.caption)
                            .foregroundColor(theme.accent)
                    }
                }

                if index < sorted.count - 1 {
                    Divider()
                }
            }
        }
        .padding()
        .background(theme.background)
        .padding(.horizontal)
    }
}
```

- [ ] **Step 4: Build and verify**

```bash
xcodebuild build -scheme BROKE -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 5: Commit**

```bash
git add BROKE/Views/AnalyticsView.swift
git commit -m "feat: add AnnualExpensesSection to AnalyticsView"
```

---

## Task 4: Annual monthly burden in HomeView

**Files:**
- Modify: `BROKE/Views/HomeView.swift`

- [ ] **Step 1: Add `annualMonthlyBurden` computed var**

In `HomeView`, add this private computed var inside the `HomeView` struct. Find the block where `transactionStore` is used (the `@EnvironmentObject var transactionStore: TransactionStore` is at line 20). Add after the existing `@EnvironmentObject` declarations:

```swift
private var annualMonthlyBurden: Double {
    let currentYear = Calendar.current.component(.year, from: Date())
    return annualExpenses(from: transactionStore.getAllTransactions(), year: currentYear)
        .reduce(0.0) { $0 + $1.amount } / 12.0
}
```

- [ ] **Step 2: Add burden info row below the hero stats**

Find the line that contains `HeroStatPill(label: "OUT"...` (around line 247). It's inside a `VStack` or `HStack`. Add a new line **after** that `HeroStatPill` block, still inside the same parent container:

```swift
if annualMonthlyBurden > 0 {
    HStack(spacing: 4) {
        Image(systemName: "calendar.circle")
            .font(.caption)
        Text("Annual burden ≈ \(annualMonthlyBurden.formattedCurrency)/mo")
            .font(.caption)
    }
    .foregroundColor(theme.textSecondary)
    .padding(.top, 4)
}
```

- [ ] **Step 3: Build and run tests**

```bash
xcodebuild test -scheme BROKE -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "PASSED|FAILED|error:|BUILD" | head -20
```

Expected: `BUILD SUCCEEDED`, all tests PASSED

- [ ] **Step 4: Commit**

```bash
git add BROKE/Views/HomeView.swift
git commit -m "feat: show annual monthly burden in HomeView"
```

---

## Done

All 4 tasks complete. The feature is fully implemented:
- ✅ `Transaction.isAnnual` model flag (backward compatible)
- ✅ Toggle in AddTransactionView (expense only, resets on type change, persisted in edit)
- ✅ `AnnualExpensesSection` card in AnalyticsView (year-filtered, sorted by date)
- ✅ Annual burden info row in HomeView (current year, informational only)

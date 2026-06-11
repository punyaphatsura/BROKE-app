# AnalyticsView Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current AnalyticsView with a story-driven single-scroll page featuring an expense trend line, daily spending heatmap, day-of-week bars, top transactions list, and per-category sparklines — while removing the five weak/redundant sections.

**Architecture:** All component structs live in `BROKE/Views/AnalyticsView.swift` (matching the existing convention). New data-computation helpers are pure free functions (fileprivate), making them unit-testable without SwiftUI. New components receive pre-computed data as `let` props — no EnvironmentObject fetching inside sub-components beyond `ThemeManager`.

**Tech Stack:** SwiftUI, Swift Charts (`AreaMark`, `LineMark`), `Calendar`, `BROKETests` (Swift Testing `@Test`)

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `BROKE/Views/AnalyticsView.swift` | Modify | Remove 5 deprecated structs + body call sites. Add `ExpenseTrendChart`, `SpendingTimingCard`, `TopTransactionsList`. Enhance `CategoryPerformanceList` with sparklines. Rewire `AnalyticsView` body. |
| `BROKETests/BROKETests.swift` | Modify | Unit tests for new pure data helpers. |

---

## Task 1: Remove deprecated components and their computed properties

**Files:**
- Modify: `BROKE/Views/AnalyticsView.swift`

These structs and computed properties are being removed. Remove them all in one pass.

**Structs to delete (entire struct definitions):**
- `MonthlyTotalsBar` (line ~789)
- `MonthlyTotalsChart` (line ~795)
- `ComparisonTagView` (line ~479)
- `BehaviorInsightCard` (line ~709)
- `MascotInsightPill` (line ~859)
- `MonthlyComparisonChart` (line ~507)

**Computed properties to delete from `AnalyticsView`:**
- `averageMonthlyExpense3Months` — only used by removed components
- `comparisonToAverage` — only used by `ComparisonTagView`

**Call sites to remove from `AnalyticsView.body`:**
```swift
// DELETE these blocks entirely:
MonthlyTotalsChart(transactions: transactionStore.getAllTransactions())
    .padding(.top, 8)

if selectedTab == .expense {
    ComparisonTagView(...)
    BehaviorInsightCard(...)
    MascotInsightPill(transactions: currentMonthTransactions)
}

if selectedTab == .expense {
    MonthlyComparisonChart(...)
}
```

- [ ] **Step 1: Delete the 6 deprecated struct definitions**

Open `BROKE/Views/AnalyticsView.swift`. Delete the following complete struct bodies:
- `struct MonthlyTotalsBar` and `struct MonthlyTotalsChart`
- `struct ComparisonTagView`
- `struct BehaviorInsightCard`
- `private struct MascotInsightPill`
- `struct MonthlyComparisonChart`

Also delete the `Int.formattedWithSeparator` extension only if nothing else uses it — check with grep first:
```bash
grep -n "formattedWithSeparator" BROKE/Views/AnalyticsView.swift
```
Keep it if `CategoryPerformanceList` still references it (it does).

- [ ] **Step 2: Delete `averageMonthlyExpense3Months` and `comparisonToAverage`**

In the `AnalyticsView` struct, delete these two computed properties:
```swift
// DELETE:
private var averageMonthlyExpense3Months: Double { ... }
private var comparisonToAverage: (diff: Double, isLower: Bool) { ... }
```

- [ ] **Step 3: Remove call sites from `AnalyticsView.body`**

In `var body: some View`, remove:
```swift
MonthlyTotalsChart(transactions: transactionStore.getAllTransactions())
    .padding(.top, 8)
```
And the entire two `if selectedTab == .expense { }` blocks that contain `ComparisonTagView`, `BehaviorInsightCard`, `MascotInsightPill`, and `MonthlyComparisonChart`.

Leave the `CategoryPerformanceList` block (it's in its own `if selectedTab == .expense { }`) — keep that.

- [ ] **Step 4: Build and verify the project compiles**

Open the project in Xcode and build (`Cmd+B`). Expected: build succeeds with no errors. Fix any "use of unresolved identifier" errors from leftover references to deleted symbols.

- [ ] **Step 5: Commit**

```bash
git add BROKE/Views/AnalyticsView.swift
git commit -m "refactor: remove deprecated analytics components (MonthlyTotalsChart, ComparisonTagView, BehaviorInsightCard, MascotInsightPill, MonthlyComparisonChart)"
```

---

## Task 2: Add unit-tested data helper functions

**Files:**
- Modify: `BROKE/Views/AnalyticsView.swift` (add helpers at bottom, before closing brace of file)
- Modify: `BROKETests/BROKETests.swift`

Add three pure fileprivate functions that the new components will consume. Test them before wiring them up.

The helpers go at the **bottom of `AnalyticsView.swift`**, after the existing `flattenTransactions` helper:

```swift
/// Returns total expense per month for the last `months` months ending at `referenceDate`.
/// Result is sorted oldest → newest. Each tuple: (first-of-month Date, total expense Double).
fileprivate func expenseTotals(
    from transactions: [Transaction],
    months: Int,
    referenceDate: Date
) -> [(month: Date, total: Double)] {
    let calendar = Calendar.current
    return (0..<months).reversed().compactMap { offset -> (Date, Double)? in
        guard let date = calendar.date(byAdding: .month, value: -offset, to: referenceDate),
              let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date))
        else { return nil }
        let y = calendar.component(.year, from: date)
        let m = calendar.component(.month, from: date)
        let total = transactions
            .filter { $0.type == .expense
                && calendar.component(.year, from: $0.date) == y
                && calendar.component(.month, from: $0.date) == m }
            .reduce(0.0) { $0 + $1.amount }
        return (monthStart, total)
    }
}

/// Returns a dict of day-of-month → total expense for the given month.
/// `referenceDate` can be any date within the target month.
fileprivate func dailySpend(
    from transactions: [Transaction],
    referenceDate: Date
) -> [Int: Double] {
    let calendar = Calendar.current
    let y = calendar.component(.year, from: referenceDate)
    let m = calendar.component(.month, from: referenceDate)
    let monthTxns = transactions.filter {
        $0.type == .expense
        && calendar.component(.year, from: $0.date) == y
        && calendar.component(.month, from: $0.date) == m
    }
    var result: [Int: Double] = [:]
    for t in monthTxns {
        let day = calendar.component(.day, from: t.date)
        result[day, default: 0] += t.amount
    }
    return result
}

/// Returns a dict of weekday (1=Sun...7=Sat) → average spend across all occurrences of
/// that weekday in the given month.
fileprivate func weekdayAverages(
    from transactions: [Transaction],
    referenceDate: Date
) -> [Int: Double] {
    let calendar = Calendar.current
    let y = calendar.component(.year, from: referenceDate)
    let m = calendar.component(.month, from: referenceDate)
    // Count how many times each weekday appears in the month
    guard let range = calendar.range(of: .day, in: .month, for: referenceDate),
          let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: referenceDate))
    else { return [:] }
    var weekdayCounts: [Int: Int] = [:]
    for day in range {
        if let d = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
            let wd = calendar.component(.weekday, from: d)
            weekdayCounts[wd, default: 0] += 1
        }
    }
    // Sum spend per weekday
    let monthTxns = transactions.filter {
        $0.type == .expense
        && calendar.component(.year, from: $0.date) == y
        && calendar.component(.month, from: $0.date) == m
    }
    var sums: [Int: Double] = [:]
    for t in monthTxns {
        let wd = calendar.component(.weekday, from: t.date)
        sums[wd, default: 0] += t.amount
    }
    // Divide by count to get average
    var result: [Int: Double] = [:]
    for (wd, count) in weekdayCounts {
        result[wd] = (sums[wd] ?? 0) / Double(count)
    }
    return result
}
```

- [ ] **Step 1: Write the failing tests in `BROKETests/BROKETests.swift`**

Replace the file content with:

```swift
import Testing
import Foundation
@testable import BROKE

struct AnalyticsHelpersTests {

    // MARK: - Helpers

    private func makeExpense(amount: Double, daysAgo: Int) -> Transaction {
        Transaction(
            amount: amount,
            description: "test",
            date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
            type: .expense,
            source: .manual
        )
    }

    // MARK: - expenseTotals

    @Test func expenseTotals_currentMonthOnly() {
        let t = makeExpense(amount: 100, daysAgo: 0)
        let results = expenseTotals(from: [t], months: 1, referenceDate: Date())
        #expect(results.count == 1)
        #expect(results[0].total == 100)
    }

    @Test func expenseTotals_ignoresIncome() {
        var income = makeExpense(amount: 500, daysAgo: 0)
        income.type = .income
        let results = expenseTotals(from: [income], months: 1, referenceDate: Date())
        #expect(results[0].total == 0)
    }

    @Test func expenseTotals_returns12MonthsOldestFirst() {
        let results = expenseTotals(from: [], months: 12, referenceDate: Date())
        #expect(results.count == 12)
        // oldest month should be earlier than newest
        #expect(results[0].month <= results[11].month)
    }

    // MARK: - dailySpend

    @Test func dailySpend_sumsCorrectDay() {
        let t1 = makeExpense(amount: 200, daysAgo: 0)  // today
        let t2 = makeExpense(amount: 300, daysAgo: 0)  // also today
        let result = dailySpend(from: [t1, t2], referenceDate: Date())
        let today = Calendar.current.component(.day, from: Date())
        #expect(result[today] == 500)
    }

    @Test func dailySpend_ignoresOtherMonths() {
        let t = makeExpense(amount: 999, daysAgo: 40) // ~40 days ago = different month
        let result = dailySpend(from: [t], referenceDate: Date())
        #expect(result.values.reduce(0, +) == 0)
    }

    // MARK: - weekdayAverages

    @Test func weekdayAverages_allWeekdaysPresent() {
        let result = weekdayAverages(from: [], referenceDate: Date())
        // Should have all 7 weekdays (each with avg 0)
        #expect(result.count == 7)
    }

    @Test func weekdayAverages_averagesCorrectly() {
        // Create two transactions on the same weekday (today) in the current month
        let t1 = makeExpense(amount: 100, daysAgo: 0)
        let t2 = makeExpense(amount: 100, daysAgo: 0) // same day
        let result = weekdayAverages(from: [t1, t2], referenceDate: Date())
        let todayWd = Calendar.current.component(.weekday, from: Date())
        // Count how many times this weekday appears in the month
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: Date())!
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        let count = range.filter { day in
            let d = calendar.date(byAdding: .day, value: day - 1, to: monthStart)!
            return calendar.component(.weekday, from: d) == todayWd
        }.count
        let expected = 200.0 / Double(count)
        #expect(abs((result[todayWd] ?? 0) - expected) < 0.01)
    }
}
```

- [ ] **Step 2: Run tests — expect compilation failure (helpers not yet defined)**

In Xcode: `Cmd+U` (run tests). Expected: build fails with "use of unresolved identifier 'expenseTotals'" etc.

- [ ] **Step 3: Add the three helper functions to `AnalyticsView.swift`**

At the bottom of the file, after the existing `flattenTransactions` function, add the three functions exactly as shown above (`expenseTotals`, `dailySpend`, `weekdayAverages`).

- [ ] **Step 4: Run tests — expect all pass**

`Cmd+U`. Expected: all `AnalyticsHelpersTests` tests pass. Fix any failures before continuing.

- [ ] **Step 5: Commit**

```bash
git add BROKE/Views/AnalyticsView.swift BROKETests/BROKETests.swift
git commit -m "feat: add unit-tested analytics data helper functions (expenseTotals, dailySpend, weekdayAverages)"
```

---

## Task 3: Build `ExpenseTrendChart`

**Files:**
- Modify: `BROKE/Views/AnalyticsView.swift`

Add this struct to `AnalyticsView.swift`, below the existing `CategoryDetailView`. It replaces `MonthlyTotalsChart`.

- [ ] **Step 1: Add `ExpenseTrendChart` struct**

Add the following struct to `AnalyticsView.swift`:

```swift
struct ExpenseTrendChart: View {
    let transactions: [Transaction]
    let currentDate: Date
    @EnvironmentObject var theme: ThemeManager

    private var monthlyData: [(month: Date, total: Double)] {
        expenseTotals(from: transactions, months: 12, referenceDate: currentDate)
    }

    private var sixMonthAvg: Double {
        let last6 = expenseTotals(from: transactions, months: 6, referenceDate: currentDate)
        let sum = last6.reduce(0.0) { $0 + $1.total }
        return last6.isEmpty ? 0 : sum / Double(last6.count)
    }

    private var sixMonthLow: Double {
        expenseTotals(from: transactions, months: 6, referenceDate: currentDate)
            .map(\.total).min() ?? 0
    }

    private var currentTotal: Double {
        monthlyData.last?.total ?? 0
    }

    private var vsAvgPct: Double {
        guard sixMonthAvg > 0 else { return 0 }
        return ((currentTotal - sixMonthAvg) / sixMonthAvg) * 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Spending Over Time")
                .font(.headline)
                .foregroundColor(theme.textPrimary)

            Chart(monthlyData, id: \.month) { item in
                AreaMark(
                    x: .value("Month", item.month, unit: .month),
                    y: .value("Expense", item.total)
                )
                .foregroundStyle(theme.expense.opacity(0.15))

                LineMark(
                    x: .value("Month", item.month, unit: .month),
                    y: .value("Expense", item.total)
                )
                .foregroundStyle(theme.expense)
                .lineStyle(StrokeStyle(lineWidth: 2))

                if item.month == monthlyData.last?.month {
                    PointMark(
                        x: .value("Month", item.month, unit: .month),
                        y: .value("Expense", item.total)
                    )
                    .foregroundStyle(theme.expense)
                    .symbolSize(40)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) {
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                        .foregroundStyle(theme.textSecondary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisValueLabel()
                        .foregroundStyle(theme.textSecondary)
                }
            }
            .frame(height: 160)

            HStack {
                Text("6-mo low: \(sixMonthLow.formattedCurrency)")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                Spacer()
                let isHigher = vsAvgPct >= 0
                Text("\(isHigher ? "↑" : "↓") \(Int(abs(vsAvgPct)))% vs avg")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isHigher ? theme.expense : theme.income)
            }
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}
```

- [ ] **Step 2: Wire it into `AnalyticsView.body`**

In `AnalyticsView.body`, after `MonthYearNavigator` and `SummaryStatsBoard`, add:

```swift
ExpenseTrendChart(
    transactions: transactionStore.getAllTransactions(),
    currentDate: currentDate
)
```

- [ ] **Step 3: Build (`Cmd+B`) and verify the chart renders in Xcode Preview**

Add a preview to `ExpenseTrendChart` temporarily if needed:
```swift
#Preview {
    ExpenseTrendChart(
        transactions: [],
        currentDate: Date()
    )
    .environmentObject(ThemeManager())
}
```

Expected: chart renders (empty state shows flat line at 0). No build errors.

- [ ] **Step 4: Commit**

```bash
git add BROKE/Views/AnalyticsView.swift
git commit -m "feat: add ExpenseTrendChart with 12-month area line and vs-avg stat chips"
```

---

## Task 4: Build `SpendingTimingCard` (heatmap + weekday bars)

**Files:**
- Modify: `BROKE/Views/AnalyticsView.swift`

This card has two sub-views in an `HStack`. The left is a calendar grid; the right is horizontal bars per weekday.

- [ ] **Step 1: Add `SpendingTimingCard` struct**

Add after `ExpenseTrendChart`:

```swift
struct SpendingTimingCard: View {
    let transactions: [Transaction]
    let currentDate: Date
    @EnvironmentObject var theme: ThemeManager

    private var daily: [Int: Double] {
        dailySpend(from: transactions, referenceDate: currentDate)
    }

    private var weekdayAvgs: [Int: Double] {
        weekdayAverages(from: transactions, referenceDate: currentDate)
    }

    private var maxDailySpend: Double {
        daily.values.max() ?? 1
    }

    private var maxWeekdayAvg: Double {
        weekdayAvgs.values.max() ?? 1
    }

    // Number of days in the selected month
    private var daysInMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: currentDate)?.count ?? 30
    }

    // Weekday (1=Sun) of the 1st of the month — used to offset the grid
    private var firstWeekday: Int {
        let calendar = Calendar.current
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)) else { return 1 }
        return calendar.component(.weekday, from: monthStart)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("When Do You Spend?")
                .font(.headline)
                .foregroundColor(theme.textPrimary)

            HStack(alignment: .top, spacing: 16) {
                // Left: Daily heatmap
                VStack(alignment: .leading, spacing: 4) {
                    Text("This Month")
                        .font(.caption2)
                        .foregroundColor(theme.textSecondary)

                    let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 7)
                    let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]

                    LazyVGrid(columns: columns, spacing: 3) {
                        // Day-of-week header — use index to avoid duplicate-id crash
                        ForEach(0..<dayLabels.count, id: \.self) { i in
                            Text(dayLabels[i])
                                .font(.system(size: 8))
                                .foregroundColor(theme.textSecondary)
                                .frame(maxWidth: .infinity)
                        }
                        // Empty offset cells before day 1
                        ForEach(0..<(firstWeekday - 1), id: \.self) { _ in
                            Color.clear.frame(height: 14)
                        }
                        // Day cells
                        ForEach(1...daysInMonth, id: \.self) { day in
                            let spend = daily[day] ?? 0
                            let intensity = maxDailySpend > 0 ? spend / maxDailySpend : 0
                            RoundedRectangle(cornerRadius: 3)
                                .fill(theme.expense.opacity(0.08 + intensity * 0.92))
                                .frame(height: 14)
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                // Right: Weekday average bars
                VStack(alignment: .leading, spacing: 4) {
                    Text("Avg by Day")
                        .font(.caption2)
                        .foregroundColor(theme.textSecondary)

                    // weekday labels: 2=Mon ... 7=Sat, 1=Sun — display Mon-Sun order
                    let weekdayOrder: [(label: String, wd: Int)] = [
                        ("Mon", 2), ("Tue", 3), ("Wed", 4),
                        ("Thu", 5), ("Fri", 6), ("Sat", 7), ("Sun", 1)
                    ]
                    ForEach(weekdayOrder, id: \.wd) { item in
                        HStack(spacing: 4) {
                            Text(item.label)
                                .font(.system(size: 9))
                                .foregroundColor(theme.textSecondary)
                                .frame(width: 22, alignment: .leading)
                            GeometryReader { geo in
                                let avg = weekdayAvgs[item.wd] ?? 0
                                let ratio = maxWeekdayAvg > 0 ? avg / maxWeekdayAvg : 0
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(theme.expense.opacity(0.3 + ratio * 0.7))
                                    .frame(width: geo.size.width * ratio, height: 10)
                            }
                            .frame(height: 10)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}
```

- [ ] **Step 2: Wire it into `AnalyticsView.body`**

Add inside the `if selectedTab == .expense { }` block that wraps expense-only sections, after `CategoryBreakdownChart`:

```swift
SpendingTimingCard(
    transactions: currentMonthTransactions,
    currentDate: currentDate
)
```

- [ ] **Step 3: Build (`Cmd+B`) and check preview**

Expected: card renders with a calendar grid on the left and horizontal bars on the right. No crashes.

- [ ] **Step 4: Commit**

```bash
git add BROKE/Views/AnalyticsView.swift
git commit -m "feat: add SpendingTimingCard with daily heatmap and weekday average bars"
```

---

## Task 5: Build `TopTransactionsList`

**Files:**
- Modify: `BROKE/Views/AnalyticsView.swift`

Shows the top 5 expenses by amount for the selected month. Hidden if fewer than 3 transactions exist.

- [ ] **Step 1: Add `TopTransactionsList` struct**

Add after `SpendingTimingCard`:

```swift
struct TopTransactionsList: View {
    let transactions: [Transaction]
    @EnvironmentObject var theme: ThemeManager

    private var top5: [Transaction] {
        Array(transactions
            .sorted { $0.amount > $1.amount }
            .prefix(5))
    }

    var body: some View {
        if transactions.count >= 3 {
            VStack(alignment: .leading, spacing: 12) {
                Text("Biggest Spends This Month")
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)

                ForEach(top5) { tx in
                    HStack(spacing: 12) {
                        // Category icon
                        let cat = tx.categoryId ?? .others
                        Image(systemName: cat.icon)
                            .foregroundColor(cat.color)
                            .font(.subheadline)
                            .frame(width: 36, height: 36)
                            .background(cat.color.opacity(0.12))
                            .cornerRadius(10)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(tx.description.isEmpty ? cat.displayName : tx.description)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(theme.textPrimary)
                                .lineLimit(1)

                            let dateStr = tx.date.formatted(.dateTime.month(.abbreviated).day())
                            Text("\(cat.displayName) · \(dateStr)")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        }

                        Spacer()

                        Text(tx.amount.formattedCurrency)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.expense)
                    }
                }
            }
            .padding()
            .background(theme.cardBackground)
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
}
```

- [ ] **Step 2: Wire it into `AnalyticsView.body`**

Inside the expense-only section, after `SpendingTimingCard`:

```swift
TopTransactionsList(transactions: chartTransactions)
```

(`chartTransactions` is already filtered to the current month + selected type.)

- [ ] **Step 3: Build (`Cmd+B`) and verify**

Expected: card appears when there are 3+ expense transactions for the month; hidden otherwise.

- [ ] **Step 4: Commit**

```bash
git add BROKE/Views/AnalyticsView.swift
git commit -m "feat: add TopTransactionsList showing top 5 expenses by amount"
```

---

## Task 6: Add per-category sparklines to `CategoryPerformanceList`

**Files:**
- Modify: `BROKE/Views/AnalyticsView.swift`

Extend the `CategoryPerf` model to carry a 4-month trend array and render a `LineMark` sparkline on each row.

- [ ] **Step 1: Extend `CategoryPerf` with `monthlyTrend`**

Find `struct CategoryPerf` inside `CategoryPerformanceList` and add one field:

```swift
struct CategoryPerf: Identifiable {
    let id = UUID()
    let category: ExpenseCategory
    let currentAmount: Double
    let avgPast: Double
    let monthlyTrend: [Double]  // [3mo ago, 2mo ago, 1mo ago, current] oldest→newest
    var delta: Double { currentAmount - avgPast }
    var isLower: Bool { delta < 0 }
}
```

- [ ] **Step 2: Populate `monthlyTrend` in the `rows` computed property**

In the `rows` computed property inside `CategoryPerformanceList`, update the loop to collect per-month amounts:

```swift
private var rows: [CategoryPerf] {
    let grouped = Dictionary(grouping: currentTransactions, by: { $0.categoryId ?? .others })
    var result: [CategoryPerf] = []
    let calendar = Calendar.current

    for (cat, txs) in grouped {
        let currentSum = txs.reduce(0.0) { $0 + $1.amount }

        var perMonth: [Double] = []
        for date in previous3Months.reversed() { // reversed: oldest first
            let y = calendar.component(.year, from: date)
            let m = calendar.component(.month, from: date)
            let monthTxs = transactionStore.getAllTransactions().filter {
                let ty = calendar.component(.year, from: $0.date)
                let tm = calendar.component(.month, from: $0.date)
                return ty == y && tm == m && $0.type == .expense
            }
            let flattened = flattenTransactions(monthTxs)
            let catSum = flattened.filter { $0.categoryId == cat }
                .reduce(0.0) { $0 + $1.amount }
            perMonth.append(catSum)
        }
        perMonth.append(currentSum) // current month last

        let pastSum = perMonth.dropLast().reduce(0.0, +)
        let avg = previous3Months.isEmpty ? 0 : pastSum / Double(previous3Months.count)

        result.append(CategoryPerf(
            category: cat,
            currentAmount: currentSum,
            avgPast: avg,
            monthlyTrend: perMonth
        ))
    }
    return result.sorted { $0.currentAmount > $1.currentAmount }
}
```

- [ ] **Step 3: Add sparkline rendering inside the row `HStack`**

Find the row `HStack` inside `CategoryPerformanceList.body` (the `ForEach(rows)` loop). Add the sparkline between the `VStack(alignment: .leading)` and `Spacer()`:

```swift
// Sparkline — insert after the VStack that shows name+delta, before Spacer()
let trendColor = (row.monthlyTrend.last ?? 0) <= (row.monthlyTrend.first ?? 0)
    ? theme.income : theme.expense
SparklineView(values: row.monthlyTrend, color: trendColor)
    .frame(width: 50, height: 20)
```

Then add the `SparklineView` struct outside `CategoryPerformanceList` (at file scope, near the bottom):

```swift
private struct SparklineView: View {
    let values: [Double]
    let color: Color

    var body: some View {
        if values.count >= 2 {
            let maxVal = values.max() ?? 1
            let minVal = values.min() ?? 0
            let range = maxVal - minVal

            Chart(Array(values.enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("Month", index),
                    y: .value("Amount", value)
                )
                .foregroundStyle(color)
                .lineStyle(StrokeStyle(lineWidth: 1.5))

                if index == values.count - 1 {
                    PointMark(
                        x: .value("Month", index),
                        y: .value("Amount", value)
                    )
                    .foregroundStyle(color)
                    .symbolSize(20)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartYScale(domain: max(0, minVal - range * 0.1)...maxVal + range * 0.1)
        }
    }
}
```

- [ ] **Step 4: Build (`Cmd+B`) and verify**

Expected: each category row shows a small sparkline between the delta label and the amount. Build succeeds with no errors.

- [ ] **Step 5: Commit**

```bash
git add BROKE/Views/AnalyticsView.swift
git commit -m "feat: add 4-month sparklines to CategoryPerformanceList rows"
```

---

## Task 7: Final body wiring and section ordering

**Files:**
- Modify: `BROKE/Views/AnalyticsView.swift`

Ensure the final `AnalyticsView.body` matches the spec order exactly. Clean up any leftover structure.

- [ ] **Step 1: Verify final `AnalyticsView.body` order**

The body should be exactly:

```swift
var body: some View {
    ScrollView {
        VStack(spacing: 24) {
            // 1. How much this month?
            MonthYearNavigator(currentDate: $currentDate)
            SummaryStatsBoard(stats: monthStats)

            // 2. Am I spending more or less lately?
            ExpenseTrendChart(
                transactions: transactionStore.getAllTransactions(),
                currentDate: currentDate
            )

            // 3. Where did it go? (filter + donut)
            TypeFilterTabs(selectedTab: $selectedTab)
            CategoryBreakdownChart(
                transactions: chartTransactions,
                contextMonth: currentDate,
                contextType: selectedTab,
                totalAmount: selectedTab == .expense ? monthStats.expense : (selectedTab == .income ? monthStats.income : 0)
            )

            // Expense-only sections
            if selectedTab == .expense {
                // 4. When do I spend?
                SpendingTimingCard(
                    transactions: currentMonthTransactions,
                    currentDate: currentDate
                )

                // 5. Biggest hits
                TopTransactionsList(transactions: chartTransactions)

                // 6. Category deep-dive
                CategoryPerformanceList(
                    currentTransactions: chartTransactions,
                    previous3Months: previous3Months,
                    transactionStore: transactionStore
                )
            }

            Spacer(minLength: 50)
        }
        .padding(.vertical)
    }
    .background(theme.background.ignoresSafeArea())
    .navigationBarTitleDisplayMode(.inline)
}
```

- [ ] **Step 2: Build and run on simulator**

Run the app on a simulator (iPhone 15 or similar). Navigate to the Analytics tab. Verify:
- Month nav and stats appear at top
- Trend chart shows below
- Filter tabs + donut appear
- Switching to Income tab hides sections 4–6
- Switching back to Expense shows heatmap, top transactions, category list with sparklines
- No crashes

- [ ] **Step 3: Commit**

```bash
git add BROKE/Views/AnalyticsView.swift
git commit -m "feat: complete AnalyticsView redesign - story-driven scroll layout"
```

---

## Verification Checklist

Before calling this done, confirm:

- [ ] All 5 deprecated structs are gone (grep: `MonthlyTotalsChart\|ComparisonTagView\|BehaviorInsightCard\|MascotInsightPill\|MonthlyComparisonChart`)
- [ ] All unit tests pass (`Cmd+U`)
- [ ] Build succeeds with zero warnings introduced by this work
- [ ] Income tab: shows only nav, stats, trend, filter tabs, donut — no timing card, no top transactions, no category performance
- [ ] Expense tab: all 6 sections visible
- [ ] Empty month (no transactions): app does not crash — trend shows flat line, heatmap shows all-grey cells, top transactions card is hidden

# AnalyticsView Redesign — Design Spec

**Date:** 2026-06-12  
**Scope:** Full overhaul of `BROKE/Views/AnalyticsView.swift`

---

## Overview

Replace the current AnalyticsView with a story-driven single-scroll page that takes the user from a high-level monthly summary down to granular category detail. The new layout removes weak/redundant sections, keeps what works, and adds targeted expense-focused visualizations.

---

## What Changes

### Removed
- `MonthlyTotalsChart` — plain 6-month bar chart replaced by trend line with context
- `ComparisonTagView` — "Lower/Higher than avg" pill absorbed into trend line stat
- `BehaviorInsightCard` — rule-based text insight; weak signal, removed
- `MascotInsightPill` — duplicates weekend insight logic; removed
- `MonthlyComparisonChart` — stacked 4-month comparison bar; replaced by per-category sparklines

### Kept (unchanged in function, may get visual polish)
- `MonthYearNavigator` — month prev/next navigation
- `SummaryStatsBoard` — income / expense / balance numbers
- `TypeFilterTabs` — expense / income tab selector
- `CategoryBreakdownChart` — interactive donut
- `CategoryPerformanceList` — per-category rows with delta vs avg

### Added (new components)
- `ExpenseTrendChart` — 12-month area/line chart of total monthly expense
- `SpendingTimingCard` — two side-by-side mini-charts: daily heatmap + day-of-week bars
- `TopTransactionsList` — ranked list of top 5 largest transactions for the month
- ~~`CategoryQuotaBars`~~ — deferred: no per-category budget data exists in the model yet; this requires a future feature
- Per-category sparklines inside `CategoryPerformanceList` rows

---

## Page Order (Top → Bottom)

```
1. MonthYearNavigator + SummaryStatsBoard   ← How much this month?
2. ExpenseTrendChart                         ← Am I spending more or less lately?
3. TypeFilterTabs + CategoryBreakdownChart   ← Where did it go?
4. SpendingTimingCard                        ← When do I spend?
5. TopTransactionsList                       ← What were the biggest hits?
6. CategoryPerformanceList (with sparklines) ← Category deep-dive
```

Sections 3–6 only render for the Expense tab. Income tab shows only sections 1–3 (summary + donut for income categories).

---

## Component Specs

### 1. ExpenseTrendChart
- Renders a filled area line chart using Swift Charts `AreaMark` + `LineMark`
- X-axis: last 12 months
- Y-axis: total expense per month
- Annotates current month point with dot
- Below chart: two stat chips — "6-month low: ฿X" and "↑/↓ X% vs avg"
- Replaces the removed `MonthlyTotalsChart`

### 2. SpendingTimingCard
- A single card with two sub-views side by side in an `HStack`
- **Left — DailyHeatmap:** 7-column grid (Sun–Sat) of square cells for the selected month. Cell color intensity maps to spend amount using `theme.expense` at varying opacity (0.08 = zero spend, 1.0 = max spend day). Empty days before month start are blank.
- **Right — WeekdayBars:** Horizontal bar chart (Mon–Sun rows) showing average spend per weekday across the selected month. Uses `theme.expense` fill color. Bars scale relative to the max weekday.
- Both sub-views are non-interactive (display only)

### 3. TopTransactionsList
- Shows up to 5 transactions sorted by `amount` descending for the selected month + type
- Each row: category icon (rounded square, category color background) + description + "category · date" subtitle + amount
- Tapping a row navigates to `TransactionDetailView` (same nav pattern as existing rows)
- If fewer than 3 transactions exist, the card is hidden entirely

### 4. Per-category sparklines in CategoryPerformanceList
- Each `CategoryPerf` row gains a 4-point `LineMark` sparkline (last 4 months)
- Sparkline is 50×20pt, rendered inline between the delta label and the amount
- Color: `theme.income` (green) if trending down, `theme.expense` (red) if trending up
- Terminal dot (last month) is a filled circle

---

## Data Flow

No new data sources required. All new components consume:
- `transactionStore.getAllTransactions()` — existing source
- `currentDate` — existing `@State` on `AnalyticsView`
- `previous3Months` — existing computed property

`CategoryQuotaBars` is deferred — the existing "quota" concept in the codebase refers to SlipOK API scan quota, not per-category spending budgets. No budget model exists yet; this feature requires a separate spec.

---

## File Structure

All new component structs go in `AnalyticsView.swift` (matching the existing pattern where all analytics components live in one file). If the file exceeds ~1200 lines after the redesign, consider splitting into:
- `AnalyticsView.swift` — main view + `AnalyticsView` body
- `AnalyticsComponents.swift` — all sub-component structs

This split is optional — only do it if it aids readability.

---

## Out of Scope

- Income tab redesign (keep existing donut behavior for income)
- Budget quota management UI (setting/editing quotas)
- Any changes outside `AnalyticsView.swift` and its direct sub-components
- New model fields or persistence changes

# BROKE UI Redesign — Penguin/Dragon Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply penguin/dragon switchable theme + light/dark mode to every view in the BROKE app, using exact hex colors from the HTML redesign file, without changing any functionality.

**Architecture:** A new `ThemeManager` ObservableObject holds two `@AppStorage` values (`character` and `appearance`). It exposes computed `Color` properties for each token. All views read these via `@EnvironmentObject var theme: ThemeManager`. The root view applies `.preferredColorScheme()` to enforce light/dark/system.

**Tech Stack:** SwiftUI, UIKit (UIColor dynamic provider for system mode), @AppStorage for persistence, SF Symbols throughout.

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| Modify | `BROKE/Utils/Extensions.swift` | Add `Color(hex:)` initializer |
| Create | `BROKE/Utils/AppTheme.swift` | Enums + ThemeManager with all color tokens |
| Modify | `BROKE/BROKEApp.swift` | Inject ThemeManager as env object |
| Modify | `BROKE/ContentView.swift` | Apply preferredColorScheme + accent color |
| Modify | `BROKE/Views/HomeView.swift` | Replace hardcoded colors with theme tokens |
| Modify | `BROKE/Views/TransactionRow.swift` | Replace hardcoded colors with theme tokens |
| Modify | `BROKE/Views/TransactionListView.swift` | Replace hardcoded colors with theme tokens |
| Modify | `BROKE/Views/AddTransactionView.swift` | Replace hardcoded colors with theme tokens |
| Modify | `BROKE/Views/AnalyticsView.swift` | Replace hardcoded colors with theme tokens |
| Modify | `BROKE/Views/SettingsView.swift` | Add Appearance section (theme + mode pickers) |

---

## Task 1: Add Color(hex:) initializer to Extensions.swift

**Files:**
- Modify: `BROKE/Utils/Extensions.swift`

- [ ] **Step 1: Add hex initializer**

Open `BROKE/Utils/Extensions.swift` and replace the entire file with:

```swift
//
//  Extensions.swift
//  BROKE
//

import Foundation
import SwiftUI

extension Double {
    var formattedCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
xcodebuild build \
  -project /Users/jackkahod/Desktop/File/Project/Meow-Jod-Clone-App/BROKE.xcodeproj \
  -scheme BROKE \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add BROKE/Utils/Extensions.swift
git commit -m "feat: add Color(hex:) initializer to Extensions"
```

---

## Task 2: Create AppTheme.swift

**Files:**
- Create: `BROKE/Utils/AppTheme.swift`

- [ ] **Step 1: Create the file**

Create `BROKE/Utils/AppTheme.swift` with the following content:

```swift
//
//  AppTheme.swift
//  BROKE
//

import SwiftUI

enum ThemeCharacter: String, CaseIterable {
    case penguin, dragon
}

enum AppearanceMode: String, CaseIterable {
    case light, dark, system
}

class ThemeManager: ObservableObject {
    @AppStorage("themeCharacter") var character: ThemeCharacter = .penguin {
        willSet { objectWillChange.send() }
    }
    @AppStorage("appearanceMode") var appearance: AppearanceMode = .light {
        willSet { objectWillChange.send() }
    }

    var preferredColorScheme: ColorScheme? {
        switch appearance {
        case .light:  return .light
        case .dark:   return .dark
        case .system: return nil
        }
    }

    // MARK: - Public tokens

    var background: Color     { resolve(.background) }
    var cardBackground: Color { resolve(.cardBackground) }
    var primary: Color        { resolve(.primary) }
    var accent: Color         { resolve(.accent) }
    var textPrimary: Color    { resolve(.textPrimary) }
    var textSecondary: Color  { resolve(.textPrimary).opacity(0.5) }
    var income: Color         { resolve(.income) }
    var expense: Color        { resolve(.expense) }
    var separator: Color      { resolve(.primary).opacity(0.12) }

    // MARK: - Private

    private enum Token {
        case background, cardBackground, primary, accent, textPrimary, income, expense
    }

    private func resolve(_ token: Token) -> Color {
        switch appearance {
        case .light:
            return lightColor(token, for: character)
        case .dark:
            return darkColor(token, for: character)
        case .system:
            return Color(uiColor: UIColor { [self] traits in
                UIColor(
                    traits.userInterfaceStyle == .dark
                        ? self.darkColor(token, for: self.character)
                        : self.lightColor(token, for: self.character)
                )
            })
        }
    }

    private func lightColor(_ token: Token, for character: ThemeCharacter) -> Color {
        switch (character, token) {
        case (.penguin, .background):     return Color(hex: "F0F7FF")
        case (.penguin, .cardBackground): return Color(hex: "DDEEFF")
        case (.penguin, .primary):        return Color(hex: "3D9BF0")
        case (.penguin, .accent):         return Color(hex: "FFA94D")
        case (.penguin, .textPrimary):    return Color(hex: "1A1410")
        case (.penguin, .income):         return Color(hex: "1A8A50")
        case (.penguin, .expense):        return Color(hex: "D93030")
        case (.dragon, .background):      return Color(hex: "FFF6EC")
        case (.dragon, .cardBackground):  return Color(hex: "F0EEE9")
        case (.dragon, .primary):         return Color(hex: "F5BC1A")
        case (.dragon, .accent):          return Color(hex: "FF8A3D")
        case (.dragon, .textPrimary):     return Color(hex: "2A1F08")
        case (.dragon, .income):          return Color(hex: "1A8A50")
        case (.dragon, .expense):         return Color(hex: "CC3300")
        }
    }

    private func darkColor(_ token: Token, for character: ThemeCharacter) -> Color {
        switch (character, token) {
        case (.penguin, .background):     return Color(hex: "0A1628")
        case (.penguin, .cardBackground): return Color(hex: "0D2847")
        case (.penguin, .primary):        return Color(hex: "3D9BF0")
        case (.penguin, .accent):         return Color(hex: "FFA94D")
        case (.penguin, .textPrimary):    return Color(hex: "FFFCF1")
        case (.penguin, .income):         return Color(hex: "40C8A0")
        case (.penguin, .expense):        return Color(hex: "FF6B8A")
        case (.dragon, .background):      return Color(hex: "1C0E08")
        case (.dragon, .cardBackground):  return Color(hex: "2D1206")
        case (.dragon, .primary):         return Color(hex: "F5BC1A")
        case (.dragon, .accent):          return Color(hex: "FF8A3D")
        case (.dragon, .textPrimary):     return Color(hex: "FFFCF1")
        case (.dragon, .income):          return Color(hex: "40C8A0")
        case (.dragon, .expense):         return Color(hex: "FF6B8A")
        }
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
xcodebuild build \
  -project /Users/jackkahod/Desktop/File/Project/Meow-Jod-Clone-App/BROKE.xcodeproj \
  -scheme BROKE \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add BROKE/Utils/AppTheme.swift
git commit -m "feat: add ThemeManager with penguin/dragon light/dark color tokens"
```

---

## Task 3: Wire ThemeManager into BROKEApp + ContentView

**Files:**
- Modify: `BROKE/BROKEApp.swift`
- Modify: `BROKE/ContentView.swift`

- [ ] **Step 1: Update BROKEApp.swift**

Replace `BROKE/BROKEApp.swift` with:

```swift
//
//  BROKEApp.swift
//  BROKE
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
}

@main
struct BROKEApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject var transactionStore = TransactionStore()
    @StateObject var photoService = PhotoService()
    @StateObject var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(transactionStore)
                .environmentObject(photoService)
                .environmentObject(themeManager)
        }
    }
}
```

- [ ] **Step 2: Update ContentView.swift**

Replace `BROKE/ContentView.swift` with:

```swift
//
//  ContentView.swift
//  BROKE
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)

            NavigationStack {
                AnalyticsView()
            }
            .tabItem {
                Label("Analytics", systemImage: "chart.pie.fill")
            }
            .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
        .tint(theme.primary)
        .ignoresSafeArea()
        .preferredColorScheme(theme.preferredColorScheme)
    }
}

#Preview {
    ContentView()
        .environmentObject(TransactionStore())
        .environmentObject(ThemeManager())
}
```

- [ ] **Step 3: Build to verify**

```bash
xcodebuild build \
  -project /Users/jackkahod/Desktop/File/Project/Meow-Jod-Clone-App/BROKE.xcodeproj \
  -scheme BROKE \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
git add BROKE/BROKEApp.swift BROKE/ContentView.swift
git commit -m "feat: inject ThemeManager and apply tint + colorScheme at root"
```

---

## Task 4: Theme HomeView.swift

**Files:**
- Modify: `BROKE/Views/HomeView.swift`

Color substitutions to make:
- `Color(UIColor.secondarySystemGroupedBackground)` → `theme.cardBackground`
- `.foregroundColor(.green)` on income → `.foregroundColor(theme.income)`
- `.foregroundColor(.red)` on expense → `.foregroundColor(theme.expense)`
- `.background(Color.blue)` on scan button → `.background(theme.primary)`
- `Color.black.opacity(0.1)` shadow on thumbnail → keep as-is (neutral)

- [ ] **Step 1: Add theme environment object and update summaryView**

Replace the `summaryView` computed property in `HomeView.swift`:

```swift
// Add at top of HomeView struct (after existing @State vars):
@EnvironmentObject var theme: ThemeManager

// Replace summaryView:
private var summaryView: some View {
    HStack(spacing: 0) {
        VStack(alignment: .center) {
            Text("Income")
                .font(.caption)
                .foregroundColor(theme.textSecondary)
            Text(transactionStore.totalIncome().formattedCurrency)
                .font(.headline)
                .foregroundColor(theme.income)
        }
        .frame(maxWidth: .infinity)

        VStack(alignment: .center) {
            Text("Expense")
                .font(.caption)
                .foregroundColor(theme.textSecondary)
            Text(transactionStore.totalExpense().formattedCurrency)
                .font(.headline)
                .foregroundColor(theme.expense)
        }
        .frame(maxWidth: .infinity)
    }
    .padding(.vertical, 12)
    .background(theme.cardBackground)
    .cornerRadius(12)
    .padding(.horizontal)
    .padding(.bottom, 4)
}
```

- [ ] **Step 2: Update scanButton**

Replace the `scanButton` computed property:

```swift
private var scanButton: some View {
    Button(action: {
        triggerBatchScan()
    }) {
        HStack {
            Image(systemName: "arrow.triangle.2.circlepath")
            Text("Scan Remaining (\(unprocessedCount))")
        }
        .font(.caption.weight(.medium))
        .foregroundColor(.white)
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(theme.primary)
        .cornerRadius(15)
    }
}
```

- [ ] **Step 3: Update TransactionThumbnailView**

Replace the `TransactionThumbnailView` struct body at the bottom of `HomeView.swift`:

```swift
struct TransactionThumbnailView: View {
    let transaction: Transaction
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if let bank = transaction.bank, let iconName = bank.iconName {
                    Image(iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .cornerRadius(4)
                } else {
                    Image(systemName: "building.columns.fill")
                        .foregroundColor(theme.textSecondary)
                        .frame(width: 24, height: 24)
                }

                Spacer()

                Text(transaction.amount.formattedCurrency)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(theme.textPrimary)
            }

            Spacer()

            HStack {
                Spacer()
                if let category = transaction.categoryId {
                    Image(systemName: category.icon)
                        .font(.system(size: 24))
                        .foregroundColor(category.color)
                } else if let incomeCategory = transaction.incomeCategoryId {
                    Image(systemName: incomeCategory.icon)
                        .font(.system(size: 24))
                        .foregroundColor(incomeCategory.color)
                } else if transaction.type == .transfer {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 24))
                        .foregroundColor(theme.primary)
                } else {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 24))
                        .foregroundColor(theme.textSecondary)
                }
                Spacer()
            }

            Spacer()

            Text(transaction.date, style: .date)
                .font(.caption2)
                .foregroundColor(theme.textSecondary)
                .lineLimit(1)
        }
        .padding(8)
        .frame(width: 120, height: 100)
        .background(theme.cardBackground)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}
```

- [ ] **Step 4: Build to verify**

```bash
xcodebuild build \
  -project /Users/jackkahod/Desktop/File/Project/Meow-Jod-Clone-App/BROKE.xcodeproj \
  -scheme BROKE \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 5: Commit**

```bash
git add BROKE/Views/HomeView.swift
git commit -m "feat: apply theme colors to HomeView"
```

---

## Task 5: Theme TransactionRow.swift

**Files:**
- Modify: `BROKE/Views/TransactionRow.swift`

Color substitutions:
- `.green` / `.red` on amount → `theme.income` / `theme.expense`
- `.blue` on transfer icon → `theme.primary`
- `.primary` on name → `theme.textPrimary`
- `.secondary` on description → `theme.textSecondary`

- [ ] **Step 1: Replace TransactionRow.swift**

Replace the entire file `BROKE/Views/TransactionRow.swift`:

```swift
//
//  TransactionRow.swift
//  BROKE
//

import SwiftUI

struct TransactionRow: View {
    @EnvironmentObject var transactionStore: TransactionStore
    @EnvironmentObject var theme: ThemeManager
    let transaction: Transaction
    @State private var showingEditSheet = false

    var body: some View {
        HStack(spacing: 16) {
            if transaction.type == .expense {
                if let categoryId = transaction.categoryId,
                   let category = ExpenseCategory(rawValue: categoryId.rawValue) {
                    Menu {
                        ForEach(ExpenseCategory.allCases) { cat in
                            Button(action: {
                                var newTransaction = transaction
                                newTransaction.categoryId = cat
                                transactionStore.updateTransaction(newTransaction)
                            }) {
                                Label(cat.displayName, systemImage: cat.icon)
                            }
                        }
                    } label: {
                        Image(systemName: category.icon)
                            .foregroundColor(category.color)
                            .font(.title)
                    }
                }
            } else if transaction.type == .income {
                if let categoryId = transaction.incomeCategoryId,
                   let category = IncomeCategory(rawValue: categoryId.rawValue) {
                    Menu {
                        ForEach(IncomeCategory.allCases) { cat in
                            Button(action: {
                                var newTransaction = transaction
                                newTransaction.incomeCategoryId = cat
                                transactionStore.updateTransaction(newTransaction)
                            }) {
                                Label(cat.displayName, systemImage: cat.icon)
                            }
                        }
                    } label: {
                        Image(systemName: category.icon)
                            .foregroundColor(category.color)
                            .font(.title)
                    }
                }
            } else {
                Image(systemName: "arrow.left.arrow.right")
                    .foregroundColor(theme.primary)
                    .font(.title)
            }

            VStack(alignment: .leading) {
                if transaction.type == .expense {
                    if let category = transaction.categoryId {
                        Text(category.displayName)
                            .font(.headline)
                            .foregroundColor(theme.textPrimary)
                    }
                } else if transaction.type == .income {
                    if let category = transaction.incomeCategoryId {
                        Text(category.displayName)
                            .font(.headline)
                            .foregroundColor(theme.textPrimary)
                    }
                } else {
                    Text("Transfer")
                        .font(.headline)
                        .foregroundColor(theme.textPrimary)
                }
                Text(transaction.description)
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)

                if let subTransactions = transaction.subTransactions, !subTransactions.isEmpty {
                    Text(subTransactions.map { $0.categoryId.displayName }.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(transaction.amount.formattedCurrency)
                .font(.headline)
                .foregroundColor(
                    transaction.type == .income ? theme.income :
                    transaction.type == .expense ? theme.expense :
                    theme.textPrimary
                )
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                transactionStore.deleteTransactionById(transaction.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            AddTransactionView(transactionToEdit: transaction)
                .environmentObject(transactionStore)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showingEditSheet = true
        }
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
xcodebuild build \
  -project /Users/jackkahod/Desktop/File/Project/Meow-Jod-Clone-App/BROKE.xcodeproj \
  -scheme BROKE \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add BROKE/Views/TransactionRow.swift
git commit -m "feat: apply theme colors to TransactionRow"
```

---

## Task 6: Theme TransactionListView.swift

**Files:**
- Modify: `BROKE/Views/TransactionListView.swift`

Color substitutions:
- `.green` / `.red` in `TransactionSectionHeader` → `theme.income` / `theme.expense`
- `.primary` text → `theme.textPrimary`
- `.secondary` text → `theme.textSecondary`

- [ ] **Step 1: Replace TransactionListView.swift**

Replace the entire file `BROKE/Views/TransactionListView.swift`:

```swift
//
//  TransactionListView.swift
//  BROKE
//

import SwiftUI

struct TransactionListView: View {
    @EnvironmentObject var transactionStore: TransactionStore
    @EnvironmentObject var theme: ThemeManager
    @State private var showingAddTransaction = false
    @State private var filterType: TransactionType? = nil
    var customTransactions: [Transaction]?

    var filteredTransactions: [Transaction] {
        if let custom = customTransactions {
            return custom
        }
        if let filterType = filterType {
            return transactionStore.transactions.filter { $0.type == filterType }
        } else {
            return transactionStore.transactions
        }
    }

    var groupedTransactions: [(key: Date, value: [Transaction])] {
        let grouped = Dictionary(grouping: filteredTransactions) { transaction in
            Calendar.current.startOfDay(for: transaction.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    var body: some View {
        NavigationView {
            VStack {
                if customTransactions == nil {
                    Picker("Filter", selection: $filterType) {
                        Text("All").tag(nil as TransactionType?)
                        Text("Income").tag(TransactionType.income as TransactionType?)
                        Text("Expense").tag(TransactionType.expense as TransactionType?)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                }

                List {
                    ForEach(groupedTransactions, id: \.key) { section in
                        Section(header: TransactionSectionHeader(date: section.key, transactions: section.value)) {
                            ForEach(section.value.sorted(by: { $0.date > $1.date })) { transaction in
                                TransactionRow(transaction: transaction)
                            }
                            .onDelete { indexSet in
                                deleteTransactions(at: indexSet, in: section.value)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .toolbar {
                if customTransactions == nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingAddTransaction = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView()
            }
        }
    }

    private func deleteTransactions(at offsets: IndexSet, in transactions: [Transaction]) {
        let transactionsToDelete = offsets.map { transactions[$0] }
        for transaction in transactionsToDelete {
            if let index = transactionStore.transactions.firstIndex(where: { $0.id == transaction.id }) {
                transactionStore.transactions.remove(at: index)
            }
        }
        transactionStore.saveTransactions()
    }
}

struct TransactionSectionHeader: View {
    let date: Date
    let transactions: [Transaction]
    @EnvironmentObject var theme: ThemeManager

    var income: Double {
        transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    var expense: Double {
        transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .center, spacing: 2) {
                Text(date, format: .dateTime.weekday(.abbreviated))
                    .font(.caption)
                    .fontWeight(.bold)
                    .textCase(.uppercase)

                Text(date, format: .dateTime.day())
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .foregroundColor(theme.textPrimary)
            .frame(width: 50)

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                if income > 0 {
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.down.left")
                            .foregroundColor(theme.income)
                        Text(income.formattedCurrency)
                            .foregroundColor(theme.income)
                    }
                    .frame(maxWidth: .infinity)
                }

                if expense > 0 {
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(theme.expense)
                        Text(expense.formattedCurrency)
                            .foregroundColor(theme.expense)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minWidth: 120)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
xcodebuild build \
  -project /Users/jackkahod/Desktop/File/Project/Meow-Jod-Clone-App/BROKE.xcodeproj \
  -scheme BROKE \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add BROKE/Views/TransactionListView.swift
git commit -m "feat: apply theme colors to TransactionListView and TransactionSectionHeader"
```

---

## Task 7: Theme AddTransactionView.swift

**Files:**
- Modify: `BROKE/Views/AddTransactionView.swift`

Color substitutions:
- `Color(uiColor: .systemGroupedBackground)` → `theme.background`
- `Color(uiColor: .secondarySystemGroupedBackground)` → `theme.cardBackground`
- `Color(uiColor: .tertiarySystemGroupedBackground)` → `theme.cardBackground.opacity(0.7)`
- `.foregroundColor(.blue)` on calendar icon, date chevron, category expand → `theme.primary`
- `Color.blue.opacity(0.1)` on "Add Remaining" button bg → `theme.primary.opacity(0.1)`
- `.foregroundColor(.blue)` on "Add Remaining" text → `theme.primary`
- `.foregroundColor(.secondary)` → `theme.textSecondary`
- `.foregroundColor(.primary)` → `theme.textPrimary`

- [ ] **Step 1: Add theme env object and update background + navigation**

In `AddTransactionView`, add `@EnvironmentObject var theme: ThemeManager` after the existing `@Environment(\.dismiss)` line.

Then in the `body`, replace:
```swift
Color(uiColor: .systemGroupedBackground)
    .ignoresSafeArea()
```
with:
```swift
theme.background
    .ignoresSafeArea()
```

And replace the `.background(Color(uiColor: .systemGroupedBackground))` on the ScrollView with:
```swift
.background(theme.background)
```

- [ ] **Step 2: Update Type & Amount card background**

In the `body`, replace:
```swift
.background(Color(uiColor: .secondarySystemGroupedBackground))
.cornerRadius(20)
.padding(.horizontal)
.shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
```
(the one wrapping the Type & Amount VStack) with:
```swift
.background(theme.cardBackground)
.cornerRadius(20)
.padding(.horizontal)
.shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
```

- [ ] **Step 3: Update date row**

Replace the date row button contents:
```swift
Image(systemName: "calendar")
    .foregroundColor(theme.primary)
Text(dateFormatted)
    .foregroundColor(theme.textPrimary)
    .fontWeight(.medium)
Spacer()
Image(systemName: "chevron.right")
    .font(.caption)
    .foregroundColor(theme.textSecondary)
```

And its background:
```swift
.background(theme.cardBackground.opacity(0.7))
.cornerRadius(10)
```

- [ ] **Step 4: Update Category section**

Replace all occurrences of:
```swift
.background(Color(uiColor: .secondarySystemGroupedBackground))
.cornerRadius(20)
```
(the two category scroll/grid containers) with:
```swift
.background(theme.cardBackground)
.cornerRadius(20)
```

Replace the expand/collapse button:
```swift
Image(systemName: isCategoryExpanded ? "chevron.up" : "chevron.down")
    .font(.caption)
    .foregroundColor(theme.primary)
    .padding(8)
    .background(theme.cardBackground.opacity(0.7))
    .clipShape(Circle())
```

Replace the "Category" label:
```swift
Text("Category")
    .font(.headline)
    .foregroundColor(theme.textSecondary)
```

- [ ] **Step 5: Update Note section**

Replace:
```swift
Image(systemName: "square.and.pencil")
    .foregroundColor(theme.textSecondary)
```

Replace Note card background:
```swift
.background(theme.cardBackground)
.cornerRadius(16)
```

Replace "Note" label:
```swift
Text("Note")
    .font(.headline)
    .foregroundColor(theme.textSecondary)
    .padding(.horizontal)
```

- [ ] **Step 6: Update Sub Transactions section**

Replace "Sub Transactions" label:
```swift
Text("Sub Transactions")
    .font(.headline)
    .foregroundColor(theme.textSecondary)
```

Replace "Add Remaining" button:
```swift
Text("Add Remaining (\(remainingAmount.formattedCurrency))")
    .font(.caption)
    .fontWeight(.medium)
    .foregroundColor(theme.primary)
    .padding(.horizontal, 10)
    .padding(.vertical, 4)
    .background(theme.primary.opacity(0.1))
    .cornerRadius(12)
```

Replace the sub-transaction text field background:
```swift
.background(theme.cardBackground.opacity(0.7))
.cornerRadius(6)
```

Replace the sub-transactions container background:
```swift
.background(theme.cardBackground)
.cornerRadius(16)
```

- [ ] **Step 7: Update More Details section**

Replace:
```swift
Text("More Details")
    .font(.headline)
    .foregroundColor(theme.textPrimary)
```

Replace DisclosureGroup container:
```swift
.background(theme.cardBackground)
.cornerRadius(16)
```

In `customTextField`, replace:
```swift
Text(title)
    .font(.caption)
    .foregroundColor(theme.textSecondary)
```
and:
```swift
.background(theme.cardBackground.opacity(0.7))
.cornerRadius(8)
```

- [ ] **Step 8: Update categoryButton helper**

Replace the circle fill for unselected state:
```swift
Circle()
    .fill(isSelected ? color : theme.cardBackground.opacity(0.7))
    .frame(width: 50, height: 50)
```

- [ ] **Step 9: Build to verify**

```bash
xcodebuild build \
  -project /Users/jackkahod/Desktop/File/Project/Meow-Jod-Clone-App/BROKE.xcodeproj \
  -scheme BROKE \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 10: Commit**

```bash
git add BROKE/Views/AddTransactionView.swift
git commit -m "feat: apply theme colors to AddTransactionView"
```

---

## Task 8: Theme AnalyticsView.swift

**Files:**
- Modify: `BROKE/Views/AnalyticsView.swift`

Color substitutions:
- `Color(UIColor.secondarySystemBackground).opacity(0.5)` → `theme.cardBackground`
- `Color(UIColor.systemBackground)` → `theme.background`
- `Color(UIColor.systemGray6)` on filter tab bg → `theme.cardBackground`
- Active tab bg `.primary` → `theme.primary`
- Active tab text `Color(UIColor.systemBackground)` → `theme.background`
- Inactive tab text `.primary` → `theme.textPrimary`
- `.orange` on calendar icon → `theme.accent`
- `.green` income / `.red` expense in SummaryStatsBoard → `theme.income` / `theme.expense`
- `.red` in balance text → `theme.expense`
- `.primary` foreground text → `theme.textPrimary`
- `.secondary` foreground text → `theme.textSecondary`
- `.purple` on BehaviorInsightCard icon → `theme.primary`
- `Color.purple.opacity(0.05)` bg → `theme.primary.opacity(0.05)`
- `Color.purple.opacity(0.1)` border → `theme.primary.opacity(0.1)`
- `.green` / `.orange` in CategoryPerformanceList trend → `theme.income` / `theme.accent`
- `.gray` on average rule mark → `theme.textSecondary`

- [ ] **Step 1: Add theme to AnalyticsView and all sub-structs**

Add `@EnvironmentObject var theme: ThemeManager` to:
- `AnalyticsView`
- `MonthYearNavigator`
- `SummaryStatsBoard`
- `TypeFilterTabs`
- `ComparisonTagView`
- `MonthlyComparisonChart`
- `CategoryPerformanceList`
- `BehaviorInsightCard`

For `CategoryBreakdownChart`, it has no env objects and reads only transactions — leave it unchanged.

- [ ] **Step 2: Update MonthYearNavigator**

Replace:
```swift
Image(systemName: "calendar")
    .foregroundColor(theme.accent)
```
And chevron buttons:
```swift
Image(systemName: "chevron.left")
    .foregroundColor(theme.textPrimary)
    .padding()
// ...
Image(systemName: "chevron.right")
    .foregroundColor(theme.textPrimary)
    .padding()
```

- [ ] **Step 3: Update SummaryStatsBoard**

Replace:
```swift
// Income
.foregroundColor(theme.textSecondary)   // label HStack
Text(stats.income.formattedCurrency)
    .font(.headline)
    .foregroundColor(theme.income)

// Expense  
.foregroundColor(theme.textSecondary)   // label HStack
Text(stats.expense.formattedCurrency)
    .font(.headline)
    .foregroundColor(theme.textPrimary)

// Balance
.foregroundColor(stats.balance < 0 ? theme.expense : theme.textPrimary)
```

- [ ] **Step 4: Update TypeFilterTabs**

Replace:
```swift
.background(theme.cardBackground)
.cornerRadius(8)
```

Replace `filterButton`:
```swift
private func filterButton(title: String, type: TransactionType) -> some View {
    Button(action: {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedTab = type
        }
    }) {
        Text(title)
            .font(.subheadline)
            .fontWeight(selectedTab == type ? .semibold : .regular)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(selectedTab == type ? theme.primary : Color.clear)
            .foregroundColor(selectedTab == type ? theme.background : theme.textPrimary)
            .cornerRadius(8)
    }
}
```

- [ ] **Step 5: Update ComparisonTagView**

Replace:
```swift
.background(theme.cardBackground)
.cornerRadius(12)
```

- [ ] **Step 6: Update MonthlyComparisonChart**

Replace:
```swift
.background(theme.cardBackground)
.cornerRadius(16)
```

Replace rule mark:
```swift
RuleMark(y: .value("Average", average))
    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
    .foregroundStyle(theme.textSecondary)
```

Replace title:
```swift
Text("Compare to Last 3 Months")
    .font(.headline)
    .foregroundColor(theme.textPrimary)
```

- [ ] **Step 7: Update CategoryPerformanceList**

Replace background:
```swift
.background(theme.background)
```

Replace title:
```swift
Text("Category Performance")
    .font(.headline)
    .foregroundColor(theme.textPrimary)
```

Replace trend color:
```swift
.foregroundColor(row.isLower ? theme.income : theme.accent)
```

Replace text colors:
```swift
Text(row.category.displayName)
    .font(.body)
    .fontWeight(.medium)
    .foregroundColor(theme.textPrimary)

Text(row.currentAmount.formattedCurrency)
    .font(.body)
    .fontWeight(.semibold)
    .foregroundColor(theme.textPrimary)

Image(systemName: "chevron.right")
    .font(.caption)
    .foregroundColor(theme.textSecondary)
```

- [ ] **Step 8: Update BehaviorInsightCard**

Replace:
```swift
Image(systemName: "sparkles")
    .foregroundColor(theme.primary)
    .font(.title2)

Text("Insight")
    .font(.caption)
    .foregroundColor(theme.textSecondary)
    .textCase(.uppercase)

Text(insightText)
    .font(.subheadline)
    .foregroundColor(theme.textPrimary)
    .fixedSize(horizontal: false, vertical: true)
```

Replace background:
```swift
.background(RoundedRectangle(cornerRadius: 12).fill(theme.primary.opacity(0.05)))
.overlay(RoundedRectangle(cornerRadius: 12).stroke(theme.primary.opacity(0.1), lineWidth: 1))
```

- [ ] **Step 9: Update AnalyticsView_Previews**

Replace:
```swift
struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsView()
            .environmentObject(TransactionStore())
            .environmentObject(ThemeManager())
    }
}
```

- [ ] **Step 10: Build to verify**

```bash
xcodebuild build \
  -project /Users/jackkahod/Desktop/File/Project/Meow-Jod-Clone-App/BROKE.xcodeproj \
  -scheme BROKE \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 11: Commit**

```bash
git add BROKE/Views/AnalyticsView.swift
git commit -m "feat: apply theme colors to AnalyticsView and all sub-components"
```

---

## Task 9: Add Appearance section to SettingsView.swift

**Files:**
- Modify: `BROKE/Views/SettingsView.swift`

- [ ] **Step 1: Replace SettingsView.swift**

Replace the entire file `BROKE/Views/SettingsView.swift`:

```swift
//
//  SettingsView.swift
//  BROKE
//

import PhotosUI
import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var transactionStore: TransactionStore
    @EnvironmentObject var theme: ThemeManager
    @AppStorage("lastScannedDate") private var lastScannedDate: Date?
    @State private var isRequestingAccess = false
    @State private var isImportingFile = false
    @State private var exportedFileURL: URL?
    @State private var isShareSheetPresented = false

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Appearance")) {
                    Picker("Theme", selection: $theme.character) {
                        Label("Penguin", systemImage: "snowflake")
                            .tag(ThemeCharacter.penguin)
                        Label("Dragon", systemImage: "flame")
                            .tag(ThemeCharacter.dragon)
                    }

                    Picker("Mode", selection: $theme.appearance) {
                        Label("Light", systemImage: "sun.max")
                            .tag(AppearanceMode.light)
                        Label("Dark", systemImage: "moon")
                            .tag(AppearanceMode.dark)
                        Label("System", systemImage: "circle.lefthalf.filled")
                            .tag(AppearanceMode.system)
                    }
                }

                Section(header: Text("Photo Library Access")) {
                    Button("Request Photo Access") {
                        isRequestingAccess = true
                    }
                    .sheet(isPresented: $isRequestingAccess) {
                        RequestPhotoAccessView()
                    }

                    HStack {
                        Text("Scan Start Date")
                        Spacer()
                        Text("\(viewModel.scanStartDate, formatter: dateFormatter)")
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("SlipOK API")) {
                    HStack {
                        Text("Remaining Quota")
                        Spacer()
                        if viewModel.isLoadingQuota {
                            ProgressView()
                        } else if let quota = viewModel.slipOKQuota {
                            Text("\(quota)")
                                .foregroundColor(quota < 10 ? .red : .primary)
                        } else {
                            Text("-")
                        }
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    Button("Refresh Quota") {
                        viewModel.fetchQuota()
                    }
                    .disabled(viewModel.isLoadingQuota)
                }

                Section(header: Text("Data Management")) {
                    if viewModel.isImporting {
                        HStack {
                            ProgressView()
                            Text(viewModel.importMessage ?? "Importing...")
                        }
                    } else {
                        Button("Import from CSV") {
                            isImportingFile = true
                        }
                    }

                    if let msg = viewModel.importMessage, !viewModel.isImporting {
                        Text(msg)
                            .font(.caption)
                            .foregroundColor(.green)
                    }

                    Button("Export to CSV") {
                        if let url = viewModel.exportData(store: transactionStore) {
                            exportedFileURL = url
                            isShareSheetPresented = true
                        }
                    }
                    .sheet(isPresented: $isShareSheetPresented, onDismiss: {
                        exportedFileURL = nil
                    }) {
                        if let url = exportedFileURL {
                            ShareSheet(activityItems: [url])
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                viewModel.fetchQuota()
            }
            .fileImporter(
                isPresented: $isImportingFile,
                allowedContentTypes: [.commaSeparatedText, .plainText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case let .success(urls):
                    if let url = urls.first {
                        viewModel.importCSV(from: url, into: transactionStore)
                    }
                case let .failure(error):
                    viewModel.errorMessage = "File selection failed: \(error.localizedDescription)"
                }
            }
        }
    }
}
```

- [ ] **Step 2: Final build to verify entire app compiles**

```bash
xcodebuild build \
  -project /Users/jackkahod/Desktop/File/Project/Meow-Jod-Clone-App/BROKE.xcodeproj \
  -scheme BROKE \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -10
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add BROKE/Views/SettingsView.swift
git commit -m "feat: add Appearance section to Settings with theme and mode pickers"
```

---

## Self-Review Checklist

- [x] **Spec coverage:** All 10 files from the spec are covered across 9 tasks. Both theme enums. All color tokens. `preferredColorScheme` wired at root. Settings Appearance section. SF Symbols used in pickers (snowflake, flame, sun.max, moon, circle.lefthalf.filled).
- [x] **No placeholders:** Every step has complete code or exact string replacements.
- [x] **Type consistency:** `ThemeManager` defined in Task 2, consumed in Tasks 3-9. Token names (`theme.primary`, `theme.income`, `theme.expense`, `theme.cardBackground`, `theme.background`, `theme.textPrimary`, `theme.textSecondary`, `theme.accent`) are consistent throughout. `ThemeCharacter` and `AppearanceMode` enums used identically in Tasks 2 and 9.
- [x] **Category colors unchanged:** All `category.color` and `incomeCategory.color` usages preserved in Tasks 5-6 — only the hardcoded `.green`/`.red`/`.blue` overrides are replaced.

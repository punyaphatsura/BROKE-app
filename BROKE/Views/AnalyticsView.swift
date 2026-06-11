//
//  AnalyticsView.swift
//  BROKE
//
//  Created by AI Assistant on 20/4/2568 BE.
//

import SwiftUI
import Charts

struct AnalyticsView: View {
    @EnvironmentObject var transactionStore: TransactionStore
    @EnvironmentObject var theme: ThemeManager
    
    // MARK: - State
    @State private var currentDate = Date()
    @State private var selectedTab: TransactionType = .expense
    
    // MARK: - 1. Monthly Summary (& Data Prep)
    
    private func getTransactions(for date: Date) -> [Transaction] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let filtered = transactionStore.getAllTransactions().filter {
            let tYear = calendar.component(.year, from: $0.date)
            let tMonth = calendar.component(.month, from: $0.date)
            return tYear == year && tMonth == month
        }
        return flattenTransactions(filtered)
    }
    
    private var currentMonthTransactions: [Transaction] {
        getTransactions(for: currentDate)
    }
    
    // Filtered by selected Tab (Expense/Income/Transfer)
    private var chartTransactions: [Transaction] {
        currentMonthTransactions.filter { $0.type == selectedTab }
    }
    
    // Summary Stats (Income, Expense, Net)
    private var monthStats: (income: Double, expense: Double, balance: Double) {
        let income = currentMonthTransactions.filter { $0.type == .income }.reduce(0.0) { $0 + $1.amount }
        let expense = currentMonthTransactions.filter { $0.type == .expense }.reduce(0.0) { $0 + $1.amount }
        return (income, expense, income - expense)
    }
    
    // MARK: - 3. Previous Months Data

    // Get last 3 months dates (excluding current)
    private var previous3Months: [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []
        for i in 1...3 {
            if let date = calendar.date(byAdding: .month, value: -i, to: currentDate) {
                dates.append(date)
            }
        }
        return dates
    }

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 1) Month Navigation
                MonthYearNavigator(currentDate: $currentDate)
                
                // 2) Summary Stats
                SummaryStatsBoard(stats: monthStats)
                
                // 3) Filter Tabs
                TypeFilterTabs(selectedTab: $selectedTab)
                
                // 4) Main Donut (Category Breakdown)
                CategoryBreakdownChart(
                    transactions: chartTransactions,
                    contextMonth: currentDate,
                    contextType: selectedTab,
                    totalAmount: selectedTab == .expense ? monthStats.expense : (selectedTab == .income ? monthStats.income : 0)
                )
                
                // 5) Category Performance List
                if selectedTab == .expense {
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
}

// MARK: - Components

// 1. Month Navigator (Kept similar)
struct MonthYearNavigator: View {
    @Binding var currentDate: Date
    @EnvironmentObject var theme: ThemeManager
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yy"
        return formatter.string(from: currentDate)
    }
    
    func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: currentDate) {
            currentDate = newDate
        }
    }
    
    var body: some View {
        HStack {
            Button(action: { changeMonth(by: -1) }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(theme.textPrimary)
                    .padding()
            }
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundColor(theme.accent)
                Text(dateString)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            Spacer()
            Button(action: { changeMonth(by: 1) }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(theme.textPrimary)
                    .padding()
            }
        }
        .padding(.horizontal)
    }
}

// 2. Summary Stats (Kept similar)
struct SummaryStatsBoard: View {
    let stats: (income: Double, expense: Double, balance: Double)
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 0) {
                // Income
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down")
                            .font(.caption)
                        Text("Income")
                            .font(.caption)
                    }
                    .foregroundColor(theme.textSecondary)
                    Text(stats.income.formattedCurrency)
                        .font(.headline)
                        .foregroundColor(theme.income)
                }
                .frame(maxWidth: .infinity)

                Divider().frame(height: 30)

                // Expense
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.caption)
                        Text("Expense")
                            .font(.caption)
                    }
                    .foregroundColor(theme.textSecondary)
                    Text(stats.expense.formattedCurrency)
                        .font(.headline)
                        .foregroundColor(theme.expense)
                }
                .frame(maxWidth: .infinity)
            }

            Text("Balance \(stats.balance.formattedCurrency)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(stats.balance < 0 ? theme.expense : theme.textPrimary)
        }
        .padding(.horizontal)
    }
}

// 3. Filter Tabs (Kept similar)
struct TypeFilterTabs: View {
    @Binding var selectedTab: TransactionType
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        HStack(spacing: 0) {
            filterButton(title: "Expense", type: .expense)
            filterButton(title: "Income", type: .income)
        }
        .background(theme.cardBackground)
        .cornerRadius(8)
        .padding(.horizontal)
    }

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
}

// 4. Category Breakdown (Updated with Top 2 Caption)
struct CategoryBreakdownChart: View {
    let transactions: [Transaction]
    let contextMonth: Date
    let contextType: TransactionType
    let totalAmount: Double

    @State private var lastSelectedCategory: ExpenseCategory?
    @State private var navigateToCategoryKey: String? // Trick for programmatic nav
    @EnvironmentObject var theme: ThemeManager
    
    // Helper to find filtered transactions for navigation
    private func transactionsFor(_ category: ExpenseCategory) -> [Transaction] {
        transactions.filter { $0.categoryId == category }
    }
    
    private var groupedData: [(category: ExpenseCategory, amount: Double)] {
        let grouped = Dictionary(grouping: transactions, by: { $0.categoryId ?? .others })
        return grouped.map { (key, value) in
            (key, value.reduce(0.0) { $0 + $1.amount })
        }.sorted { $0.amount > $1.amount }
    }
    
    private var chartData: [(category: ExpenseCategory, amount: Double)] {
       let top = groupedData
       return Array(top)
    }
    
    // Top 2 Logic
    private var top2Caption: String {
        let top2 = groupedData.prefix(2)
        if top2.count < 2 { return "" }
        if totalAmount == 0 { return "" }
        
        let sumTop2 = top2.reduce(0.0) { $0 + $1.amount }
        let pct = Int((sumTop2 / totalAmount) * 100)
        let names = top2.map { $0.category.displayName }.joined(separator: " + ")
        
        return "\(names) = \(pct)% of your spending"
    }

    var body: some View {
        VStack(spacing: 8) {
            // Invisible Link for Selection
            NavigationLink(
                destination: Group {
                    if let catName = navigateToCategoryKey, let cat = ExpenseCategory(rawValue: catName) {
                        CategoryDetailView(category: cat, transactions: transactionsFor(cat))
                    } else {
                        EmptyView()
                    }
                },
                isActive: Binding(
                    get: { navigateToCategoryKey != nil },
                    set: { if !$0 { navigateToCategoryKey = nil } }
                )
            ) { EmptyView() }

            Chart(chartData, id: \.category) { item in
                SectorMark(
                    angle: .value("Amount", item.amount),
                    innerRadius: .ratio(0.65),
                    angularInset: 2
                )
                .cornerRadius(6)
                .foregroundStyle(item.category.color)
                // Highlight logic: Use persisted category
                .opacity(lastSelectedCategory == nil || lastSelectedCategory == item.category ? 1.0 : 0.3)
            }
            .chartBackground { proxy in
                GeometryReader { geo in
                    VStack(spacing: 2) {
                        if let cat = lastSelectedCategory, let item = chartData.first(where: { $0.category == cat }) {
                            Text(cat.displayName)
                                .font(.headline)
                                .foregroundColor(theme.textSecondary)
                            Text(item.amount.formattedCurrency)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(theme.textPrimary)
                            Text("\(Int((item.amount / totalAmount) * 100))%")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.caption)
                                .foregroundColor(theme.accent.opacity(0.8))
                                .padding(.top, 2)
                        } else {
                            Text("Total")
                                .font(.headline)
                                .foregroundColor(theme.textSecondary)
                            Text(totalAmount.formattedCurrency)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(theme.textPrimary)
                        }
                    }
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Color.clear
                        .contentShape(Circle())
                        .gesture(
                            SpatialTapGesture()
                                .onEnded { value in
                                    handleTap(at: value.location, in: geo.size)
                                }
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    handleDrag(at: value.location, in: geo.size)
                                }
                        )
                }
            }
            .frame(height: 250)
            
            // Insight Line
            if !top2Caption.isEmpty {
                Text(top2Caption)
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Interaction Helpers
    private func handleTap(at location: CGPoint, in size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let distance = sqrt(pow(location.x - center.x, 2) + pow(location.y - center.y, 2))
        let radius = min(size.width, size.height) / 2
        let innerRadius = radius * 0.65
        
        if distance < innerRadius {
            // Center Tap -> Navigate
            if let cat = lastSelectedCategory {
                navigateToCategoryKey = cat.rawValue
            }
        } else {
            // Ring Tap -> Toggle Selection
            let angle = angleFor(point: location, in: size)
            if let cat = category(forAngle: angle) {
                if lastSelectedCategory == cat {
                    lastSelectedCategory = nil // Deselect
                } else {
                    lastSelectedCategory = cat // Select
                }
            }
        }
    }
    
    private func handleDrag(at location: CGPoint, in size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let distance = sqrt(pow(location.x - center.x, 2) + pow(location.y - center.y, 2))
        let radius = min(size.width, size.height) / 2
        let innerRadius = radius * 0.65
        
        if distance >= innerRadius {
            let angle = angleFor(point: location, in: size)
            if let cat = category(forAngle: angle) {
                lastSelectedCategory = cat
            }
        }
    }
    
    private func angleFor(point: CGPoint, in size: CGSize) -> Double {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let dx = point.x - center.x
        let dy = point.y - center.y
        
        // Atan2: 0 is Right (3 o'clock), 90 is Down.
        // Swift Charts starts Top (12 o'clock) and goes Clockwise.
        // Top (-90 deg) should be 0.
        // Right (0 deg) should be 90.
        var degrees = atan2(dy, dx) * 180 / .pi
        degrees += 90 // Rotate so -90 becomes 0
        
        if degrees < 0 { degrees += 360 }
        return degrees
    }
    
    private func category(forAngle angle: Double) -> ExpenseCategory? {
        // Angle is 0...360 starting from Top Clockwise
        var currentAngle: Double = 0
        let total = chartData.reduce(0.0) { $0 + $1.amount }
        if total == 0 { return nil }
        
        for item in chartData {
            let sliceDegrees = (item.amount / total) * 360
            if angle >= currentAngle && angle < (currentAngle + sliceDegrees) {
                return item.category
            }
            currentAngle += sliceDegrees
        }
        return nil
    }
}

// 8. Category Performance (New)
struct CategoryPerformanceList: View {
    let currentTransactions: [Transaction]
    let previous3Months: [Date]
    var transactionStore: TransactionStore // Need full store to look back
    @EnvironmentObject var theme: ThemeManager
    
    struct CategoryPerf: Identifiable {
        let id = UUID()
        let category: ExpenseCategory
        let currentAmount: Double
        let avgPast: Double
        var delta: Double { currentAmount - avgPast }
        var isLower: Bool { delta < 0 }
    }
    
    private var rows: [CategoryPerf] {
        let grouped = Dictionary(grouping: currentTransactions, by: { $0.categoryId ?? .others })
        // For distinct categories in current month
        var result: [CategoryPerf] = []
        
        for (cat, txs) in grouped {
            let currentSum = txs.reduce(0.0) { $0 + $1.amount }
            
            // Calculate avg for this cat in past 3 months
            let pastSum = previous3Months.map { date in
                let calendar = Calendar.current
                let y = calendar.component(.year, from: date)
                let m = calendar.component(.month, from: date)
                
                // Fetch for month -> Flatten -> Filter for Category
                let monthTxs = transactionStore.getAllTransactions().filter {
                    let ty = calendar.component(.year, from: $0.date)
                    let tm = calendar.component(.month, from: $0.date)
                    return ty == y && tm == m && $0.type == .expense
                }
                let flattened = flattenTransactions(monthTxs)
                return flattened.filter { $0.categoryId == cat }
                    .reduce(0.0) { $0 + $1.amount }
            }.reduce(0.0, +)
            
            let avg = previous3Months.isEmpty ? 0 : pastSum / Double(previous3Months.count)
            
            result.append(CategoryPerf(category: cat, currentAmount: currentSum, avgPast: avg))
        }
        return result.sorted { $0.currentAmount > $1.currentAmount }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category Performance")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            ForEach(rows) { row in
                NavigationLink(destination: CategoryDetailView(
                    category: row.category,
                    transactions: currentTransactions.filter { $0.categoryId == row.category }
                )) {
                    HStack {
                        // Icon
                  Image(systemName: row.category.icon)
                                .foregroundColor(row.category.color).font(.caption)
                            .frame(width: 40, height: 40)
                        
                        VStack(alignment: .leading) {
                            Text(row.category.displayName)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(theme.textPrimary)
                            
                            HStack(spacing: 4) {
                                if row.avgPast > 0 {
                                    Image(systemName: row.isLower ? "arrow.down" : "arrow.up")
                                        .font(.caption2)
                                    Text("\(row.isLower ? "Lower" : "Higher") than avg by \(Int(abs(row.delta)).formattedWithSeparator)")
                                        .font(.caption2)
                                } else {
                                    Text("New spending")
                                        .font(.caption2)
                                }
                            }
                            .foregroundColor(row.isLower ? theme.income : theme.accent)
                        }
                        
                        Spacer()
                        
                        Text(row.currentAmount.formattedCurrency)
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.textPrimary)

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                }
                .buttonStyle(.plain)
                Divider()
            }
        }
        .padding()
        .background(theme.background)
        .padding(.horizontal)
    }
}

struct CategoryDetailView: View {
    let category: ExpenseCategory
    let transactions: [Transaction]
    
    var body: some View {
        TransactionListView(customTransactions: transactions)
            .navigationTitle(category.displayName)
            .navigationBarTitleDisplayMode(.inline)
    }
}

// Helpers
extension Int {
    var formattedWithSeparator: String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsView()
            .environmentObject(TransactionStore())
            .environmentObject(ThemeManager())
    }
}

// MARK: - Helpers
fileprivate func flattenTransactions(_ transactions: [Transaction]) -> [Transaction] {
    var result: [Transaction] = []
    for t in transactions {
        if let subs = t.subTransactions, !subs.isEmpty {
            for sub in subs {
                var newT = t
                newT.id = UUID() // Unique ID for analytics list
                newT.amount = sub.amount
                newT.categoryId = sub.categoryId
                newT.subTransactions = nil // Avoid recursion
                result.append(newT)
            }
        } else {
            result.append(t)
        }
    }
    return result
}

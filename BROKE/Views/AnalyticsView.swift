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
    
    // MARK: - 3. "Lower / Higher than Average" Logic
    
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
    
    // Average Monthly Expense of last 3 months
    private var averageMonthlyExpense3Months: Double {
        let pastMonths = previous3Months
        let totalPast = pastMonths.map { date in
            getTransactions(for: date).filter { $0.type == .expense }.reduce(0.0) { $0 + $1.amount }
        }.reduce(0.0, +)
        return pastMonths.isEmpty ? 0 : totalPast / Double(pastMonths.count)
    }
    
    private var comparisonToAverage: (diff: Double, isLower: Bool) {
        let currentExpense = monthStats.expense
        let avg = averageMonthlyExpense3Months
        let diff = currentExpense - avg
        return (abs(diff), diff < 0)
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
                
                // 5) "Lower / Higher than Average" Tag
                // Only show for Expense tab as per logic prompt
                if selectedTab == .expense {
                    ComparisonTagView(
                        diff: comparisonToAverage.diff,
                        isLower: comparisonToAverage.isLower,
                        avg: averageMonthlyExpense3Months
                    )
                    
                    // 6) Behavior Insight Engine
                    BehaviorInsightCard(
                        transactions: currentMonthTransactions,
                        avgExpense: averageMonthlyExpense3Months
                    )
                }
                
                // 7) Monthly Comparison Chart (Last 4 Months)
                if selectedTab == .expense {
                    MonthlyComparisonChart(
                        currentDate: currentDate,
                        transactionStore: transactionStore,
                        average: averageMonthlyExpense3Months
                    )
                }
                
                // 8) Category Performance List
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
                    .foregroundColor(.secondary)
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

// 5. Comparison Tag (Updated Logic)
struct ComparisonTagView: View {
    let diff: Double
    let isLower: Bool
    let avg: Double
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isLower ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundColor(isLower ? theme.income : theme.expense)
            
            if avg == 0 {
                Text("No data for comparison")
                    .font(.subheadline)
            } else {
                Text("\(isLower ? "Lower" : "Higher") than average by \(Int(diff).formattedWithSeparator)")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// 7. Monthly Comparison Chart (New)
struct MonthlyComparisonChart: View {
    let currentDate: Date
    let transactionStore: TransactionStore
    let average: Double
    @EnvironmentObject var theme: ThemeManager
    
    // Last 4 months based on currentDate
    // Data structure for stacked chart
    struct MonthlyCategoryData: Identifiable {
        let id = UUID()
        let month: Date
        let category: ExpenseCategory
        let amount: Double
    }
    
    // Last 4 months based on currentDate
    private var chartData: [MonthlyCategoryData] {
        let calendar = Calendar.current
        var result: [MonthlyCategoryData] = []
        
        // Include current, -1, -2, -3 (Total 4 bars)
        for i in (0...3).reversed() {
            if let date = calendar.date(byAdding: .month, value: -i, to: currentDate) {
                let y = calendar.component(.year, from: date)
                let m = calendar.component(.month, from: date)
                
                // 1. Get Expenses for Month
                let monthTxs = transactionStore.getAllTransactions().filter {
                     let ty = calendar.component(.year, from: $0.date)
                     let tm = calendar.component(.month, from: $0.date)
                     return ty == y && tm == m && $0.type == .expense
                }
                
                // 2. Flatten subtransactions
                let flattened = flattenTransactions(monthTxs)
                
                // 3. Group by Category
                let grouped = Dictionary(grouping: flattened, by: { $0.categoryId ?? .others })
                
                for (cat, txs) in grouped {
                    let sum = txs.reduce(0.0) { $0 + $1.amount }
                    result.append(MonthlyCategoryData(month: date, category: cat, amount: sum))
                }
            }
        }
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Compare to Last 3 Months")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            Chart {
                ForEach(chartData) { item in
                    BarMark(
                        x: .value("Month", item.month, unit: .month),
                        y: .value("Amount", item.amount)
                    )
                    .foregroundStyle(item.category.color)
                }
                
                RuleMark(y: .value("Average", average))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .foregroundStyle(theme.textSecondary)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 180)
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal)
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

// 6. Behavior Insight Engine (New)
struct BehaviorInsightCard: View {
    let transactions: [Transaction]
    let avgExpense: Double
    @EnvironmentObject var theme: ThemeManager
    
    var insightText: String {
        // Logic:
        // 1. Weekend vs Weekday
        let calendar = Calendar.current
        let weekendSpend = transactions.filter {
            let d = calendar.component(.weekday, from: $0.date)
            return d == 1 || d == 7
        }.reduce(0.0) { $0 + $1.amount }
        let total = transactions.reduce(0.0) { $0 + $1.amount }
        
        // 2. Food Percent
        let foodAmount = transactions.filter { $0.categoryId == .food }.reduce(0.0) { $0 + $1.amount }
        let foodPct = total > 0 ? (foodAmount / total) : 0
        
        // 3. Variance (Simple: Current vs Avg)
        let isHighVariance = avgExpense > 0 && total > (avgExpense * 1.2)
        
        // Synthesis
        var traits: [String] = []
        if total > 0 && (weekendSpend / total) > 0.4 { traits.append("Weekend Spender") }
        if foodPct > 0.35 { traits.append("Foodie") }
        if isHighVariance { traits.append("Spulsive Spender") } // calculated wording
        if total < avgExpense * 0.8 && avgExpense > 0 { traits.append("Great Saver") }
        
        if traits.isEmpty { return "Your spending is balanced this month." }
        
        // Construct sentence
        if traits.contains("Great Saver") {
            return "You are saving 20% more than usual. Keeping fixed costs low!"
        }
        if traits.contains("Weekend Spender") {
           return "Most of your spending happens on weekends. Try limiting Saturday splurges."
        }
         if traits.contains("Foodie") {
           return "Food accounts for \(Int(foodPct * 100))% of your spending. Cooking at home could save you ~฿2,000."
        }
        
        return "You're a \(traits.joined(separator: " & ")). Watch out for impulse buys!"
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .foregroundColor(theme.primary)
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                Text("Insight")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                    .textCase(.uppercase)

                Text(insightText)
                    .font(.subheadline)
                    .foregroundColor(theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(theme.primary.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(theme.primary.opacity(0.1), lineWidth: 1))
        .padding(.horizontal)
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

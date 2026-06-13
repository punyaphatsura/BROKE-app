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

    private var annualTransactionsForYear: [Transaction] {
        let year = Calendar.current.component(.year, from: currentDate)
        return annualExpenses(from: transactionStore.getAllTransactions(), year: year)
    }

    // MARK: - Body
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

                    // 7. Annual expenses
                    if !annualTransactionsForYear.isEmpty {
                        AnnualExpensesSection(
                            transactions: annualTransactionsForYear,
                            year: Calendar.current.component(.year, from: currentDate)
                        )
                    }
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

    private var daysInMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: currentDate)?.count ?? 30
    }

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
                        ForEach(0..<dayLabels.count, id: \.self) { i in
                            Text(dayLabels[i])
                                .font(.system(size: 8))
                                .foregroundColor(theme.textSecondary)
                                .frame(maxWidth: .infinity)
                        }
                        ForEach(0..<(firstWeekday - 1), id: \.self) { _ in
                            Color.clear.frame(height: 14)
                        }
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

// 8. Top Transactions List
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
                    NavigationLink(destination: TransactionListView(customTransactions: [tx])) {
                        HStack(spacing: 12) {
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
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(theme.cardBackground)
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
}

// 9. Category Performance (New)
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
        let monthlyTrend: [Double]  // [3mo ago, 2mo ago, 1mo ago, current] oldest→newest
        var delta: Double { currentAmount - avgPast }
        var isLower: Bool { delta < 0 }
    }

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

                        let trendColor: Color = (row.monthlyTrend.last ?? 0) <= (row.monthlyTrend.first ?? 0)
                            ? theme.income : theme.expense
                        SparklineView(values: row.monthlyTrend, color: trendColor)
                            .frame(width: 50, height: 20)

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
            .chartYScale(domain: {
                let padding = range > 0 ? range * 0.1 : max(maxVal * 0.1, 1.0)
                return max(0, minVal - padding)...(maxVal + padding)
            }())
        }
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
        .background(theme.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct ExpenseTrendChart: View {
    let transactions: [Transaction]
    let currentDate: Date
    @EnvironmentObject var theme: ThemeManager

    private var monthlyData: [(month: Date, total: Double)] {
        expenseTotals(from: transactions, months: 12, referenceDate: currentDate)
    }

    private var last6MonthsData: [(month: Date, total: Double)] {
        expenseTotals(from: transactions, months: 6, referenceDate: currentDate)
    }

    private var sixMonthAvg: Double {
        let sum = last6MonthsData.reduce(0.0) { $0 + $1.total }
        return last6MonthsData.isEmpty ? 0 : sum / Double(last6MonthsData.count)
    }

    private var sixMonthLow: Double {
        last6MonthsData.map(\.total).min() ?? 0
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

/// Returns total expense per month for the last `months` months ending at `referenceDate`.
/// Result is sorted oldest → newest. Each tuple: (first-of-month Date, total expense Double).
func expenseTotals(
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
func dailySpend(
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
func weekdayAverages(
    from transactions: [Transaction],
    referenceDate: Date
) -> [Int: Double] {
    let calendar = Calendar.current
    let y = calendar.component(.year, from: referenceDate)
    let m = calendar.component(.month, from: referenceDate)
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
    var result: [Int: Double] = [:]
    for (wd, count) in weekdayCounts {
        result[wd] = (sums[wd] ?? 0) / Double(count)
    }
    return result
}


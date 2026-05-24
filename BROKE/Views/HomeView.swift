//
//  HomeView.swift
//  BROKE
//
//  Created by Punyaphat Surakiatkamjorn on 20/4/2568 BE.
//

import Photos
import PhotosUI
import SwiftUI

private enum TransactionContentPositionKey: PreferenceKey {
    static var defaultValue: [UUID: CGFloat] = [:]
    static func reduce(value: inout [UUID: CGFloat], nextValue: () -> [UUID: CGFloat]) {
        value.merge(nextValue()) { _, new in new }
    }
}

struct HomeView: View {
    @EnvironmentObject var transactionStore: TransactionStore
    @EnvironmentObject var photoService: PhotoService
    @StateObject private var scannerViewModel = SlipScannerViewModel()
    @StateObject private var viewModel = HomeViewModel()
    @Environment(\.scenePhase) var scenePhase

    @State private var newSlipsCount: Int = 0
    @State private var showingQuotaAlert = false
    @State private var isLastBatchExpanded: Bool = false
    @State private var showingSlipReview = false
    @State private var showStickyHeader = false
    @State private var stickyDate: Date = Date()
    @State private var stickyExpense: Double = 0
    @State private var stickyIncome: Double = 0
    @State private var transactionContentPositions: [UUID: CGFloat] = [:]
    @State private var scrollOffset: CGFloat = 0
    @EnvironmentObject var theme: ThemeManager
    @AppStorage("userName") private var userName: String = ""

    // Computed properties for counts
    var unprocessedCount: Int {
        photoService.assets.filter { !ImageHashManager.shared.isProcessed(asset: $0) }.count
    }

    var processedCount: Int {
        newSlipsCount - unprocessedCount
    }

    private var slipBannerBankSources: String {
        let banks = viewModel.recentScannedTransactions
            .compactMap { $0.bank }
            .filter { $0 != .unknown }
        let uniqueNames = NSOrderedSet(array: banks.map { $0.rawValue })
            .array as? [String] ?? []
        guard !uniqueNames.isEmpty else { return "Tap Scan to review" }
        return "From " + uniqueNames.prefix(4).joined(separator: " · ")
    }

    var groupedTransactions: [(key: Date, value: [Transaction])] {
        let grouped = Dictionary(grouping: transactionStore.transactions) { transaction in
            Calendar.current.startOfDay(for: transaction.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    // Ordered list of all transactions as displayed (date desc, then time desc within day)
    private var orderedTransactions: [Transaction] {
        groupedTransactions.flatMap { $0.value.sorted { $0.date > $1.date } }
    }

    // For each transaction: running total of expense+income from that row DOWN to the last row
    private var cumulativeFromTransactionDown: [UUID: (expense: Double, income: Double)] {
        var cumExpense = 0.0
        var cumIncome = 0.0
        var result = [UUID: (expense: Double, income: Double)]()
        for txn in orderedTransactions.reversed() {
            if txn.type == .expense { cumExpense += txn.amount }
            else if txn.type == .income { cumIncome += txn.amount }
            result[txn.id] = (cumExpense, cumIncome)
        }
        return result
    }

    // Maps transaction ID → its section date (for the sticky header date label)
    private var transactionSectionDate: [UUID: Date] {
        var result = [UUID: Date]()
        for section in groupedTransactions {
            for txn in section.value { result[txn.id] = section.key }
        }
        return result
    }

    var body: some View {
        ZStack(alignment: .top) {
            theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    characterHeader
                    heroBalanceCard
                    if !viewModel.recentScannedTransactions.isEmpty {
                        slipBanner
                    }
                    lazyTransactionList
                        .padding(.bottom, 80)
                }
                .coordinateSpace(name: "homeContent")
            }
            // Reserve space equal to the sticky header height so it never covers a row
            .safeAreaInset(edge: .top, spacing: 0) {
                Color.clear.frame(height: showStickyHeader ? 52 : 0)
                    .animation(.easeInOut(duration: 0.2), value: showStickyHeader)
            }
            .onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.y
            } action: { _, newOffset in
                scrollOffset = newOffset
                updateStickyHeaderFromPositions()
            }
            .onPreferenceChange(TransactionContentPositionKey.self) { positions in
                for (id, y) in positions { transactionContentPositions[id] = y }
                updateStickyHeaderFromPositions()
            }
            .refreshable { await refreshData() }
            .sheet(isPresented: $viewModel.showingAddTransaction) {
                AddTransactionView()
            }
            .sheet(item: $viewModel.selectedTransactionForReview) { transaction in
                AddTransactionView(transactionToEdit: transaction)
            }
            .sheet(isPresented: $showingSlipReview) {
                SlipReviewView()
                    .environmentObject(transactionStore)
                    .environmentObject(photoService)
                    .environmentObject(theme)
            }
            .alert("Limit Exceeded", isPresented: $showingQuotaAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The daily limit for Gemini API has been reached. Please try again later.")
            }
            .onReceive(photoService.$isLoadingComplete) { isComplete in
                if isComplete { triggerBatchScan() }
            }
            .onReceive(scannerViewModel.$processedSlipData) { slipData in
                if let slipData { saveTransactionFromSlip(slipData) }
            }
            .onReceive(scannerViewModel.$errorMessage) { error in
                if let error, error.contains("quota") || error.contains("429") || error.contains("RESOURCE_EXHAUSTED") {
                    showingQuotaAlert = true
                }
            }
            .onAppear {
                updateTransactionsList()
                if newSlipsCount == 0 && unprocessedCount > 0 {
                    newSlipsCount = unprocessedCount
                }
            }
            .onChange(of: viewModel.currentMonth) { updateTransactionsList() }
            .onChange(of: viewModel.currentYear) { updateTransactionsList() }

            // Sticky cumulative header overlay
            if showStickyHeader {
                StickyScrollHeader(
                    date: stickyDate,
                    cumulativeExpense: stickyExpense,
                    cumulativeIncome: stickyIncome
                )
                .transition(.opacity)
            }
        }
    }

    // MARK: - Subviews

    private var characterHeader: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(theme.primary.opacity(0.15))
                    .frame(width: 44, height: 44)
                MascotView(size: 30, mood: .happy)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(userName.isEmpty ? "Hi, there." : "Hi, \(userName).")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                Text(viewModel.monthYearString)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.textSecondary)
            }

            Spacer()

            HStack(spacing: 0) {
                Button(action: viewModel.previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                        .frame(width: 32, height: 32)
                }
                Button(action: viewModel.nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                        .frame(width: 32, height: 32)
                }
                .disabled(viewModel.isCurrentMonthAndYear)
            }

            Button(action: { viewModel.showingAddTransaction = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.cardBackground)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(theme.primary)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 18)
    }

    private var heroBalanceCard: some View {
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(Color.white.opacity(0.16))
                .frame(width: 140, height: 140)
                .offset(x: 30, y: -30)
            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 60, height: 60)
                .offset(x: -20, y: 30)

            VStack(alignment: .leading, spacing: 0) {
                Text("NET THIS MONTH")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.8)
                    .foregroundColor(theme.cardBackground.opacity(0.85))

                let net = transactionStore.totalIncome() - transactionStore.totalExpense()
                Text((net < 0 ? "−" : "") + "฿" + String(format: "%.0f", abs(net)))
                    .font(.system(size: 52, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.cardBackground)
                    .padding(.top, 10)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                HStack(spacing: 8) {
                    HeroStatPill(label: "IN",  amount: transactionStore.totalIncome(),  textColor: theme.cardBackground)
                    HeroStatPill(label: "OUT", amount: transactionStore.totalExpense(), textColor: theme.cardBackground)
                }
                .padding(.top, 14)
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(theme.primary)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }

    private var slipBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(theme.primary.opacity(0.15))
                    .frame(width: 44, height: 44)
                MascotView(size: 30, mood: .alert)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(theme.character == .penguin
                     ? "I caught \(viewModel.recentScannedTransactions.count) slips!"
                     : "Rawr! Found \(viewModel.recentScannedTransactions.count) slips!")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                Text(slipBannerBankSources)
                    .font(.system(size: 12))
                    .foregroundColor(theme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(theme.textSecondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(theme.cardBackground)
                .shadow(color: theme.textPrimary.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
        .onTapGesture { showingSlipReview = true }
    }

    private var lazyTransactionList: some View {
        LazyVStack(spacing: 0) {
            ForEach(groupedTransactions, id: \.key) { section in
                TransactionSectionHeader(date: section.key, transactions: section.value)
                    .background(theme.background)

                VStack(spacing: 0) {
                    let sorted = section.value.sorted(by: { $0.date > $1.date })
                    ForEach(sorted) { transaction in
                        TransactionRow(transaction: transaction)
                            .padding(.horizontal, 16)
                            .background(
                                GeometryReader { geo in
                                    Color(theme.cardBackground).preference(
                                        key: TransactionContentPositionKey.self,
                                        value: [transaction.id: geo.frame(in: .named("homeContent")).minY]
                                    )
                                }
                            )
                        if transaction.id != sorted.last?.id {
                            Divider()
                                .padding(.leading, 72)
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .background(theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Actions

    private func updateTransactionsList() {
        transactionStore.transactions = viewModel.getTransactions(from: transactionStore)
    }

    private func saveTransactionFromSlip(_ slipData: SlipData) {
        viewModel.saveTransactionFromSlip(slipData, into: transactionStore) { data in
            scannerViewModel.suggestCategory(for: data)
        }

        // Refresh list if added transaction belongs to current view
        let calendar = Calendar.current
        let transMonth = calendar.component(.month, from: slipData.parsedDate ?? Date())
        let transYear = calendar.component(.year, from: slipData.parsedDate ?? Date())

        if transMonth == viewModel.currentMonth, transYear == viewModel.currentYear {
            updateTransactionsList()
        }

        // Optional: Provide feedback (haptic or toast)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func triggerBatchScan() {
        // Only reset if we are starting a fresh batch
        if unprocessedCount > 0 {
            // Set the fixed count for this batch
            newSlipsCount = viewModel.recentScannedTransactions.count + unprocessedCount
        }
        scannerViewModel.processBatch(assets: photoService.assets) { count in
        }
    }

    private func refreshData() async {
        photoService.fetchPhotos()

        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)

        await MainActor.run {
            triggerBatchScan()
            updateTransactionsList()
        }
    }

    private func updateStickyHeaderFromPositions() {
        guard scrollOffset > 0 else {
            withAnimation(.easeInOut(duration: 0.15)) { showStickyHeader = false }
            return
        }
        guard !transactionContentPositions.isEmpty else { return }

        // Transaction positions include the section header height (~55pt) above each
        // section's first row. Subtracting that offset makes the accumulation update
        // when the section header leaves the screen — matching the timing users expect.
        let candidate = transactionContentPositions
            .filter { $0.value >= scrollOffset + 55 }
            .min { $0.value < $1.value }
            ?? transactionContentPositions.max { $0.value < $1.value }

        guard let (txnId, _) = candidate else { return }

        let cumulative = cumulativeFromTransactionDown
        let sectionDates = transactionSectionDate
        let data = cumulative[txnId]
        let date = sectionDates[txnId] ?? stickyDate

        withAnimation(.easeInOut(duration: 0.2)) {
            showStickyHeader = true
            stickyDate = date
            stickyExpense = data?.expense ?? 0
            stickyIncome = data?.income ?? 0
        }
    }
}

private struct HeroStatPill: View {
    let label: String
    let amount: Double
    let textColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.5)
                .foregroundColor(textColor.opacity(0.85))
            Text("฿" + String(format: "%.0f", amount))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(textColor)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(Color.white.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct StickyScrollHeader: View {
    let date: Date
    let cumulativeExpense: Double
    let cumulativeIncome: Double
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(date, format: .dateTime.weekday(.abbreviated))
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.5)
                        .textCase(.uppercase)
                        .foregroundColor(theme.textSecondary)
                    Text(date, format: .dateTime.day().month(.abbreviated))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                }

                Spacer()

                HStack(spacing: 14) {
                    if cumulativeIncome > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.left")
                                .font(.system(size: 11))
                                .foregroundColor(theme.income)
                            Text(cumulativeIncome.formattedCurrency)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(theme.income)
                                .contentTransition(.numericText())
                                .animation(.easeInOut(duration: 0.25), value: cumulativeIncome)
                        }
                    }
                    if cumulativeExpense > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 11))
                                .foregroundColor(theme.expense)
                            Text(cumulativeExpense.formattedCurrency)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(theme.expense)
                                .contentTransition(.numericText(countsDown: true))
                                .animation(.easeInOut(duration: 0.25), value: cumulativeExpense)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(theme.background.opacity(0.97))

            Rectangle()
                .fill(theme.separator)
                .frame(height: 0.5)
        }
    }
}

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
        .shadow(color: theme.textPrimary.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

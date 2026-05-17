//
//  HomeView.swift
//  BROKE
//

import Photos
import PhotosUI
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var transactionStore: TransactionStore
    @EnvironmentObject var photoService: PhotoService
    @EnvironmentObject var theme: ThemeManager
    @StateObject private var scannerViewModel = SlipScannerViewModel()
    @StateObject private var viewModel = HomeViewModel()
    @Environment(\.scenePhase) var scenePhase

    @State private var newSlipsCount: Int = 0
    @State private var showingQuotaAlert = false
    @State private var showingAddTransaction = false
    @State private var selectedTransactionForReview: Transaction?

    var unprocessedCount: Int {
        photoService.assets.filter { !ImageHashManager.shared.isProcessed(asset: $0) }.count
    }

    var groupedTransactions: [(key: Date, value: [Transaction])] {
        let grouped = Dictionary(grouping: transactionStore.transactions) { t in
            Calendar.current.startOfDay(for: t.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    var netBalance: Double {
        transactionStore.totalIncome() - transactionStore.totalExpense()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                homeHeader
                    .padding(.top, 56)
                    .padding(.bottom, 18)

                BalanceCard(
                    netAmount: netBalance,
                    incomeAmount: transactionStore.totalIncome(),
                    expenseAmount: transactionStore.totalExpense()
                )
                .padding(.bottom, 14)

                if unprocessedCount > 0 || !viewModel.recentScannedTransactions.isEmpty {
                    SlipBanner(
                        slipCount: max(unprocessedCount, viewModel.recentScannedTransactions.count),
                        onReview: { triggerBatchScan() }
                    )
                    .padding(.bottom, 14)
                }

                monthNav
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                ForEach(groupedTransactions, id: \.key) { section in
                    transactionGroup(date: section.key, transactions: section.value)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)
                }

                Spacer(minLength: 20)
            }
        }
        .background(theme.bg.ignoresSafeArea())
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionView()
        }
        .sheet(item: $selectedTransactionForReview) { transaction in
            AddTransactionView(transactionToEdit: transaction)
        }
        .alert("Limit Exceeded", isPresented: $showingQuotaAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The daily Gemini API quota has been reached. Please try again later.")
        }
        .onReceive(photoService.$isLoadingComplete) { complete in
            if complete { triggerBatchScan() }
        }
        .onReceive(scannerViewModel.$processedSlipData) { slipData in
            if let slipData { saveTransactionFromSlip(slipData) }
        }
        .onReceive(scannerViewModel.$errorMessage) { error in
            if let error, (error.contains("quota") || error.contains("429") || error.contains("RESOURCE_EXHAUSTED")) {
                showingQuotaAlert = true
            }
        }
        .onAppear { updateTransactionsList() }
        .onChange(of: viewModel.currentMonth) { _ in updateTransactionsList() }
        .onChange(of: viewModel.currentYear)  { _ in updateTransactionsList() }
    }

    // MARK: - Header

    private var homeHeader: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(theme.softBrand)
                    .frame(width: 44, height: 44)
                MascotView(size: 28)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Hi, there.")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.ink)
                Text(viewModel.monthYearString)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(theme.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: { showingAddTransaction = true }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(theme.brand)
                        .frame(width: 44, height: 44)
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.brandInk)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Month navigation

    private var monthNav: some View {
        HStack {
            Button(action: viewModel.previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.muted)
                    .frame(width: 32, height: 32)
            }
            Spacer()
            Text(viewModel.monthYearString)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(theme.ink)
            Spacer()
            Button(action: viewModel.nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(viewModel.isCurrentMonthAndYear ? theme.muted.opacity(0.3) : theme.muted)
                    .frame(width: 32, height: 32)
            }
            .disabled(viewModel.isCurrentMonthAndYear)
        }
    }

    // MARK: - Transaction group card

    private func transactionGroup(date: Date, transactions: [Transaction]) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.ink)
                Spacer()
                let daily = transactions.filter { $0.type == .expense }.reduce(0.0) { $0 + $1.amount }
                if daily > 0 {
                    Text("-฿\(Int(daily).formattedWithSeparator)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.muted)
                }
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 8)

            VStack(spacing: 0) {
                let sorted = transactions.sorted(by: { $0.date > $1.date })
                ForEach(Array(sorted.enumerated()), id: \.element.id) { idx, transaction in
                    TransactionRow(transaction: transaction)
                        .onTapGesture { selectedTransactionForReview = transaction }
                    if idx < sorted.count - 1 {
                        Divider()
                            .padding(.leading, 68)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(theme.surface)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
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
        let cal = Calendar.current
        let tm = cal.component(.month, from: slipData.parsedDate ?? Date())
        let ty = cal.component(.year, from: slipData.parsedDate ?? Date())
        if tm == viewModel.currentMonth, ty == viewModel.currentYear {
            updateTransactionsList()
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func triggerBatchScan() {
        if unprocessedCount > 0 {
            newSlipsCount = viewModel.recentScannedTransactions.count + unprocessedCount
        }
        scannerViewModel.processBatch(assets: photoService.assets) { _ in }
    }
}

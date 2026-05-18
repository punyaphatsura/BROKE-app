//
//  HomeView.swift
//  BROKE
//
//  Created by Punyaphat Surakiatkamjorn on 20/4/2568 BE.
//

import Photos
import PhotosUI
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var transactionStore: TransactionStore
    @EnvironmentObject var photoService: PhotoService
    @StateObject private var scannerViewModel = SlipScannerViewModel()
    @StateObject private var viewModel = HomeViewModel()
    @Environment(\.scenePhase) var scenePhase

    @State private var newSlipsCount: Int = 0
    @State private var showingQuotaAlert = false
    @State private var isLastBatchExpanded: Bool = false
    @EnvironmentObject var theme: ThemeManager

    // Computed properties for counts
    var unprocessedCount: Int {
        photoService.assets.filter { !ImageHashManager.shared.isProcessed(asset: $0) }.count
    }

    var processedCount: Int {
        newSlipsCount - unprocessedCount
    }

    var groupedTransactions: [(key: Date, value: [Transaction])] {
        let grouped = Dictionary(grouping: transactionStore.transactions) { transaction in
            Calendar.current.startOfDay(for: transaction.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    var body: some View {
        NavigationView {
            VStack {
                lastBatchScannedView

                monthNavigation

                summaryView

                transactionList

                Spacer()
            }
            .background(theme.background.ignoresSafeArea())
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $viewModel.showingAddTransaction) {
                AddTransactionView() // Manual add
            }
            .sheet(item: $viewModel.selectedTransactionForReview) { transaction in
                AddTransactionView(transactionToEdit: transaction)
            }
            .alert("Limit Exceeded", isPresented: $showingQuotaAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The daily limit for Gemini API has been reached. Please try again later.")
            }
            .onReceive(photoService.$isLoadingComplete) { isComplete in
                if isComplete {
                    triggerBatchScan()
                }
            }
            .onReceive(scannerViewModel.$processedSlipData) { slipData in
                if let slipData = slipData {
                    saveTransactionFromSlip(slipData)
                }
            }
            .onReceive(scannerViewModel.$errorMessage) { error in
                // Check for quota error in message if it bubbles up here,
                // but ideally we check the flag from VM if exposed or just string match
                if let error = error, error.contains("quota") || error.contains("429") || error.contains("RESOURCE_EXHAUSTED") {
                    showingQuotaAlert = true
                } else if let error = error, !error.isEmpty {
                    // Show other errors if needed, or handle them elsewhere
                    print("Scanner Error: \(error)")
                }
            }
            .onAppear {
                updateTransactionsList()
                if newSlipsCount == 0 && unprocessedCount > 0 {
                    self.newSlipsCount = unprocessedCount
                }
            }
            .onChange(of: viewModel.currentMonth) { _ in updateTransactionsList() }
            .onChange(of: viewModel.currentYear) { _ in updateTransactionsList() }
        }
    }

    // MARK: - Subviews

    private var lastBatchScannedView: some View {
        Group {
            if !viewModel.recentScannedTransactions.isEmpty {
                VStack(alignment: .leading) {
                    HStack {
                        Button(action: {
                            withAnimation {
                                isLastBatchExpanded.toggle()
                            }
                        }) {
                            HStack {
                                Text("Last Scanned Batch (\(viewModel.recentScannedTransactions.count)/\(newSlipsCount))")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Image(systemName: isLastBatchExpanded ? "chevron.down" : "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)

                        Spacer()
                        statisticsSection
                    }

                    if isLastBatchExpanded {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.recentScannedTransactions) { transaction in
                                    TransactionThumbnailView(transaction: transaction)
                                        .onTapGesture {
                                            viewModel.selectedTransactionForReview = transaction
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical, 10)
            }
        }
    }

    private var monthNavigation: some View {
        HStack {
            Button(action: viewModel.previousMonth) {
                Image(systemName: "chevron.left")
                    .padding()
            }

            Text(viewModel.monthYearString)
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)

            Button(action: viewModel.nextMonth) {
                Image(systemName: "chevron.right")
                    .padding()
            }
            .disabled(viewModel.isCurrentMonthAndYear)
        }
        .padding(.horizontal)
    }

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

    private var transactionList: some View {
        VStack(alignment: .leading) {
            List {
                ForEach(groupedTransactions, id: \.key) { section in
                    Section(header: TransactionSectionHeader(date: section.key, transactions: section.value)) {
                        ForEach(section.value.sorted(by: { $0.date > $1.date })) { transaction in
                            TransactionRow(transaction: transaction)
                                .listRowBackground(theme.cardBackground)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .refreshable {
                await refreshData()
            }
        }
    }

    private var statisticsSection: some View {
        Group {
            if !photoService.assets.isEmpty {
                HStack(spacing: 12) {
                    if scannerViewModel.isProcessing {
                        processingIndicator
                    } else if unprocessedCount > 0 {
                        scanButton
                    }
                }
                .padding(.trailing, 16)
            }
        }
    }

    private var processingIndicator: some View {
        HStack {
            ProgressView()
                .padding(.trailing, 5)
        }
        .padding(.vertical, 5)
    }

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

    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.showingAddTransaction = true
                }) {
                    Image(systemName: "plus")
                }
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
        print("Starting batch scan...")
        // Only reset if we are starting a fresh batch
        if unprocessedCount > 0 {
            // Set the fixed count for this batch
            newSlipsCount = viewModel.recentScannedTransactions.count + unprocessedCount
        }
        scannerViewModel.processBatch(assets: photoService.assets) { count in
            print("Batch processed: \(count) assets")
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

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
                                .listRowBackground(theme.cardBackground)
                        }
                        .onDelete { indexSet in
                            deleteTransactions(at: indexSet, in: section.value)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .contentMargins(.bottom, 90, for: .scrollContent)
        }
        .background(theme.background.ignoresSafeArea())
        .toolbar {
            if customTransactions == nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTransaction = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionView()
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
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .center, spacing: 0) {
                Text(date, format: .dateTime.weekday(.abbreviated))
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.5)
                    .textCase(.uppercase)
                    .foregroundColor(theme.textSecondary)
                Text(date, format: .dateTime.day())
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
            }
            .frame(width: 44)

            Spacer()

            HStack(spacing: 14) {
                if income > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.left")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(theme.income)
                        Text(income.formattedCurrency)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.income)
                    }
                }
                if expense > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(theme.expense)
                        Text(expense.formattedCurrency)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.expense)
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
    }
}

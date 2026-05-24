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
        VStack(spacing: 0) {
            if let txns = customTransactions {
                let totalExpense = txns.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
                let totalIncome = txns.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(txns.count) transactions")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.textSecondary)
                        if totalExpense > 0 && totalIncome > 0 {
                            Text(totalExpense.formattedCurrency)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(theme.expense)
                        } else if totalIncome > 0 {
                            Text(totalIncome.formattedCurrency)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(theme.income)
                        } else {
                            Text(totalExpense.formattedCurrency)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(theme.expense)
                        }
                    }
                    Spacer()
                    if totalIncome > 0 {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Income")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(theme.textSecondary)
                            Text(totalIncome.formattedCurrency)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(theme.income)
                        }
                    }
                    if totalExpense > 0 {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Expense")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(theme.textSecondary)
                            Text(totalExpense.formattedCurrency)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(theme.expense)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(theme.cardBackground)

                Divider()
            } else {
                Picker("Filter", selection: $filterType) {
                    Text("All").tag(nil as TransactionType?)
                    Text("Income").tag(TransactionType.income as TransactionType?)
                    Text("Expense").tag(TransactionType.expense as TransactionType?)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

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

    private func deleteTransaction(_ transaction: Transaction) {
        if let index = transactionStore.transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactionStore.transactions.remove(at: index)
            transactionStore.saveTransactions()
        }
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

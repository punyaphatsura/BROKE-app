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

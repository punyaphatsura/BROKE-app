//
//  TransactionListView.swift
//  BROKE
//
//  Created by Punyaphat Surakiatkamjorn on 20/4/2568 BE.
//

import SwiftUI

struct TransactionListView: View {
    @EnvironmentObject var transactionStore: TransactionStore
    @State private var showingAddTransaction = false
    @State private var filterType: TransactionType? = nil

    var filteredTransactions: [Transaction] {
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
                Picker("Filter", selection: $filterType) {
                    Text("All").tag(nil as TransactionType?)
                    Text("Income").tag(TransactionType.income as TransactionType?)
                    Text("Expense").tag(TransactionType.expense as TransactionType?)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

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
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddTransaction = true
                    }) {
                        Image(systemName: "plus")
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

    var income: Double {
        transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    var expense: Double {
        transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        HStack(alignment: .center) {
            // Date Part
            VStack(alignment: .center, spacing: 2) {
                Text(date, format: .dateTime.weekday(.abbreviated))
                    .font(.caption)
                    .fontWeight(.bold)
                    .textCase(.uppercase)

                Text(date, format: .dateTime.day())
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .frame(width: 50)

            Spacer()

            // Summary Part
            VStack(alignment: .leading, spacing: 4) {
                if income > 0 {
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.down.left")
                            .foregroundColor(.green)
                        Text(income.formattedCurrency)
                            .foregroundColor(.green)
                    }
                    .frame(maxWidth: .infinity)
                }

                if expense > 0 {
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(.red)
                        Text(expense.formattedCurrency)
                            .foregroundColor(.red)
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

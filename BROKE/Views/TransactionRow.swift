//
//  TransactionRow.swift
//  BROKE
//
//  Created by Punyaphat Surakiatkamjorn on 20/4/2568 BE.
//

import SwiftUI

struct TransactionRow: View {
    @EnvironmentObject var transactionStore: TransactionStore
    let transaction: Transaction
    @State private var showingEditSheet = false

    var body: some View {
        HStack(spacing: 16) {
            if transaction.type == .expense {
                if let categoryId = transaction.categoryId,
                   let category = ExpenseCategory(rawValue: categoryId.rawValue)
                {
                    Menu {
                        ForEach(ExpenseCategory.allCases) { cat in
                            Button(action: {
                                var newTransaction = transaction
                                newTransaction.categoryId = cat
                                transactionStore.updateTransaction(newTransaction)
                            }) {
                                Label(cat.displayName, systemImage: cat.icon)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(category.color)
                                .font(.title)
                        }
                    }
                }
            } else if transaction.type == .income {
                if let categoryId = transaction.incomeCategoryId,
                   let category = IncomeCategory(rawValue: categoryId.rawValue)
                {
                    Menu {
                        ForEach(IncomeCategory.allCases) { cat in
                            Button(action: {
                                var newTransaction = transaction
                                newTransaction.incomeCategoryId = cat
                                transactionStore.updateTransaction(newTransaction)
                            }) {
                                Label(cat.displayName, systemImage: cat.icon)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(category.color)
                                .font(.title)
                        }
                    }
                }
            } else {
                // Transfer
                Image(systemName: "arrow.left.arrow.right")
                    .foregroundColor(.blue)
                    .font(.title)
            }
            VStack(alignment: .leading) {
                if transaction.type == .expense {
                    if let category = transaction.categoryId {
                        Text(category.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                } else if transaction.type == .income {
                    if let category = transaction.incomeCategoryId {
                        Text(category.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                } else {
                    Text("Transfer")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                Text(transaction.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let subTransactions = transaction.subTransactions, !subTransactions.isEmpty {
                    Text(subTransactions.map { $0.categoryId.displayName }.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()
            VStack(alignment: .trailing) {
                Text(transaction.amount.formattedCurrency)
                    .font(.headline)
                    .foregroundColor(transaction.type == .income ? .green : (transaction.type == .expense ? .red : .primary))
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                transactionStore.deleteTransactionById(transaction.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            AddTransactionView(transactionToEdit: transaction)
                .environmentObject(transactionStore)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showingEditSheet = true
        }
    }
}

//
//  TransactionRow.swift
//  BROKE
//

import SwiftUI

struct TransactionRow: View {
    @EnvironmentObject var transactionStore: TransactionStore
    @EnvironmentObject var theme: ThemeManager
    let transaction: Transaction
    @State private var showingEditSheet = false

    var body: some View {
        HStack(spacing: 16) {
            if transaction.type == .expense {
                if let categoryId = transaction.categoryId,
                   let category = ExpenseCategory(rawValue: categoryId.rawValue) {
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
                        Image(systemName: category.icon)
                            .foregroundColor(category.color)
                            .font(.title)
                    }
                }
            } else if transaction.type == .income {
                if let categoryId = transaction.incomeCategoryId,
                   let category = IncomeCategory(rawValue: categoryId.rawValue) {
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
                        Image(systemName: category.icon)
                            .foregroundColor(category.color)
                            .font(.title)
                    }
                }
            } else {
                Image(systemName: "arrow.left.arrow.right")
                    .foregroundColor(theme.primary)
                    .font(.title)
            }

            VStack(alignment: .leading) {
                if transaction.type == .expense {
                    if let category = transaction.categoryId {
                        Text(category.displayName)
                            .font(.headline)
                            .foregroundColor(theme.textPrimary)
                    }
                } else if transaction.type == .income {
                    if let category = transaction.incomeCategoryId {
                        Text(category.displayName)
                            .font(.headline)
                            .foregroundColor(theme.textPrimary)
                    }
                } else {
                    Text("Transfer")
                        .font(.headline)
                        .foregroundColor(theme.textPrimary)
                }
                Text(transaction.description)
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)

                if let subTransactions = transaction.subTransactions, !subTransactions.isEmpty {
                    Text(subTransactions.map { $0.categoryId.displayName }.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(transaction.amount.formattedCurrency)
                .font(.headline)
                .foregroundColor(
                    transaction.type == .income ? theme.income :
                    transaction.type == .expense ? theme.expense :
                    theme.textPrimary
                )
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

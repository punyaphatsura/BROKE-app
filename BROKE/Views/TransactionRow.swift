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
        HStack(spacing: 14) {
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
                            .font(.system(size: 26))
                            .frame(width: 36, alignment: .center)
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
                            .font(.system(size: 26))
                            .frame(width: 36, alignment: .center)
                    }
                }
            } else {
                Image(systemName: "arrow.left.arrow.right")
                    .foregroundColor(theme.primary)
                    .font(.system(size: 26))
                    .frame(width: 36)
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

                if let bank = transaction.bank, bank != .unknown {
                    Text(bank.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(theme.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(theme.primary.opacity(0.12))
                        )
                }

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
        .padding(.vertical, 10)
        .sheet(isPresented: $showingEditSheet) {
            AddTransactionView(transactionToEdit: transaction)
                .environmentObject(transactionStore)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showingEditSheet = true
        }
        .contextMenu {
            Button(role: .destructive) {
                transactionStore.deleteTransactionById(transaction.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

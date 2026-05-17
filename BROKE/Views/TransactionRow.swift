//
//  TransactionRow.swift
//  BROKE
//

import SwiftUI

struct TransactionRow: View {
    @EnvironmentObject var transactionStore: TransactionStore
    @EnvironmentObject var theme: ThemeManager
    let transaction: Transaction

    private var categoryColor: Color {
        if let cat = transaction.categoryId { return cat.color }
        if let cat = transaction.incomeCategoryId { return cat.color }
        return theme.muted
    }

    private var categoryIcon: String {
        if let cat = transaction.categoryId { return cat.icon }
        if let cat = transaction.incomeCategoryId { return cat.icon }
        return transaction.type == .transfer ? "arrow.left.arrow.right" : "questionmark"
    }

    private var displayName: String {
        if let cat = transaction.categoryId { return cat.displayName }
        if let cat = transaction.incomeCategoryId { return cat.displayName }
        return transaction.type == .transfer ? "Transfer" : "Unknown"
    }

    private var amountColor: Color {
        switch transaction.type {
        case .income:   return theme.income
        case .expense:  return theme.expense
        case .transfer: return theme.ink
        }
    }

    private var amountPrefix: String {
        switch transaction.type {
        case .income:   return "+"
        case .expense:  return "−"
        case .transfer: return ""
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Category icon tile
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(categoryColor.opacity(0.14))
                    .frame(width: 40, height: 40)
                Image(systemName: categoryIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(categoryColor)
            }

            // Name + meta
            VStack(alignment: .leading, spacing: 3) {
                Text(displayName)
                    .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.ink)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if !transaction.description.isEmpty {
                        Text(transaction.description)
                            .font(.system(size: 11))
                            .foregroundColor(theme.muted)
                            .lineLimit(1)
                    }
                    if let bank = transaction.bank, bank != .unknown {
                        Text(bank.rawValue)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(theme.ink)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(theme.softBrand))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Amount
            Text("\(amountPrefix)฿\(transaction.amount.formattedCurrency)")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(amountColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                transactionStore.deleteTransactionById(transaction.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

//
//  TransactionRow.swift
//  Meow-Jod-Clone-App
//
//  Created by Punyaphat Surakiatkamjorn on 20/4/2568 BE.
//

import SwiftUI

struct TransactionRow: View {
    @EnvironmentObject var transactionStore: TransactionStore
    let transaction: Transaction
    @State private var showingEditSheet = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                if transaction.type == .expense {
                    if let categoryId = transaction.categoryId,
                       let category = ExpenseCategory(rawValue: categoryId.rawValue) {
                        Text(category.displayName)
                            .font(.headline)
                    }
                } else {
                    if let categoryId = transaction.incomeCategoryId,
                       let category = IncomeCategory(rawValue: categoryId.rawValue) {
                        Text(category.displayName)
                            .font(.headline)
                    }
                }
                
                
                Text(transaction.description)
                    .font(.subheadline)
                        .foregroundColor(.secondary)
           
                Text(transaction.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            VStack(alignment: .trailing) {
                Text(transaction.amount.formattedCurrency)
                    .font(.headline)
                    .foregroundColor(transaction.type == .income ? .green : .red)
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
        .onTapGesture() {
            showingEditSheet = true
        }
    }
}

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
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(transaction.description)
                    .font(.headline)
                
                Text(transaction.category)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(transaction.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("$\(transaction.amount, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(transaction.type == .income ? .green : .red)
                
                Text(transaction.source.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4).swipeActions(edge: .trailing) {
            Button(role: .destructive) { transactionStore.deleteTransactionById(transaction.id)} label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

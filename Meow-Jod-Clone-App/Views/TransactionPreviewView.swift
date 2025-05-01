//
//  TransactionPreviewView.swift
//  Meow-Jod-Clone-App
//
//  Created by Punyaphat Surakiatkamjorn on 20/4/2568 BE.
//

import SwiftUI

struct TransactionPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var transaction: Transaction
    let onConfirm: (Transaction) -> Void
    
    init(transaction: Transaction, onConfirm: @escaping (Transaction) -> Void) {
        _transaction = State(initialValue: transaction)
        self.onConfirm = onConfirm
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Transaction Details")) {
                    Picker("Type", selection: $transaction.type) {
                        Text("Income").tag(TransactionType.income)
                        Text("Expense").tag(TransactionType.expense)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    TextField("Amount", value: $transaction.amount, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                    
                    TextField("Description", text: $transaction.description)
                    
                    DatePicker("Date", selection: $transaction.date, displayedComponents: .date)
                    
//                    TextField("Category", text: $transaction.category)
                }
                
                Section {
                    Button("Confirm Transaction") {
                        onConfirm(transaction)
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                }
            }
            .navigationTitle("Review Transaction")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

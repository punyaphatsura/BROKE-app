//
//  AddTransactionView.swift
//  Meow-Jod-Clone-App
//
//  Created by Punyaphat Surakiatkamjorn on 20/4/2568 BE.
//

import SwiftUI

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var transactionStore: TransactionStore
    
    @State private var amount: Double = 0
    @State private var description: String = ""
    @State private var date: Date = Date()
    @State private var type: TransactionType = .expense
    @State private var category: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Transaction Details")) {
                    Picker("Type", selection: $type) {
                        Text("Income").tag(TransactionType.income)
                        Text("Expense").tag(TransactionType.expense)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    TextField("Amount", value: $amount, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                    
                    TextField("Description", text: $description)
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    TextField("Category", text: $category)
                }
                
                Section {
                    Button("Add Transaction") {
                        let newTransaction = Transaction(
                            amount: amount,
                            description: description,
                            date: date,
                            type: type,
                            category: category.isEmpty ? (type == .income ? "Income" : "Expense") : category,
                            source: .manual
                        )
                        
                        transactionStore.addTransaction(newTransaction)
                        dismiss()
                    }
                    .disabled(amount <= 0 || description.isEmpty)
                }
            }
            .navigationTitle("Add Transaction")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

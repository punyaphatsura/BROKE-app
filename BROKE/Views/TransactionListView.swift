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
                    ForEach(filteredTransactions.sorted(by: { $0.date > $1.date })) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                    .onDelete(perform: deleteTransactions)
                }
                .listStyle(PlainListStyle())
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
    
    private func deleteTransactions(at offsets: IndexSet) {
        // Map offsets of filtered array back to original array
        let transactionsToDelete = offsets.map { filteredTransactions[$0] }
        
        for transaction in transactionsToDelete {
            if let index = transactionStore.transactions.firstIndex(where: { $0.id == transaction.id }) {
                transactionStore.transactions.remove(at: index)
            }
        }
        
        transactionStore.saveTransactions()
    }
}

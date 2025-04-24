//
//  HomeView.swift
//  Meow-Jod-Clone-App
//
//  Created by Punyaphat Surakiatkamjorn on 20/4/2568 BE.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var transactionStore: TransactionStore
    @State private var showingAddTransaction = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Summary Card
                VStack(spacing: 20) {
                    Text("Balance")
                        .font(.headline)
                    Text("$\(transactionStore.balance(), specifier: "%.2f")")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 40) {
                        VStack {
                            Text("Income")
                                .font(.subheadline)
                            Text("$\(transactionStore.totalIncome(), specifier: "%.2f")")
                                .foregroundColor(.green)
                        }
                        
                        VStack {
                            Text("Expenses")
                                .font(.subheadline)
                            Text("$\(transactionStore.totalExpense(), specifier: "%.2f")")
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding()
                
                // Recent Transactions
                VStack(alignment: .leading) {
                    Text("Recent Transactions")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    List {
                        ForEach(Array(transactionStore.transactions.prefix(5))) { transaction in
                            TransactionRow(transaction: transaction)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                
                Spacer()
            }
            .navigationTitle("Dashboard")
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
}

//
//  File.swift
//  Meow-Jod-Clone-App
//
//  Created by Punyaphat Surakiatkamjorn on 20/4/2568 BE.
//

import Foundation
import Combine

class TransactionStore: ObservableObject {
    @Published var transactions: [Transaction] = []
    
    private let saveKey = "transactions"
    
    init() {
        loadTransactions()
    }
    
    func addTransaction(_ transaction: Transaction) {
        transactions.append(transaction)
        saveTransactions()
    }
    
    func deleteTransaction(at offsets: IndexSet) {
        transactions.remove(atOffsets: offsets)
        saveTransactions()
    }
    
    func deleteTransactionById(_ id: UUID) {
        if let index = transactions.firstIndex(where: { $0.id == id }) {
            transactions.remove(at: index)
            saveTransactions()
        }
    }

    
    func loadTransactions() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return }
        
        do {
            transactions = try JSONDecoder().decode([Transaction].self, from: data)
        } catch {
            print("Error loading transactions: \(error)")
        }
    }
    
    func saveTransactions() {
        do {
            let data = try JSONEncoder().encode(transactions)
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("Error saving transactions: \(error)")
        }
    }
    
    func totalIncome() -> Double {
        transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    func totalExpense() -> Double {
        transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    func balance() -> Double {
        totalIncome() - totalExpense()
    }
}

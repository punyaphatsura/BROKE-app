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
    private var allTransactions: [Transaction] = []
    
    private let saveKey = "transactions"
    
    init() {
        self.allTransactions = []
        self.allTransactions = loadTransactions()
        
        let now = Date()
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        transactions = getTransactions(byMonth: currentMonth, year: currentYear)
    }
    
    func addTransaction(_ transaction: Transaction) {
        allTransactions.append(transaction)
        
        // Also add to current view (transactions) and sort
        transactions.append(transaction)
        transactions.sort { $0.date > $1.date }
        
        saveTransactions()
    }
    
    func updateTransaction(_ transaction: Transaction) {
        if let index = allTransactions.firstIndex(where: { $0.id == transaction.id }) {
            allTransactions[index] = transaction
        }
        
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions[index] = transaction
            transactions.sort { $0.date > $1.date }
        }
        
        saveTransactions()
    }
    
    func deleteTransaction(at offsets: IndexSet) {
        let itemsToDelete = offsets.map { transactions[$0] }
        let idsToDelete = itemsToDelete.map { $0.id }
        
        transactions.remove(atOffsets: offsets)
        allTransactions.removeAll { idsToDelete.contains($0.id) }
        
        saveTransactions()
    }
    
    func deleteTransactionById(_ id: UUID) {
        transactions.removeAll { $0.id == id }
        allTransactions.removeAll { $0.id == id }
        saveTransactions()
    }
    
    func clearAllTransactions() {
        transactions.removeAll()
        allTransactions.removeAll()
        saveTransactions()
    }
    
    func loadTransactions() -> [Transaction] {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return [] }
        
        do {
            let data = try JSONDecoder().decode([Transaction].self, from: data)
            return data
        } catch {
            print("Error loading transactions: \(error)")
            return []
        }
    }
    
    func getTransactions(byMonth month: Int, year: Int) -> [Transaction] {
        let calendar = Calendar.current
        return allTransactions.filter { transaction in
            let components = calendar.dateComponents([.month, .year], from: transaction.date)
            return components.month == month && components.year == year
        }.sorted { $0.date > $1.date }
    }
    
    func getAllTransactions() -> [Transaction] {
        return allTransactions
    }
    
    func saveTransactions() {
        do {
            let data = try JSONEncoder().encode(allTransactions)
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

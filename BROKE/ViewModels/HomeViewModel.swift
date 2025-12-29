//
//  HomeViewModel.swift
//  BROKE
//
//  Created by Punyaphat Surakiatkamjorn on 20/4/2568 BE.
//

import Foundation
import SwiftUI
import Photos

@MainActor
class HomeViewModel: ObservableObject {
    @Published var currentMonth: Int
    @Published var currentYear: Int
    @Published var showingAddTransaction = false
    @Published var showingAddExpense = false
    @Published var selectedSlipData: SlipData?
    @Published var selectedTransactionForReview: Transaction?
    @Published var recentScannedTransactions: [Transaction] = []
    
    init() {
        let now = Date()
        let calendar = Calendar.current
        self.currentMonth = calendar.component(.month, from: now)
        self.currentYear = calendar.component(.year, from: now)
    }
    
    var monthYearString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        
        var components = DateComponents()
        components.month = currentMonth
        components.year = currentYear
        
        if let date = Calendar.current.date(from: components) {
            return dateFormatter.string(from: date)
        }
        return "\(currentMonth)/\(currentYear)"
    }
    
    var isCurrentMonthAndYear: Bool {
        let calendar = Calendar.current
        let now = Date()
        return currentMonth == calendar.component(.month, from: now) &&
               currentYear == calendar.component(.year, from: now)
    }
    
    func previousMonth() {
        if currentMonth == 1 {
            currentMonth = 12
            currentYear -= 1
        } else {
            currentMonth -= 1
        }
    }
    
    func nextMonth() {
        if currentMonth == 12 {
            currentMonth = 1
            currentYear += 1
        } else {
            currentMonth += 1
        }
    }
    
    func getTransactions(from store: TransactionStore) -> [Transaction] {
        store.getTransactions(byMonth: currentMonth, year: currentYear)
    }
    
    func saveTransactionFromSlip(_ slipData: SlipData, into store: TransactionStore, suggestionProvider: (SlipData) -> ExpenseCategory) {
        let suggestedCategory = suggestionProvider(slipData)
        
        let transaction = Transaction(
            refId: slipData.refId.isEmpty ? nil : slipData.refId,
            amount: slipData.parsedAmount ?? 0.0,
            description: "Transfer to \(slipData.receiver)",
            date: slipData.parsedDate ?? Date(),
            sender: slipData.sender.isEmpty ? nil : slipData.sender,
            receiver: slipData.receiver.isEmpty ? nil : slipData.receiver,
            type: .expense, // Assuming slips are expenses
            source: .scan,
            categoryId: suggestedCategory,
            bank: slipData.detectedBank,
            imagePath: slipData.imagePath,
            subTransactions: nil
        )
        
        store.addTransaction(transaction)
        
        // Append to recent scans list (newest first)
        recentScannedTransactions.insert(transaction, at: 0)
    }
}

//
//  CSVExportService.swift
//  BROKE
//
//  Created by Assistant on 29/12/2568 BE.
//

import Foundation
import SwiftUI

class CSVExportService {
    
    func generateCSV(transactions: [Transaction]) -> String {
        var csvString = "Date,Time,Type,Category,Amount,Note,Sender,Receiver,Bank,RefID\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        for transaction in transactions {
            let date = dateFormatter.string(from: transaction.date)
            let time = timeFormatter.string(from: transaction.date)
            
            // Map Type
            var typeStr = "Expense"
            switch transaction.type {
            case .income: typeStr = "Income"
            case .expense: typeStr = "Expense"
            case .transfer: typeStr = "Transfer"
            }
            
            // Map Category
            var categoryStr = "-"
            if transaction.type == .income {
                categoryStr = transaction.incomeCategoryId?.displayName ?? "-"
            } else {
                categoryStr = transaction.categoryId?.displayName ?? "-"
            }
            
            // Amount
            let amount = String(format: "%.2f", transaction.amount)
            
            // Fields
            let note = cleanString(transaction.description)
            let sender = cleanString(transaction.sender ?? "-")
            let receiver = cleanString(transaction.receiver ?? "-")
            let bank = cleanString(transaction.bank?.rawValue ?? "-")
            let refId = cleanString(transaction.refId ?? "-")
            
            let line = "\(date),\(time),\(typeStr),\(categoryStr),\(amount),\(note),\(sender),\(receiver),\(bank),\(refId)\n"
            csvString.append(line)
        }
        
        return csvString
    }
    
    private func cleanString(_ input: String) -> String {
        var output = input.replacingOccurrences(of: "\"", with: "\"\"") // Escape quotes
        output = output.replacingOccurrences(of: "\n", with: " ") // Remove newlines
        
        if output.contains(",") || output.contains("\"") {
            return "\"\(output)\""
        }
        
        return output
    }
    
    func exportCSV(transactions: [Transaction]) -> URL? {
        let csvData = generateCSV(transactions: transactions)
        
        let fileName = "BROKE_Export_\(Date().timeIntervalSince1970).csv"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csvData.write(to: path, atomically: true, encoding: .utf8)
            return path
        } catch {
            print("Failed to write CSV file: \(error)")
            return nil
        }
    }
}


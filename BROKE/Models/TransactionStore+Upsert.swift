//
//  TransactionStore+Upsert.swift
//  BROKE
//
//  Created by Assistant on 29/12/2568 BE.
//

import Foundation

extension TransactionStore {
    func upsertTransaction(from slipData: SlipData) {
        // Prepare the new transaction data
        guard let amount = slipData.parsedAmount,
              let date = slipData.parsedDate else {
            print("Skipping invalid slip data: \(slipData)")
            return
        }
        
        let refId = slipData.refId == "-" ? nil : slipData.refId
        
        // Check if transaction with this refId already exists
        if let refId = refId, let index = transactions.firstIndex(where: { $0.refId == refId }) {
            // Update existing
            print("Updating existing transaction with refId: \(refId)")
            var transaction = transactions[index]
            transaction.amount = amount
            transaction.date = date
            transaction.sender = slipData.sender != "-" ? slipData.sender : transaction.sender
            transaction.receiver = slipData.receiver != "-" ? slipData.receiver : transaction.receiver
            transaction.bank = slipData.detectedBank ?? transaction.bank
            
            updateTransaction(transaction)
        } else {
            // Create new
            print("Creating new transaction for refId: \(refId ?? "nil")")
            // Determine Type
            var type: TransactionType = .expense
            if let hint = slipData.typeHint {
                if hint == "income" { type = .income }
                else if hint == "transfer" { type = .transfer }
            }

            // Determine Category
            var expenseCategory: ExpenseCategory? = nil
            var incomeCategory: IncomeCategory? = nil

            if let catHint = slipData.categoryHint {
                if type == .expense {
                    // Default to others if no match
                    expenseCategory = .others
                    
                    if catHint.contains("อาหาร") { expenseCategory = .food }
                    else if catHint.contains("เดินทาง") || catHint.contains("รถ") { expenseCategory = .transport }
                    else if catHint.contains("ช้อปปิ้ง") || catHint.contains("สินค้า") { expenseCategory = .shopping }
                    else if catHint.contains("บันเทิง") { expenseCategory = .entertainment }
                    else if catHint.contains("สุขภาพ") || catHint.contains("ดูแลตัวเอง") { expenseCategory = .health }
                    else if catHint.contains("บ้าน") || catHint.contains("สาธารณูปโภค") { expenseCategory = .accommodation }
                    else if catHint.contains("การศึกษา") { expenseCategory = .education }
                    else if catHint.contains("ท่องเที่ยว") { expenseCategory = .travel }
                    else if catHint.contains("ให้คนอื่น") || catHint.contains("บริจาค") { expenseCategory = .gift }
                    else if catHint.contains("ออมเงิน") || catHint.contains("ลงทุน") { expenseCategory = .investment }
                    else if catHint.contains("ของใช้จำเป็น") { expenseCategory = .necessary }
                    else if catHint.contains("ครอบครัว") || catHint.contains("สัตว์เลี้ยง") { expenseCategory = .family }
                } else if type == .income {
                    // Default to other if no match
                    incomeCategory = .other
                    
                    if catHint.contains("เงินเดือน") { incomeCategory = .salary }
                    else if catHint.contains("ลงทุน") || catHint.contains("ออมเงิน") { incomeCategory = .investment }
                    else if catHint.contains("ให้คนอื่น") || catHint.contains("บริจาค") { incomeCategory = .gift }
                }
            } else {
                 if type == .expense { expenseCategory = .others }
                 else if type == .income { incomeCategory = .other }
            }

            let newTransaction = Transaction(
                refId: refId,
                amount: amount,
                description: slipData.receiver != "-" ? slipData.receiver : "Imported Transaction",
                date: date,
                sender: slipData.sender != "-" ? slipData.sender : nil,
                receiver: slipData.receiver != "-" ? slipData.receiver : nil,
                type: type,
                source: .scan,
                categoryId: expenseCategory,
                incomeCategoryId: incomeCategory,
                bank: slipData.detectedBank
            )
            
            addTransaction(newTransaction)
        }
    }
}


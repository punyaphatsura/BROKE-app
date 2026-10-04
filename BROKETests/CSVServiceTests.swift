//
//  CSVServiceTests.swift
//  BROKETests
//

import Testing
import Foundation
@testable import BROKE

private func makeDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute
    return Calendar(identifier: .gregorian).date(from: components)!
}

private func gregorianComponents(_ date: Date) -> DateComponents {
    Calendar(identifier: .gregorian).dateComponents([.year, .month, .day, .hour, .minute], from: date)
}

struct CSVExportServiceTests {

    @Test func header_includesAnnualAndSubTransactionsColumns() {
        let csv = CSVExportService().generateCSV(transactions: [])
        #expect(csv == "Date,Time,Type,Category,Amount,Note,Sender,Receiver,Bank,RefID,Annual,SubTransactions\n")
    }

    @Test func row_writesSubTransactionsInlineAndAnnualFlag() {
        let t = Transaction(
            amount: 250,
            description: "Lunch",
            date: makeDate(2026, 1, 5, 12, 30),
            type: .expense,
            source: .manual,
            categoryId: .food,
            subTransactions: [
                SubTransaction(amount: 150, categoryId: .food, note: "Noodles"),
                SubTransaction(amount: 100, categoryId: .shopping),
            ],
            isAnnual: true
        )
        let rows = CSVExportService().generateCSV(transactions: [t]).components(separatedBy: "\n")
        #expect(rows[1] == "2026-01-05,12:30,Expense,Food,250.00,Lunch,-,-,-,-,Yes,Food|150.00|Noodles;Shopping|100.00|")
    }

    @Test func row_withoutSubTransactions_leavesColumnEmpty() {
        let t = Transaction(amount: 10, description: "x", date: makeDate(2026, 1, 5, 8, 0), type: .expense, source: .manual, categoryId: .others)
        let rows = CSVExportService().generateCSV(transactions: [t]).components(separatedBy: "\n")
        #expect(rows[1].hasSuffix(",No,"))
    }

    @Test func subNote_stripsDelimiterCharacters() {
        let t = Transaction(
            amount: 10,
            description: "x",
            date: makeDate(2026, 1, 5, 8, 0),
            type: .expense,
            source: .manual,
            categoryId: .food,
            subTransactions: [SubTransaction(amount: 10, categoryId: .food, note: "a|b;c")]
        )
        let rows = CSVExportService().generateCSV(transactions: [t]).components(separatedBy: "\n")
        #expect(rows[1].hasSuffix(",Food|10.00|a b c"))
    }
}

struct CSVImportServiceTests {

    private let service = CSVImportService()

    // MARK: - Format detection

    @Test func detectFormat_recognizesBrokeExport() {
        let csv = "Date,Time,Type,Category,Amount,Note,Sender,Receiver,Bank,RefID\n"
        #expect(service.detectFormat(content: csv) == .broke)
    }

    @Test func detectFormat_recognizesMeowJod() {
        let csv = "วันที่,เวลา,ประเภท,หมวดหมู่,แท็ก,จำนวน,โน๊ต,ช่องทางจ่าย,จ่ายจาก,ธนาคารผู้รับ,ผู้รับ\n"
        #expect(service.detectFormat(content: csv) == .meowJod)
    }

    @Test func detectFormat_unknownHeader_returnsNil() {
        #expect(service.detectFormat(content: "foo,bar\n1,2\n") == nil)
    }

    // MARK: - BROKE format (legacy 10-column export)

    @Test func parseBroke_legacyRows_mapAllFields() {
        let csv = """
        Date,Time,Type,Category,Amount,Note,Sender,Receiver,Bank,RefID
        2025-11-03,09:15,Expense,Transport,45.00,"Taxi, airport",Me,Grab,KBank,ABC123
        2025-11-04,18:00,Income,Salary,30000.00,Payday,-,-,-,-
        """
        let txs = service.parseBrokeCSV(content: csv)
        #expect(txs.count == 2)

        let expense = txs[0]
        #expect(expense.type == .expense)
        #expect(expense.categoryId == .transport)
        #expect(expense.incomeCategoryId == nil)
        #expect(expense.amount == 45)
        #expect(expense.description == "Taxi, airport")
        #expect(expense.sender == "Me")
        #expect(expense.receiver == "Grab")
        #expect(expense.bank == .kbank)
        #expect(expense.refId == "ABC123")
        #expect(expense.isAnnual == false)
        #expect(expense.subTransactions == nil)
        let c = gregorianComponents(expense.date)
        #expect(c.year == 2025 && c.month == 11 && c.day == 3 && c.hour == 9 && c.minute == 15)

        let income = txs[1]
        #expect(income.type == .income)
        #expect(income.incomeCategoryId == .salary)
        #expect(income.categoryId == nil)
        #expect(income.sender == nil)
        #expect(income.receiver == nil)
        #expect(income.bank == nil)
        #expect(income.refId == nil)
    }

    @Test func parseBroke_buddhistYear_convertsToGregorian() {
        let csv = "Date,Time,Type,Category,Amount,Note,Sender,Receiver,Bank,RefID\n2568-11-03,09:15,Expense,Food,10.00,x,-,-,-,-\n"
        let txs = service.parseBrokeCSV(content: csv)
        #expect(txs.count == 1)
        #expect(gregorianComponents(txs[0].date).year == 2025)
    }

    @Test func parseBroke_unknownCategory_fallsBackToOthers() {
        let csv = "Date,Time,Type,Category,Amount,Note,Sender,Receiver,Bank,RefID\n2025-11-03,09:15,Expense,Mystery,10.00,x,-,-,-,-\n"
        let txs = service.parseBrokeCSV(content: csv)
        #expect(txs[0].categoryId == .others)
    }

    @Test func parseBroke_skipsRowsWithInvalidAmountOrDate() {
        let csv = """
        Date,Time,Type,Category,Amount,Note,Sender,Receiver,Bank,RefID
        2025-11-03,09:15,Expense,Food,abc,x,-,-,-,-
        not-a-date,09:15,Expense,Food,10.00,x,-,-,-,-
        2025-11-03,09:15,Expense,Food,10.00,ok,-,-,-,-
        """
        let txs = service.parseBrokeCSV(content: csv)
        #expect(txs.count == 1)
        #expect(txs[0].description == "ok")
    }

    @Test func parseBroke_unescapesDoubledQuotes() {
        let csv = "Date,Time,Type,Category,Amount,Note,Sender,Receiver,Bank,RefID\n2025-11-03,09:15,Expense,Food,10.00,\"He said \"\"hi\"\"\",-,-,-,-\n"
        let txs = service.parseBrokeCSV(content: csv)
        #expect(txs[0].description == "He said \"hi\"")
    }

    // MARK: - Round trip through the new 12-column export

    @Test func roundTrip_preservesSubTransactionsAndAnnual() {
        let original = Transaction(
            refId: "REF-1",
            amount: 250,
            description: "Lunch, with \"friends\"",
            date: makeDate(2026, 1, 5, 12, 30),
            sender: "Me",
            receiver: "Cafe",
            type: .expense,
            source: .manual,
            categoryId: .food,
            bank: .scb,
            subTransactions: [
                SubTransaction(amount: 150, categoryId: .food, note: "Noodles"),
                SubTransaction(amount: 100, categoryId: .shopping),
            ],
            isAnnual: true
        )
        let csv = CSVExportService().generateCSV(transactions: [original])
        let txs = service.parseBrokeCSV(content: csv)
        #expect(txs.count == 1)

        let t = txs[0]
        #expect(t.refId == "REF-1")
        #expect(t.amount == 250)
        #expect(t.description == "Lunch, with \"friends\"")
        #expect(t.sender == "Me")
        #expect(t.receiver == "Cafe")
        #expect(t.type == .expense)
        #expect(t.categoryId == .food)
        #expect(t.bank == .scb)
        #expect(t.isAnnual == true)
        #expect(gregorianComponents(t.date) == gregorianComponents(original.date))

        let subs = t.subTransactions ?? []
        #expect(subs.count == 2)
        #expect(subs[0].amount == 150 && subs[0].categoryId == .food && subs[0].note == "Noodles")
        #expect(subs[1].amount == 100 && subs[1].categoryId == .shopping && subs[1].note == "")
    }

    // MARK: - Meow Jod format still parses

    @Test func parseCSV_meowJodRow_stillProducesSlipData() async throws {
        let csv = """
        วันที่,เวลา,ประเภท,หมวดหมู่,แท็ก,จำนวน,โน๊ต,ช่องทางจ่าย,จ่ายจาก,ธนาคารผู้รับ,ผู้รับ
        3/11/2025,09:15,รายจ่าย,อาหาร,,-120,ข้าว,,KBank,SCB,ร้านข้าว
        """
        let slips = try await service.parseCSV(content: csv)
        #expect(slips.count == 1)
        #expect(slips[0].parsedAmount == 120)
        #expect(slips[0].typeHint == "expense")
        #expect(slips[0].categoryHint == "อาหาร")
    }
}

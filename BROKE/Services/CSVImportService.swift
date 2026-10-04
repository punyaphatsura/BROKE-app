//
//  CSVImportService.swift
//  BROKE
//
//  Created by Assistant on 29/12/2568 BE.
//

import Foundation

enum CSVFormat {
    /// Export from the original Meow Jod app (Thai headers).
    case meowJod
    /// Export produced by this app's CSVExportService (10-column legacy or 12-column current).
    case broke
}

struct CSVImportResult {
    let added: Int
    let updated: Int
}

enum CSVImportError: LocalizedError {
    case permissionDenied
    case notUTF8
    case unrecognizedFormat

    var errorDescription: String? {
        switch self {
        case .permissionDenied: return "Permission denied to access file."
        case .notUTF8: return "Could not read file as UTF-8"
        case .unrecognizedFormat: return "Unrecognized CSV format. Expected a BROKE or Meow Jod export."
        }
    }
}

class CSVImportService {
    // "วันที่", "เวลา", "ประเภท", "หมวดหมู่", "แท็ก", "จำนวน", "โน๊ต", "ช่องทางจ่าย", "จ่ายจาก", "ธนาคารผู้รับ", "ผู้รับ"
    //  0       1       2         3          4       5        6        7            8          9            10

    // MARK: - File access

    /// Reads a file picked via `.fileImporter`, handling security-scoped access.
    static func readFile(at url: URL) throws -> String {
        guard url.startAccessingSecurityScopedResource() else { throw CSVImportError.permissionDenied }
        defer { url.stopAccessingSecurityScopedResource() }
        let data = try Data(contentsOf: url)
        guard let content = String(data: data, encoding: .utf8) else { throw CSVImportError.notUTF8 }
        return content
    }

    // MARK: - Import into store

    /// Detects the file format, parses it, and writes the rows into `store`.
    @MainActor
    func importCSV(content: String, into store: TransactionStore) async throws -> CSVImportResult {
        switch detectFormat(content: content) {
        case .broke:
            return importBroke(parseBrokeCSV(content: content), into: store)
        case .meowJod:
            let slips = try await parseCSV(content: content)
            var added = 0
            var updated = 0
            for slip in slips {
                if slip.refId != "-", store.getAllTransactions().contains(where: { $0.refId == slip.refId }) {
                    updated += 1
                } else {
                    added += 1
                }
                store.upsertTransaction(from: slip)
            }
            return CSVImportResult(added: added, updated: updated)
        case nil:
            throw CSVImportError.unrecognizedFormat
        }
    }

    @MainActor
    private func importBroke(_ parsed: [Transaction], into store: TransactionStore) -> CSVImportResult {
        let existingByRefId = Dictionary(
            store.getAllTransactions().compactMap { t in t.refId.map { ($0, t) } },
            uniquingKeysWith: { first, _ in first }
        )
        var toAdd: [Transaction] = []
        var updated = 0
        for var transaction in parsed {
            if let refId = transaction.refId, let existing = existingByRefId[refId] {
                transaction.id = existing.id
                transaction.source = existing.source
                transaction.imagePath = existing.imagePath
                store.updateTransaction(transaction)
                updated += 1
            } else {
                toAdd.append(transaction)
            }
        }
        store.addTransactions(toAdd)
        return CSVImportResult(added: toAdd.count, updated: updated)
    }

    // MARK: - Format detection

    func detectFormat(content: String) -> CSVFormat? {
        guard let headerLine = content.components(separatedBy: .newlines)
            .first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) else { return nil }
        let header = parseCSVRow(headerLine).map(stripBOM)
        guard let first = header.first else { return nil }
        if first.contains("วันที่") { return .meowJod }
        if first == "Date", header.contains("Amount") { return .broke }
        return nil
    }

    // MARK: - BROKE format

    private let brokeDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = Calendar(identifier: .gregorian)
        return f
    }()

    /// Files written on a device using the Thai Buddhist calendar carry years like 2568.
    private let brokeBuddhistDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = Calendar(identifier: .buddhist)
        return f
    }()

    /// Parses a CSV produced by `CSVExportService`. Columns are matched by header name so both the
    /// legacy 10-column file and the current 12-column file (Annual, SubTransactions) are accepted.
    func parseBrokeCSV(content: String) -> [Transaction] {
        let lines = content.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard let headerLine = lines.first else { return [] }

        var columnIndex: [String: Int] = [:]
        for (i, name) in parseCSVRow(headerLine).map(stripBOM).enumerated() {
            columnIndex[name] = i
        }

        var results: [Transaction] = []
        for line in lines.dropFirst() {
            let columns = parseCSVRow(line)

            func field(_ name: String) -> String? {
                guard let i = columnIndex[name], i < columns.count else { return nil }
                return columns[i]
            }
            /// Fields the exporter writes as "-" when the value is nil.
            func optionalField(_ name: String) -> String? {
                guard let value = field(name), !value.isEmpty, value != "-" else { return nil }
                return value
            }

            guard let amount = Double(field("Amount") ?? ""),
                  let date = parseBrokeDate(field("Date") ?? "", time: field("Time") ?? "") else { continue }

            let type: TransactionType
            switch field("Type") {
            case "Income": type = .income
            case "Transfer": type = .transfer
            default: type = .expense
            }

            let categoryName = optionalField("Category")
            var expenseCategory: ExpenseCategory? = nil
            var incomeCategory: IncomeCategory? = nil
            if type == .income {
                incomeCategory = categoryName.map { name in
                    IncomeCategory.allCases.first { $0.displayName == name } ?? .other
                }
            } else {
                expenseCategory = categoryName.map(matchExpenseCategory(named:))
            }

            let bank = optionalField("Bank")
                .map { Bank(rawValue: $0) ?? Bank.from(string: $0) }
                .flatMap { $0 == .unknown ? nil : $0 }

            results.append(Transaction(
                refId: optionalField("RefID"),
                amount: amount,
                description: field("Note") ?? "",
                date: date,
                sender: optionalField("Sender"),
                receiver: optionalField("Receiver"),
                type: type,
                source: .manual,
                categoryId: expenseCategory,
                incomeCategoryId: incomeCategory,
                bank: bank,
                subTransactions: parseSubTransactions(field("SubTransactions") ?? ""),
                isAnnual: type == .expense && field("Annual") == "Yes"
            ))
        }
        return results
    }

    private func parseBrokeDate(_ dateStr: String, time: String) -> Date? {
        let combined = "\(dateStr) \(time.isEmpty ? "00:00" : time)"
        guard let date = brokeDateFormatter.date(from: combined) else { return nil }
        if Calendar(identifier: .gregorian).component(.year, from: date) > 2400 {
            return brokeBuddhistDateFormatter.date(from: combined)
        }
        return date
    }

    /// Inverse of `CSVExportService.encodeSubTransactions`: `Category|Amount|Note;...`
    private func parseSubTransactions(_ cell: String) -> [SubTransaction]? {
        let subs = cell.split(separator: ";").compactMap { entry -> SubTransaction? in
            let parts = entry.split(separator: "|", maxSplits: 2, omittingEmptySubsequences: false).map(String.init)
            guard parts.count >= 2, let amount = Double(parts[1]) else { return nil }
            return SubTransaction(
                amount: amount,
                categoryId: matchExpenseCategory(named: parts[0]),
                note: parts.count > 2 ? parts[2] : ""
            )
        }
        return subs.isEmpty ? nil : subs
    }

    private func matchExpenseCategory(named name: String) -> ExpenseCategory {
        ExpenseCategory.allCases.first { $0.displayName == name } ?? .others
    }

    private func stripBOM(_ s: String) -> String {
        s.trimmingCharacters(in: CharacterSet(charactersIn: "\u{FEFF}"))
    }

    // MARK: - Meow Jod format

    func parseCSV(content: String) async throws -> [SlipData] {
        var results: [SlipData] = []
        let rows = content.components(separatedBy: .newlines)

        for (index, row) in rows.enumerated() {
            if row.trimmingCharacters(in: .whitespaces).isEmpty { continue }

            let columns = parseCSVRow(row)
            guard columns.count >= 6 else { continue } // Min requirement: Date, Amount

            // Check for header
            if index == 0, columns[0].contains("วันที่") {
                continue
            }

            // Parse Date & Time
            let dateStr = columns[0]
            let timeStr = columns.count > 1 ? columns[1] : "00:00"
            let dateTimeString = "\(dateStr) \(timeStr)"
            let formattedDate = convertToISO(dateStr: dateTimeString)

            // Parse Amount (handle negative values for expenses)
            // Example: -20 -> 20.0
            var amountStr = columns.count > 5 ? columns[5].replacingOccurrences(of: ",", with: "") : "0"
            if let amountDouble = Double(amountStr) {
                amountStr = String(abs(amountDouble))
            }

            // Parse Type and Category
            // Column 2: Type ("รายจ่าย" = expense, "รายรับ" = income, "ย้ายเงิน" = transfer)
            let typeStr = columns.count > 2 ? columns[2] : "รายจ่าย"
            var type = "expense"
            if typeStr == "รายรับ" { type = "income" }
            else if typeStr == "ย้ายเงิน" { type = "transfer" }

            // Column 3: Category
            // Pass this as a hint to SlipData
            let categoryStr = columns.count > 3 ? columns[3].replacingOccurrences(of: "\"", with: "") : ""

            // Receiver / Note
            let receiver = columns.count > 10 ? columns[10] : (columns.count > 6 ? columns[6] : "-")
            let sender = columns.count > 8 ? columns[8] : "-"
            let bank = columns.count > 9 ? columns[9] : "Unknown"

            // Construct SlipData dictionary
            let dict: [String: String] = [
                "bank": bank.isEmpty ? "Unknown" : bank,
                "date": formattedDate,
                "sender": sender.isEmpty ? "-" : sender,
                "receiver": receiver.isEmpty ? "-" : receiver,
                "amount": amountStr,
                "refId": UUID().uuidString,
                "categoryHint": categoryStr,
                "typeHint": type,
            ]

            results.append(SlipData(dictionary: dict))
        }

        return results
    }

    // MARK: - Shared helpers

    /// Splits one CSV line. Quoted fields may contain commas; a doubled quote inside a quoted field is a literal quote.
    private func parseCSVRow(_ row: String) -> [String] {
        var result: [String] = []
        var currentField = ""
        var inQuotes = false
        let chars = Array(row)
        var i = 0

        while i < chars.count {
            let char = chars[i]
            if char == "\"" {
                if inQuotes, i + 1 < chars.count, chars[i + 1] == "\"" {
                    currentField.append("\"")
                    i += 1
                } else {
                    inQuotes.toggle()
                }
            } else if char == ",", !inQuotes {
                result.append(currentField.trimmingCharacters(in: .whitespaces))
                currentField = ""
            } else {
                currentField.append(char)
            }
            i += 1
        }
        result.append(currentField.trimmingCharacters(in: .whitespaces))
        return result
    }

    private func convertToISO(dateStr: String) -> String {
        let formatters = [
            "d/M/yyyy HH:mm",
            "dd/MM/yyyy HH:mm",
            "yyyy-MM-dd HH:mm",
            "d/M/yyyy HH:mm:ss",
        ]

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        outputFormatter.calendar = Calendar(identifier: .gregorian)

        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.calendar = Calendar(identifier: .gregorian)
            if let date = formatter.date(from: dateStr) {
                return outputFormatter.string(from: date)
            }

            formatter.locale = Locale(identifier: "th_TH")
            if let date = formatter.date(from: dateStr) {
                return outputFormatter.string(from: date)
            }
        }
        return dateStr
    }
}

//
//  SettingsViewModel.swift
//  BROKE
//
//  Created by Assistant on 29/12/2568 BE.
//

import Combine
import Foundation
import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var slipOKQuota: Int?
    @Published var isLoadingQuota = false
    @Published var isImporting = false
    @Published var importMessage: String?
    @Published var errorMessage: String?

    var scanStartDate: Date {
        UserDefaults.standard.object(forKey: "firstLaunchDate") as? Date ?? Date()
    }

    private let slipService = SlipExtractionService()
    let csvService = CSVImportService()
    let exportService = CSVExportService()
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupObservers()
    }

    func exportData(store: TransactionStore) -> URL? {
        let transactions = store.getAllTransactions()
        return exportService.exportCSV(transactions: transactions)
    }

    func setupObservers() {
        NotificationCenter.default.publisher(for: SlipExtractionService.quotaUpdatedNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                if let quota = notification.userInfo?["quota"] as? Int {
                    self?.slipOKQuota = quota
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: SlipExtractionService.quotaUsedNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                // Optimistically decrement quota to avoid unnecessary API calls
                if let current = self?.slipOKQuota, current > 0 {
                    self?.slipOKQuota = current - 1
                } else {
                    // If unknown, fetch it
                    self?.fetchQuota()
                }
            }
            .store(in: &cancellables)
    }

    func fetchQuota() {
        isLoadingQuota = true
        errorMessage = nil

        Task {
            do {
                let quota = try await slipService.checkSlipOKQuota()
                self.slipOKQuota = quota
            } catch {
                self.errorMessage = "Failed to fetch quota: \(error.localizedDescription)"
            }
            self.isLoadingQuota = false
        }
    }

    func importCSV(from url: URL, into store: TransactionStore) {
        isImporting = true
        importMessage = "Reading file..."
        errorMessage = nil

        let fileContent: String
        do {
            fileContent = try CSVImportService.readFile(at: url)
        } catch {
            errorMessage = "Read Failed: \(error.localizedDescription)"
            isImporting = false
            return
        }

        Task {
            importMessage = "Analyzing..."
            do {
                let result = try await csvService.importCSV(content: fileContent, into: store)
                importMessage = "Success: \(result.added) added, \(result.updated) updated."
            } catch {
                errorMessage = "Import Failed: \(error.localizedDescription)"
            }
            isImporting = false
        }
    }
}

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

        guard url.startAccessingSecurityScopedResource() else {
            errorMessage = "Permission denied to access file."
            isImporting = false
            return
        }

        // Read data immediately while we have access
        let fileContent: String
        do {
            let data = try Data(contentsOf: url)
            guard let content = String(data: data, encoding: .utf8) else {
                url.stopAccessingSecurityScopedResource()
                errorMessage = "Could not read file as UTF-8"
                isImporting = false
                return
            }
            fileContent = content
        } catch {
            url.stopAccessingSecurityScopedResource()
            errorMessage = "Read Failed: \(error.localizedDescription)"
            isImporting = false
            return
        }

        url.stopAccessingSecurityScopedResource()

        Task {
            await MainActor.run {
                self.importMessage = "Analyzing..."
            }

            do {
                let slips = try await csvService.parseCSV(content: fileContent)

                await MainActor.run {
                    self.importMessage = "Importing \(slips.count) transactions..."

                    var newCount = 0
                    var updateCount = 0

                    for slip in slips {
                        if slip.refId != "-", store.getAllTransactions().contains(where: { $0.refId == slip.refId }) {
                            updateCount += 1
                        } else {
                            newCount += 1
                        }

                        store.upsertTransaction(from: slip)
                    }

                    self.importMessage = "Success: \(newCount) added, \(updateCount) updated."
                    self.isImporting = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Import Failed: \(error.localizedDescription)"
                    self.isImporting = false
                }
            }
        }
    }
}

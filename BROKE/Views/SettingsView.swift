//
//  SettingsView.swift
//  BROKE
//
//  Created by Punyaphat Surakiatkamjorn on 20/4/2568 BE.
//

import PhotosUI
import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var transactionStore: TransactionStore
    @AppStorage("lastScannedDate") private var lastScannedDate: Date?
    @State private var isRequestingAccess = false
    @State private var isImportingFile = false
    @State private var exportedFileURL: URL?
    @State private var isShareSheetPresented = false

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Photo Library Access")) {
                    Button("Request Photo Access") {
                        isRequestingAccess = true
                    }
                    .sheet(isPresented: $isRequestingAccess) {
                        RequestPhotoAccessView()
                    }

                    HStack {
                        Text("Scan Start Date")
                        Spacer()
                        Text("\(viewModel.scanStartDate, formatter: dateFormatter)")
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("SlipOK API")) {
                    HStack {
                        Text("Remaining Quota")
                        Spacer()
                        if viewModel.isLoadingQuota {
                            ProgressView()
                        } else if let quota = viewModel.slipOKQuota {
                            Text("\(quota)")
                                .foregroundColor(quota < 10 ? .red : .primary)
                        } else {
                            Text("-")
                        }
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    Button("Refresh Quota") {
                        viewModel.fetchQuota()
                    }
                    .disabled(viewModel.isLoadingQuota)
                }

                Section(header: Text("Data Management")) {
                    if viewModel.isImporting {
                        HStack {
                            ProgressView()
                            Text(viewModel.importMessage ?? "Importing...")
                        }
                    } else {
                        Button("Import from CSV") {
                            isImportingFile = true
                        }
                    }

                    if let msg = viewModel.importMessage, !viewModel.isImporting {
                        Text(msg)
                            .font(.caption)
                            .foregroundColor(.green)
                    }

                    Button("Export to CSV") {
                        if let url = viewModel.exportData(store: transactionStore) {
                            exportedFileURL = url
                            isShareSheetPresented = true
                        }
                    }
                    .sheet(isPresented: $isShareSheetPresented, onDismiss: {
                        exportedFileURL = nil
                    }) {
                        if let url = exportedFileURL {
                            ShareSheet(activityItems: [url])
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                viewModel.fetchQuota()
            }
            .fileImporter(isPresented: $isImportingFile, allowedContentTypes: [.commaSeparatedText, .plainText], allowsMultipleSelection: false) { result in
                switch result {
                case let .success(urls):
                    if let url = urls.first {
                        viewModel.importCSV(from: url, into: transactionStore)
                    }
                case let .failure(error):
                    viewModel.errorMessage = "File selection failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

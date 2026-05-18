//
//  SettingsView.swift
//  BROKE
//

import PhotosUI
import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var transactionStore: TransactionStore
    @EnvironmentObject var theme: ThemeManager
    @AppStorage("lastScannedDate") private var lastScannedDate: Date?
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("geminiEnabled") private var geminiEnabled: Bool = true
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
                Section(header: Text("Profile")) {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Your name", text: $userName)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(theme.textSecondary)
                    }
                }

                Section(header: Text("Appearance")) {
                    Picker("Theme", selection: $theme.character) {
                        Label("Penguin", systemImage: "snowflake")
                            .tag(ThemeCharacter.penguin)
                        Label("Dragon", systemImage: "flame")
                            .tag(ThemeCharacter.dragon)
                    }

                    Picker("Mode", selection: $theme.appearance) {
                        Label("Light", systemImage: "sun.max")
                            .tag(AppearanceMode.light)
                        Label("Dark", systemImage: "moon")
                            .tag(AppearanceMode.dark)
                        Label("System", systemImage: "circle.lefthalf.filled")
                            .tag(AppearanceMode.system)
                    }
                }

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
                        Text("Quota Used")
                        Spacer()
                        if viewModel.isLoadingQuota {
                            ProgressView()
                        } else if viewModel.slipOKQuota != nil {
                            Text("\(viewModel.slipOKUsedCount) / 5,000 used — \(viewModel.slipOKUsagePercent)%")
                                .foregroundColor(
                                    viewModel.slipOKUsagePercent >= 80
                                        ? theme.expense
                                        : theme.textPrimary
                                )
                        } else {
                            Text("—")
                                .foregroundColor(theme.textSecondary)
                        }
                    }

                    Toggle(isOn: $geminiEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Gemini AI Fallback")
                            Text("Used when SlipOK can't read a slip")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        }
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(theme.expense)
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
                            .foregroundColor(theme.income)
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
            .scrollContentBackground(.hidden)
            .background(theme.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .onAppear {
                viewModel.fetchQuota()
            }
            .fileImporter(
                isPresented: $isImportingFile,
                allowedContentTypes: [.commaSeparatedText, .plainText],
                allowsMultipleSelection: false
            ) { result in
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

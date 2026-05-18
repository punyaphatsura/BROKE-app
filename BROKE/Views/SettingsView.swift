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
    @AppStorage("confirmedSlipsCount") private var confirmedSlipsCount: Int = 0
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

    private var memberSinceString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        let date = UserDefaults.standard.object(forKey: "firstLaunchDate") as? Date ?? Date()
        return formatter.string(from: date)
    }

    private var profileHeroCard: some View {
        ZStack(alignment: .topTrailing) {
            // Mascot in corner
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(-8))
                MascotView(size: 62, mood: .sleepy)
                    .rotationEffect(.degrees(-8))
            }
            .offset(x: -8, y: -8)

            // Text content
            VStack(alignment: .leading, spacing: 6) {
                Text("Member since \(memberSinceString)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(theme.cardBackground.opacity(0.85))
                    .tracking(0.4)
                    .textCase(.uppercase)

                Text(userName.isEmpty ? "Your Profile" : userName)
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.cardBackground)
                    .lineLimit(1)

                Text(theme.character == .penguin
                     ? "❤️ \(confirmedSlipsCount) slips caught by the penguin"
                     : "🔥 \(confirmedSlipsCount) slips sniffed by the dragon")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.cardBackground.opacity(0.9))
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(theme.primary)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    profileHeroCard
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

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
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Buddy")
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)

                        HStack(spacing: 12) {
                            ForEach([ThemeCharacter.penguin, ThemeCharacter.dragon], id: \.self) { character in
                                let isActive = theme.character == character
                                Button(action: { theme.character = character }) {
                                    VStack(spacing: 8) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(isActive ? theme.primary.opacity(0.15) : theme.separator.opacity(0.4))
                                                .frame(width: 52, height: 52)
                                            Image(systemName: character == .penguin ? "snowflake" : "flame")
                                                .font(.system(size: 24))
                                                .foregroundColor(isActive ? theme.primary : theme.textSecondary)
                                        }

                                        Text(character == .penguin ? "Penguin" : "Dragon")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(isActive ? theme.primary : theme.textPrimary)

                                        Text(character == .penguin ? "Cool & calm" : "Bold & toasty")
                                            .font(.system(size: 10))
                                            .foregroundColor(theme.textSecondary)

                                        if isActive {
                                            Text("✓ Active")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(theme.primary)
                                        } else {
                                            Text("Tap to switch")
                                                .font(.system(size: 10))
                                                .foregroundColor(theme.textSecondary)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 18)
                                            .fill(isActive ? theme.primary.opacity(0.08) : Color.clear)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 18)
                                                    .stroke(
                                                        isActive ? theme.primary : theme.primary.opacity(0.15),
                                                        lineWidth: isActive ? 2 : 1
                                                    )
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
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

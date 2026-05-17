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
    @State private var isRequestingAccess = false
    @State private var isImportingFile = false
    @State private var exportedFileURL: URL?
    @State private var isShareSheetPresented = false

    private var dateFormatter: DateFormatter {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none; return f
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                heroCard
                    .padding(.top, 56)

                mascotSwitcher
                    .padding(.horizontal, 16)

                settingsCard("Appearance") {
                    labeledPicker("Theme", selection: $theme.character) {
                        Label("Penguin", systemImage: "snowflake").tag(ThemeCharacter.penguin)
                        Label("Dragon",  systemImage: "flame").tag(ThemeCharacter.dragon)
                    }
                    Divider()
                    labeledPicker("Mode", selection: $theme.appearance) {
                        Label("Light",  systemImage: "sun.max").tag(AppearanceMode.light)
                        Label("Dark",   systemImage: "moon").tag(AppearanceMode.dark)
                        Label("System", systemImage: "circle.lefthalf.filled").tag(AppearanceMode.system)
                    }
                }
                .padding(.horizontal, 16)

                settingsCard("Photo Library") {
                    Button("Request Photo Access") { isRequestingAccess = true }
                        .foregroundColor(theme.brand)
                        .sheet(isPresented: $isRequestingAccess) { RequestPhotoAccessView() }
                    Divider()
                    HStack {
                        Text("Scan Start Date").foregroundColor(theme.ink)
                        Spacer()
                        Text("\(viewModel.scanStartDate, formatter: dateFormatter)")
                            .foregroundColor(theme.muted)
                    }
                }
                .padding(.horizontal, 16)

                settingsCard("SlipOK API") {
                    HStack {
                        Text("Remaining Quota").foregroundColor(theme.ink)
                        Spacer()
                        if viewModel.isLoadingQuota {
                            ProgressView()
                        } else if let quota = viewModel.slipOKQuota {
                            Text("\(quota)")
                                .foregroundColor(quota < 10 ? theme.expense : theme.ink)
                        } else {
                            Text("-").foregroundColor(theme.muted)
                        }
                    }
                    if let error = viewModel.errorMessage {
                        Text(error).font(.caption).foregroundColor(theme.expense)
                    }
                    Divider()
                    Button("Refresh Quota") { viewModel.fetchQuota() }
                        .foregroundColor(theme.brand)
                        .disabled(viewModel.isLoadingQuota)
                }
                .padding(.horizontal, 16)

                settingsCard("Data") {
                    if viewModel.isImporting {
                        HStack {
                            ProgressView()
                            Text(viewModel.importMessage ?? "Importing…").foregroundColor(theme.muted)
                        }
                    } else {
                        Button("Import from CSV") { isImportingFile = true }
                            .foregroundColor(theme.brand)
                    }
                    if let msg = viewModel.importMessage, !viewModel.isImporting {
                        Text(msg).font(.caption).foregroundColor(theme.income)
                    }
                    Divider()
                    Button("Export to CSV") {
                        if let url = viewModel.exportData(store: transactionStore) {
                            exportedFileURL = url
                            isShareSheetPresented = true
                        }
                    }
                    .foregroundColor(theme.brand)
                    .sheet(isPresented: $isShareSheetPresented, onDismiss: { exportedFileURL = nil }) {
                        if let url = exportedFileURL { ShareSheet(activityItems: [url]) }
                    }
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 20)
            }
        }
        .background(theme.bg.ignoresSafeArea())
        .onAppear { viewModel.fetchQuota() }
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

    // MARK: - Hero card

    private var heroCard: some View {
        ZStack(alignment: .topTrailing) {
            MascotView(size: 100)
                .rotationEffect(.degrees(-8))
                .opacity(0.18)
                .offset(x: 10, y: -10)

            VStack(alignment: .leading, spacing: 8) {
                Text("MEMBER SINCE")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1)
                    .foregroundColor(theme.brandInk.opacity(0.7))

                Text("Punyaphat S.")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.brandInk)

                let label = theme.character == .penguin
                    ? "slips caught by the penguin"
                    : "slips toasted by the dragon"
                Text("428 \(label)")
                    .font(.system(size: 13))
                    .foregroundColor(theme.brandInk.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(22)
        }
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(theme.brand)
                .clipped()
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Mascot switcher

    private var mascotSwitcher: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose your mascot")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(theme.muted)

            HStack(spacing: 12) {
                mascotCard(.penguin, label: "Penguin")
                mascotCard(.dragon,  label: "Dragon")
            }
        }
    }

    private func mascotCard(_ char: ThemeCharacter, label: String) -> some View {
        let active = theme.character == char
        // Brand color for the preview: use actual theme.brand for active, a neutral for inactive
        let previewBrand: Color = char == .penguin ? Color(hex: "3D9BF0") : Color(hex: "F5BC1A")
        return Button { theme.character = char } label: {
            VStack(spacing: 10) {
                // Simple mascot preview using a ZStack without needing a separate ThemeManager
                mascotPreview(for: char, brand: previewBrand)
                Text(label)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(active ? theme.brand : theme.muted)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(active ? theme.softBrand : theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(active ? theme.brand : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func mascotPreview(for char: ThemeCharacter, brand: Color) -> some View {
        // Draw a simple branded circle with an SF Symbol — avoids env object injection
        ZStack {
            Circle()
                .fill(brand.opacity(0.15))
                .frame(width: 64, height: 64)
            Image(systemName: char == .penguin ? "snowflake" : "flame")
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(brand)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func settingsCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .tracking(0.5)
                .foregroundColor(theme.muted)
                .padding(.bottom, 10)

            VStack(spacing: 12) {
                content()
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 18).fill(theme.surface))
        }
    }

    @ViewBuilder
    private func labeledPicker<T: Hashable, Content: View>(
        _ label: String,
        selection: Binding<T>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack {
            Text(label).foregroundColor(theme.ink)
            Spacer()
            Picker(label, selection: selection) {
                content()
            }
            .labelsHidden()
        }
    }
}

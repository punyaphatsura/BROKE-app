//
//  WelcomeView.swift
//  BROKE
//

import SwiftUI

/// First-launch screen: restore a CSV export from a previous phone, or start with an empty ledger.
struct WelcomeView: View {
    @EnvironmentObject var transactionStore: TransactionStore
    @EnvironmentObject var theme: ThemeManager
    var onFinished: () -> Void

    @State private var isPickingFile = false
    @State private var isImporting = false
    @State private var importResult: CSVImportResult?
    @State private var errorMessage: String?
    private let importService = CSVImportService()

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            MascotView(size: 120)

            Text("Welcome to BROKE")
                .font(.largeTitle)
                .bold()
                .foregroundColor(theme.textPrimary)

            Text("Restore a CSV export from your previous phone, or start with an empty ledger.")
                .multilineTextAlignment(.center)
                .foregroundColor(theme.textSecondary)
                .padding(.horizontal)

            Spacer()

            if isImporting {
                ProgressView("Importing...")
            } else if let result = importResult {
                Text("Imported \(result.added) transactions")
                    .foregroundColor(theme.income)
                primaryButton("Continue") { onFinished() }
            } else {
                primaryButton("Import from CSV") { isPickingFile = true }
                Button("Start Fresh") { onFinished() }
                    .foregroundColor(theme.primary)
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(theme.expense)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .padding(.bottom, 24)
        .background(theme.background.ignoresSafeArea())
        .preferredColorScheme(theme.preferredColorScheme)
        .fileImporter(
            isPresented: $isPickingFile,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case let .success(urls):
                if let url = urls.first { importFile(at: url) }
            case let .failure(error):
                errorMessage = "File selection failed: \(error.localizedDescription)"
            }
        }
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding()
                .background(theme.primary)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }

    private func importFile(at url: URL) {
        errorMessage = nil
        isImporting = true
        Task {
            do {
                let content = try CSVImportService.readFile(at: url)
                importResult = try await importService.importCSV(content: content, into: transactionStore)
            } catch {
                errorMessage = "Import Failed: \(error.localizedDescription)"
            }
            isImporting = false
        }
    }
}

#Preview {
    WelcomeView(onFinished: {})
        .environmentObject(TransactionStore())
        .environmentObject(ThemeManager())
}

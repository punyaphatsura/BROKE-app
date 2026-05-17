// BROKE/Views/SlipReviewView.swift
import SwiftUI

struct SlipReviewView: View {
    @EnvironmentObject var transactionStore: TransactionStore
    @EnvironmentObject var photoService: PhotoService
    @EnvironmentObject var theme: ThemeManager
    @StateObject private var scannerViewModel = SlipScannerViewModel()
    @StateObject private var viewModel = HomeViewModel()

    @State private var currentIndex: Int = 0
    @State private var showingEditSheet = false
    @State private var showingQuotaAlert = false

    private var slips: [Transaction] {
        viewModel.recentScannedTransactions
    }

    private var currentSlip: Transaction? {
        guard currentIndex < slips.count else { return nil }
        return slips[currentIndex]
    }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            if slips.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        reviewHeader
                        mascotBubble
                        progressBar
                        if let slip = currentSlip {
                            slipCard(slip)
                            actionButtons(slip)
                        }
                        Spacer(minLength: 100)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            if let slip = currentSlip {
                AddTransactionView(transactionToEdit: slip)
                    .environmentObject(transactionStore)
                    .environmentObject(theme)
            }
        }
        .alert("Limit Exceeded", isPresented: $showingQuotaAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The daily limit for Gemini API has been reached.")
        }
        .onReceive(scannerViewModel.$errorMessage) { error in
            if let error, error.contains("quota") || error.contains("429") {
                showingQuotaAlert = true
            }
        }
        .onAppear {
            currentIndex = 0
        }
        .onChange(of: slips.count) {
            if currentIndex >= slips.count {
                currentIndex = max(0, slips.count - 1)
            }
        }
    }

    // MARK: - Subviews

    private var reviewHeader: some View {
        HStack {
            Text("Slip review")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(theme.textPrimary)
            Spacer()
            if !slips.isEmpty {
                Button("Skip all") {
                    currentIndex = slips.count
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(theme.textSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 56)
        .padding(.bottom, 12)
    }

    private var mascotBubble: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(theme.primary.opacity(0.15))
                    .frame(width: 64, height: 64)
                MascotView(size: 44, mood: .happy)
            }

            let msg = theme.character == .penguin
                ? "I caught \(slips.count) slip\(slips.count == 1 ? "" : "s"). Tap Yep if it looks right!"
                : "Rawr! I sniffed out \(slips.count) slip\(slips.count == 1 ? "" : "s"). Tap Yep if it's correct!"

            Text(msg)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(theme.textPrimary)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(theme.cardBackground)
                        .shadow(color: theme.textPrimary.opacity(0.04), radius: 6)
                )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private var progressBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                ForEach(slips.indices, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 999)
                        .fill(i <= currentIndex ? theme.primary : theme.separator)
                        .frame(height: 5)
                }
            }
            HStack {
                Text("Slip \(min(currentIndex + 1, slips.count)) of \(slips.count)")
                    .font(.system(size: 11))
                    .foregroundColor(theme.textSecondary)
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private func slipCard(_ slip: Transaction) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(slip.date, style: .date)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.8)
                    .foregroundColor(theme.textSecondary)
                Spacer()
                if let bank = slip.bank {
                    Text(bank.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                }
            }

            Text("฿" + String(format: "%.2f", slip.amount))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(theme.textPrimary)

            Divider()

            Text(slip.description)
                .font(.system(size: 15))
                .foregroundColor(theme.textPrimary)

            HStack {
                if let cat = slip.categoryId {
                    Image(systemName: cat.icon)
                        .foregroundColor(cat.color)
                    Text(cat.displayName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                } else if let cat = slip.incomeCategoryId {
                    Image(systemName: cat.icon)
                        .foregroundColor(cat.color)
                    Text(cat.displayName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                }
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(theme.cardBackground)
                .shadow(color: theme.textPrimary.opacity(0.06), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    private func actionButtons(_ slip: Transaction) -> some View {
        HStack(spacing: 12) {
            Button(action: { advanceSlip() }) {
                Text("Skip")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(theme.cardBackground)
                    )
            }

            Button(action: { showingEditSheet = true }) {
                Image(systemName: "pencil")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.textSecondary)
                    .frame(width: 52, height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(theme.cardBackground)
                    )
            }

            Button(action: { confirmSlip() }) {
                Text("Yep ✓")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.cardBackground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(theme.primary)
                    )
            }
        }
        .padding(.horizontal, 20)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            MascotView(size: 80, mood: .sleepy)
            Text(theme.character == .penguin
                 ? "No slips waiting!"
                 : "Nothing to sniff out!")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(theme.textPrimary)
            Text("New slips will appear here after a scan.")
                .font(.system(size: 14))
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)

            if !photoService.assets.isEmpty {
                Button(action: { triggerScan() }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Scan Now")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.cardBackground)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(theme.primary)
                    )
                }
            }
        }
        .padding(40)
    }

    // MARK: - Actions

    private func advanceSlip() {
        withAnimation(.easeInOut(duration: 0.2)) {
            currentIndex += 1
        }
    }

    private func confirmSlip() {
        advanceSlip()
    }

    private func triggerScan() {
        scannerViewModel.processBatch(assets: photoService.assets) { _ in }
    }
}

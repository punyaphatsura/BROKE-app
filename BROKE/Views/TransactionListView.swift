//
//  TransactionListView.swift
//  BROKE
//

import SwiftUI

struct TransactionListView: View {
    @EnvironmentObject var transactionStore: TransactionStore
    @EnvironmentObject var theme: ThemeManager
    @State private var showingAddTransaction = false
    @State private var filterType: TransactionType? = nil
    var customTransactions: [Transaction]?

    var filteredTransactions: [Transaction] {
        if let custom = customTransactions { return custom }
        if let filterType { return transactionStore.transactions.filter { $0.type == filterType } }
        return transactionStore.transactions
    }

    var groupedTransactions: [(key: Date, value: [Transaction])] {
        let grouped = Dictionary(grouping: filteredTransactions) {
            Calendar.current.startOfDay(for: $0.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if customTransactions == nil {
                    filterPicker
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                }

                ForEach(groupedTransactions, id: \.key) { section in
                    sectionCard(date: section.key, transactions: section.value)
                        .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 20)
        }
        .background(theme.bg.ignoresSafeArea())
        .toolbar {
            if customTransactions == nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddTransaction = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionView()
        }
    }

    private var filterPicker: some View {
        HStack(spacing: 0) {
            filterBtn(title: "All",     tag: nil)
            filterBtn(title: "Income",  tag: .income)
            filterBtn(title: "Expense", tag: .expense)
        }
        .padding(4)
        .background(Capsule().fill(theme.surface))
    }

    private func filterBtn(title: String, tag: TransactionType?) -> some View {
        let active = filterType == tag
        return Button { filterType = tag } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Capsule().fill(active ? theme.brand : Color.clear))
                .foregroundColor(active ? theme.brandInk : theme.muted)
        }
        .buttonStyle(.plain)
    }

    private func sectionCard(date: Date, transactions: [Transaction]) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.ink)
                Spacer()
                let total = transactions.filter { $0.type == .expense }.reduce(0.0) { $0 + $1.amount }
                if total > 0 {
                    Text("-฿\(Int(total).formattedWithSeparator)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.muted)
                }
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 8)

            VStack(spacing: 0) {
                let sorted = transactions.sorted(by: { $0.date > $1.date })
                ForEach(Array(sorted.enumerated()), id: \.element.id) { idx, tx in
                    TransactionRow(transaction: tx)
                    if idx < sorted.count - 1 {
                        Divider().padding(.leading, 68)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(theme.surface)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
    }

    private func deleteTransactions(at offsets: IndexSet, in transactions: [Transaction]) {
        for t in offsets.map({ transactions[$0] }) {
            if let i = transactionStore.transactions.firstIndex(where: { $0.id == t.id }) {
                transactionStore.transactions.remove(at: i)
            }
        }
        transactionStore.saveTransactions()
    }
}

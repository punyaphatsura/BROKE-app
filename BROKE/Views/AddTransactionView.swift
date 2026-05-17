//
//  AddTransactionView.swift
//  BROKE
//
//  Created by Punyaphat Surakiatkamjorn on 20/4/2568 BE.
//

import Photos
import SwiftUI

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var transactionStore: TransactionStore

    let slipData: SlipData?
    let transactionToEdit: Transaction?

    @State private var amount: String = ""
    @State private var description: String = ""
    @State private var date: Date = .init()
    @State private var type: TransactionType = .expense
    @State private var selectedCategory: ExpenseCategory = .others
    @State private var selectedIncomeCategory: IncomeCategory = .other
    @State private var selectedBank: Bank = .unknown
    @State private var sender: String = ""
    @State private var receiver: String = ""
    @State private var refId: String = ""
    @State private var loadedImage: UIImage? = nil

    @State private var isShowSlip: Bool = false
    @State private var showZoom: Bool = false // <- swap to zoom view AFTER the matched-geometry animation
    @State private var draftSubTransactions: [DraftSubTransaction] = [DraftSubTransaction()]

    // Draft struct to handle text input
    struct DraftSubTransaction: Identifiable {
        let id = UUID()
        var amount: String = ""
        var category: ExpenseCategory = .others
    }

    // For custom date picker
    @State private var showDatePicker: Bool = false

    // For collapsing details
    @State private var showMoreDetails: Bool = false

    @State private var subTransactionError: String? = nil

    @State private var isCategoryExpanded: Bool = false
    @FocusState private var focusedField: Field?
    @Namespace private var smoothImage

    enum Field: Hashable {
        case amount
        case description
        case sender
        case receiver
        case refId
        case subAmount(UUID) // Focus per row
    }

    init(slipData: SlipData? = nil, transactionToEdit: Transaction? = nil) {
        self.slipData = slipData
        self.transactionToEdit = transactionToEdit
    }

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()

            NavigationView {
                ScrollView {
                    VStack(spacing: 20) {
                        typePicker
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        heroAmount
                            .padding(.horizontal, 20)

                        if type != .transfer {
                            categoryGrid
                                .padding(.horizontal, 20)
                        }

                        noteField
                            .padding(.horizontal, 20)

                        if type == .expense {
                            subTransactionsSection
                                .padding(.horizontal, 4)
                        }

                        if loadedImage != nil || transactionToEdit?.imagePath != nil {
                            slipImageSection
                                .padding(.horizontal, 20)
                        }

                        moreDetailsSection
                            .padding(.horizontal, 20)

                        Spacer(minLength: 40)
                    }
                }
                .background(theme.bg)
                .navigationTitle(transactionToEdit == nil ? "New Entry" : "Edit Entry")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                            .foregroundColor(theme.muted)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(action: saveTransaction) {
                            Text(transactionToEdit == nil ? "Save" : "Update")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(theme.brandInk)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 7)
                                .background(Capsule().fill(amount.isEmpty ? theme.muted : theme.brand))
                        }
                        .disabled(amount.isEmpty)
                    }
                    ToolbarItem(placement: .keyboard) {
                        HStack { Spacer(); Button("Done") { focusedField = nil } }
                    }
                }
            }
            .onAppear {
                if let transaction = transactionToEdit {
                    populateFromTransaction(transaction)
                    loadImage(from: transaction.imagePath)
                } else {
                    populateFromSlipData()
                }
            }
            .sheet(isPresented: $showDatePicker) {
                DatePicker("Select Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                    .padding()
            }

            if isShowSlip {
                fullScreenSlipOverlay
                    .transition(.opacity)
                    .zIndex(999)
            }
        }
    }

    // MARK: - New visual helpers

    private var typePicker: some View {
        HStack(spacing: 0) {
            typeBtn("Expense",  tag: .expense)
            typeBtn("Income",   tag: .income)
            typeBtn("Transfer", tag: .transfer)
        }
        .padding(4)
        .background(
            Capsule()
                .fill(theme.surface)
                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 1)
        )
    }

    private func typeBtn(_ title: String, tag: TransactionType) -> some View {
        Button { type = tag } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity)
                .background(Capsule().fill(type == tag ? theme.brand : Color.clear))
                .foregroundColor(type == tag ? theme.brandInk : theme.muted)
        }
        .buttonStyle(.plain)
    }

    private var heroAmount: some View {
        VStack(spacing: 10) {
            Text("AMOUNT · THB")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(1)
                .foregroundColor(theme.muted)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("฿")
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.brand)
                TextField("0", text: $amount)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 92, weight: .semibold, design: .rounded))
                    .minimumScaleFactor(0.3)
                    .multilineTextAlignment(.center)
                    .focused($focusedField, equals: .amount)
                    .foregroundColor(theme.ink)
            }

            Button(action: { showDatePicker = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13))
                    Text(dateFormatted)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                }
                .foregroundColor(theme.ink)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(theme.surface))
            }
        }
    }

    private var categoryGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(theme.muted)

            if type == .expense {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                    ForEach(ExpenseCategory.allCases) { cat in
                        expenseCatCell(cat)
                    }
                }
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                    ForEach(IncomeCategory.allCases) { cat in
                        incomeCatCell(cat)
                    }
                }
            }
        }
    }

    private func expenseCatCell(_ cat: ExpenseCategory) -> some View {
        let active = selectedCategory == cat
        return Button { selectedCategory = cat } label: {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(active ? cat.color : cat.color.opacity(0.14))
                        .frame(height: 52)
                    Image(systemName: cat.icon)
                        .font(.system(size: 20))
                        .foregroundColor(active ? .white : cat.color)
                }
                Text(cat.displayName)
                    .font(.system(size: 10))
                    .foregroundColor(active ? theme.ink : theme.muted)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }

    private func incomeCatCell(_ cat: IncomeCategory) -> some View {
        let active = selectedIncomeCategory == cat
        return Button { selectedIncomeCategory = cat } label: {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(active ? cat.color : cat.color.opacity(0.14))
                        .frame(height: 52)
                    Image(systemName: cat.icon)
                        .font(.system(size: 20))
                        .foregroundColor(active ? .white : cat.color)
                }
                Text(cat.displayName)
                    .font(.system(size: 10))
                    .foregroundColor(active ? theme.ink : theme.muted)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }

    private var noteField: some View {
        HStack(spacing: 12) {
            Image(systemName: "square.and.pencil")
                .foregroundColor(theme.muted)
            TextField("Add a note…", text: $description)
                .focused($focusedField, equals: .description)
                .foregroundColor(theme.ink)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(theme.surface)
        )
    }

    private var moreDetailsSection: some View {
        DisclosureGroup(
            isExpanded: $showMoreDetails,
            content: {
                VStack(spacing: 16) {
                    Divider()
                    HStack {
                        Text("Bank")
                            .foregroundColor(theme.muted)
                        Spacer()
                        Picker("Bank", selection: $selectedBank) {
                            ForEach(Bank.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .labelsHidden()
                    }
                    customTextField("Sender", text: $sender, field: .sender)
                    customTextField("Receiver", text: $receiver, field: .receiver)
                    customTextField("Reference ID", text: $refId, field: .refId)
                }
                .padding(.top, 8)
            },
            label: {
                Text("More Details")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.ink)
            }
        )
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(theme.surface)
        )
    }

    private func customTextField(_ title: String, text: Binding<String>, field: Field) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(theme.muted)
            TextField(title, text: text)
                .focused($focusedField, equals: field)
                .padding(10)
                .background(theme.bg)
                .cornerRadius(8)
                .foregroundColor(theme.ink)
        }
    }

    // MARK: - Sub Transactions Section

    private var subTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sub Transactions")
                    .font(.headline)
                    .foregroundColor(theme.muted)
                Spacer()

                // Add Remaining Button
                if remainingAmount > 0 {
                    Button(action: addRemainingAmount) {
                        Text("Add Remaining (\(remainingAmount.formattedCurrency))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(theme.brand)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(theme.brand.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach($draftSubTransactions) { $draft in
                    HStack {
                        // Amount Field
                        TextField("Amount", text: $draft.amount)
                            .textFieldStyle(.plain)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .subAmount(draft.id))
                            .multilineTextAlignment(.trailing)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(theme.bg.opacity(0.7))
                            .cornerRadius(6)
                            .onChange(of: draft.amount) { _ in
                                handleDraftChange()
                            }

                        Spacer()

                        // Category Menu (Icon Only)
                        Menu {
                            ForEach(ExpenseCategory.allCases) { category in
                                Button(action: { draft.category = category }) {
                                    Label(category.displayName, systemImage: category.icon)
                                }
                            }
                        } label: {
                            Image(systemName: draft.category.icon)
                                .foregroundColor(draft.category.color)
                                .font(.title2)
                                .frame(width: 30, height: 30)
                        }

                        // Delete Button
                        Button(action: {
                            deleteDraft(id: draft.id)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                                .font(.title3)
                        }
                        .padding(.leading, 8)
                    }
                    .padding()

                    if draft.id != draftSubTransactions.last?.id {
                        Divider().padding(.leading)
                    }
                }

                // Validation Error
                if let error = subTransactionError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .background(theme.surface)
            .cornerRadius(16)
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    // MARK: - Slip Image Section

    private var slipImageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Slip Image")
                .font(.headline)
                .foregroundColor(theme.muted)

            if let loadedImage = loadedImage {
                if !isShowSlip {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(theme.surface)
                            .frame(height: 200)

                        Image(uiImage: loadedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 180)
                            .cornerRadius(12)
                            .matchedGeometryEffect(id: "slipImage", in: smoothImage)
                            .onTapGesture {
                                focusedField = nil
                                showZoom = false
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    isShowSlip = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                    if isShowSlip { showZoom = true }
                                }
                            }
                    }
                } else {
                    // Placeholder when image is in full screen mode to maintain layout
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.clear)
                        .frame(height: 200)
                }
            } else if transactionToEdit?.imagePath != nil {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(height: 200)
                .background(theme.surface)
                .cornerRadius(16)
            }
        }
    }

    // MARK: - Fullscreen Overlay (same hierarchy)

    private var fullScreenSlipOverlay: some View {
        Group {
            if let loadedImage = loadedImage {
                ZStack {
                    // simpler background during animation (less jank)
                    Color.black.opacity(0.9)
                        .ignoresSafeArea()
                        .onTapGesture { closeSlip() }

                    // Phase 1 (smooth): matchedGeometryEffect with a pure SwiftUI Image
                    // Phase 2 (functional): swap to ZoomableScrollView after animation settles
                    if showZoom {
                        ZoomableScrollView {
                            Image(uiImage: loadedImage)
                                .resizable()
                                .scaledToFit()
                        }
                        .padding()
                    } else {
                        Image(uiImage: loadedImage)
                            .resizable()
                            .scaledToFit()
                            .matchedGeometryEffect(id: "slipImage", in: smoothImage)
                            .padding()
                    }

                    VStack(spacing: 0) {
                        HStack {
                            Spacer()
                            Button(action: { closeSlip() }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(16)
                            }
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    private func closeSlip() {
        showZoom = false
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            isShowSlip = false
        }
    }

    // MARK: - Helper Methods

    private var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d MMM yy, HH:mm"
        return formatter.string(from: date)
    }

    private var remainingAmount: Double {
        let total = Double(amount) ?? 0.0
        let currentUsed = draftSubTransactions.reduce(0.0) { $0 + (Double($1.amount) ?? 0.0) }
        return max(0, total - currentUsed)
    }

    private func handleDraftChange() {
        // Clear error
        subTransactionError = nil

        let mainTotal = Double(amount) ?? 0.0
        let currentUsed = draftSubTransactions.reduce(0.0) { $0 + (Double($1.amount) ?? 0.0) }

        // 1. Cleanup: If we meet or exceed total, remove trailing empty row
        if currentUsed >= mainTotal {
            if let last = draftSubTransactions.last, last.amount.isEmpty {
                draftSubTransactions.removeLast()
            }
        }

        // 2. Append: If we have room, and the last row is Valid/Filled, append new
        if currentUsed < mainTotal {
            if let last = draftSubTransactions.last, let val = Double(last.amount), val > 0 {
                // Only append if last is not empty (already satisfied by val > 0)
                draftSubTransactions.append(DraftSubTransaction())
            }
        }

        // Error check
        if currentUsed > mainTotal {
            subTransactionError = "Exceeds total amount"
        }
    }

    private func addRemainingAmount() {
        let remainder = remainingAmount
        if remainder <= 0 { return }

        // If last row is empty, fill it. Else append.
        if let idx = draftSubTransactions.indices.last, draftSubTransactions[idx].amount.isEmpty {
            draftSubTransactions[idx].amount = String(remainder)
        } else {
            draftSubTransactions.append(DraftSubTransaction(amount: String(remainder)))
        }
    }

    private func deleteDraft(id: UUID) {
        if let index = draftSubTransactions.firstIndex(where: { $0.id == id }) {
            draftSubTransactions.remove(at: index)
        }
        // Ensure at least one empty row if list becomes empty
        if draftSubTransactions.isEmpty {
            draftSubTransactions.append(DraftSubTransaction())
        }
    }

    private func populateFromTransaction(_ transaction: Transaction) {
        amount = String(transaction.amount) // Need this first for total check
        description = transaction.description
        date = transaction.date
        type = transaction.type
        if let category = transaction.categoryId { selectedCategory = category }
        if let incomeCategory = transaction.incomeCategoryId { selectedIncomeCategory = incomeCategory }
        if let bank = transaction.bank { selectedBank = bank }
        sender = transaction.sender ?? ""
        receiver = transaction.receiver ?? ""
        refId = transaction.refId ?? ""

        // Handle SubTransactions
        if let subs = transaction.subTransactions {
            draftSubTransactions = subs.map { DraftSubTransaction(amount: String($0.amount), category: $0.categoryId) }
            // Only add empty row if there is remaining amount
            let subTotal = subs.reduce(0) { $0 + $1.amount }
            if subTotal < (Double(amount) ?? 0.0) {
                draftSubTransactions.append(DraftSubTransaction())
            }
        } else {
            draftSubTransactions = [DraftSubTransaction()]
        }
    }

    private func saveTransaction() {
        guard let amountValue = Double(amount) else { return }

        // Convert drafts to SubTransactions
        let finalSubs: [SubTransaction]? = {
            let valid = draftSubTransactions.compactMap { draft -> SubTransaction? in
                guard let val = Double(draft.amount), val > 0 else { return nil }
                return SubTransaction(amount: val, categoryId: draft.category)
            }
            return valid.isEmpty ? nil : valid
        }()

        if var transaction = transactionToEdit {
            transaction.amount = amountValue
            transaction.description = description.isEmpty ? (type == .income ? "Income" : (type == .expense ? "Expense" : "Transfer")) : description
            transaction.date = date
            transaction.type = type
            transaction.sender = sender.isEmpty ? nil : sender
            transaction.receiver = receiver.isEmpty ? nil : receiver
            transaction.categoryId = type == .expense ? selectedCategory : nil
            transaction.incomeCategoryId = type == .income ? selectedIncomeCategory : nil
            transaction.bank = selectedBank == .unknown ? nil : selectedBank
            transaction.refId = refId.isEmpty ? nil : refId
            transaction.subTransactions = finalSubs

            transactionStore.updateTransaction(transaction)
        } else {
            let transaction = Transaction(
                refId: refId.isEmpty ? nil : refId,
                amount: amountValue,
                description: description.isEmpty ? (type == .income ? "Income" : (type == .expense ? "Expense" : "Transfer")) : description,
                date: date,
                sender: sender.isEmpty ? nil : sender,
                receiver: receiver.isEmpty ? nil : receiver,
                type: type,
                source: slipData != nil ? .scan : .manual,
                categoryId: type == .expense ? selectedCategory : nil,
                incomeCategoryId: type == .income ? selectedIncomeCategory : nil,
                bank: selectedBank == .unknown ? nil : selectedBank,
                imagePath: nil,
                subTransactions: finalSubs
            )
            transactionStore.addTransaction(transaction)
        }

        dismiss()
    }

    private func populateFromSlipData() {
        guard let slipData = slipData else { return }

        if let parsedAmount = slipData.parsedAmount { amount = String(parsedAmount) }
        if let parsedDate = slipData.parsedDate { date = parsedDate }
        if let detectedBank = slipData.detectedBank { selectedBank = detectedBank }

        sender = slipData.sender
        receiver = slipData.receiver
        refId = slipData.refId
        description = "Transfer to \(slipData.receiver)"
        type = .expense
    }

    private func loadImage(from localIdentifier: String?) {
        guard let localIdentifier = localIdentifier else { return }

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        guard let asset = assets.firstObject else { return }

        let manager = PHCachingImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true

        manager.requestImage(
            for: asset,
            targetSize: CGSize(width: 1000, height: 1000),
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            DispatchQueue.main.async {
                self.loadedImage = image
            }
        }
    }

    // MARK: - Zoomable ScrollView (UIKit)

    struct ZoomableScrollView<Content: View>: UIViewRepresentable {
        let content: Content

        init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }

        func makeUIView(context: Context) -> UIScrollView {
            let scrollView = UIScrollView()
            scrollView.delegate = context.coordinator
            scrollView.maximumZoomScale = 5.0
            scrollView.minimumZoomScale = 1.0
            scrollView.bouncesZoom = true
            scrollView.backgroundColor = .clear

            let hostingController = UIHostingController(rootView: content)
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            hostingController.view.backgroundColor = .clear

            scrollView.addSubview(hostingController.view)

            NSLayoutConstraint.activate([
                hostingController.view.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
                hostingController.view.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
                hostingController.view.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
                hostingController.view.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
            ])

            return scrollView
        }

        func updateUIView(_: UIScrollView, context _: Context) {}

        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        class Coordinator: NSObject, UIScrollViewDelegate {
            var parent: ZoomableScrollView

            init(_ parent: ZoomableScrollView) {
                self.parent = parent
            }

            func viewForZooming(in scrollView: UIScrollView) -> UIView? {
                return scrollView.subviews.first
            }
        }
    }
}

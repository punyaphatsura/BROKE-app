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

    // ... (init)

    // ... (body) -> subTransactionsSection update

    private var subTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sub Transactions")
                    .font(.headline)
                    .foregroundColor(theme.textSecondary)
                Spacer()
                
                // Add Remaining Button
                if remainingAmount > 0 {
                    Button(action: addRemainingAmount) {
                        Text("Add Remaining (\(remainingAmount.formattedCurrency))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(theme.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(theme.primary.opacity(0.1))
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
                            .background(theme.cardBackground.opacity(0.7))
                            .cornerRadius(6)
                            . onChange(of: draft.amount) { _ in
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

                        // Delete Button (only if not the only empty row, or just clearer to allow delete)
                        Button(action: {
                            deleteDraft(id: draft.id)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                                .font(.title3)
                        }
                        .padding(.leading, 8)
                        // Don't allowing deleting the last single empty row if you want, or just re-add
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
            .background(theme.cardBackground)
            .cornerRadius(16)
            .padding(.horizontal) // Matches prior styling
            .padding(.bottom)
        }
    }
    
    // ... logic helpers
    
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
        // Ensure at least one empty row if list becomes empty?
        if draftSubTransactions.isEmpty {
            draftSubTransactions.append(DraftSubTransaction())
        }
    }

    // ... update populate and save logic ... 
    
    private func populateFromTransaction(_ transaction: Transaction) {
        // ... previous basic fields ...
        amount = String(transaction.amount) // Need this first for total check
        // ... (copy lines 639-648)
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
             // If manual amount set but no subs, add one empty. 
             // Logic: If opening "New", amount is "" -> append one.
             // If opening "Edit" with amount 100 but no subs -> append one.
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

    init(slipData: SlipData? = nil, transactionToEdit: Transaction? = nil) {
        self.slipData = slipData
        self.transactionToEdit = transactionToEdit
    }

    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

            NavigationView {
                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Type & Amount

                        VStack(spacing: 20) {
                            Picker("Type", selection: $type) {
                                Text("Expense").tag(TransactionType.expense)
                                Text("Income").tag(TransactionType.income)
                                Text("Transfer").tag(TransactionType.transfer)
                            }
                            .pickerStyle(SegmentedPickerStyle())

                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("฿")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.secondary)

                                TextField("0", text: $amount)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 64, weight: .bold))
                                    .multilineTextAlignment(.center)
                                    .focused($focusedField, equals: .amount)
                                    .minimumScaleFactor(0.5)
                            }
                            .padding(.vertical, 8)

                            // Date Row
                            Button(action: { showDatePicker = true }) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(theme.primary)
                                    Text(dateFormatted)
                                        .foregroundColor(theme.textPrimary)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(theme.textSecondary)
                                }
                                .padding()
                                .background(theme.cardBackground.opacity(0.7))
                                .cornerRadius(10)
                            }
                        }
                        .padding()
                        .background(theme.cardBackground)
                        .cornerRadius(20)
                        .padding(.horizontal)
                        .shadow(color: theme.textPrimary.opacity(0.05), radius: 5, x: 0, y: 2)

                        // MARK: - Category

                        if type != .transfer {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Category")
                                        .font(.headline)
                                        .foregroundColor(theme.textSecondary)
                                    Spacer()
                                    Button(action: {
                                        withAnimation(.spring()) {
                                            isCategoryExpanded.toggle()
                                        }
                                    }) {
                                        Image(systemName: isCategoryExpanded ? "chevron.up" : "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(theme.primary)
                                            .padding(8)
                                            .background(theme.cardBackground.opacity(0.7))
                                            .clipShape(Circle())
                                    }
                                }
                                .padding(.horizontal)

                                if type == .expense {
                                    if isCategoryExpanded {
                                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 8) {
                                            ForEach(ExpenseCategory.allCases) { category in
                                                categoryButton(
                                                    icon: category.icon,
                                                    color: category.color,
                                                    name: category.displayName,
                                                    isSelected: selectedCategory == category
                                                ) {
                                                    selectedCategory = category
                                                }
                                            }
                                        }
                                        .padding()
                                        .background(theme.cardBackground)
                                        .cornerRadius(20)
                                        .padding(.horizontal)
                                    } else {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 16) {
                                                ForEach(ExpenseCategory.allCases) { category in
                                                    categoryButton(
                                                        icon: category.icon,
                                                        color: category.color,
                                                        name: category.displayName,
                                                        isSelected: selectedCategory == category
                                                    ) {
                                                        selectedCategory = category
                                                    }
                                                }
                                            }
                                            .padding()
                                        }
                                        .background(theme.cardBackground)
                                        .cornerRadius(20)
                                        .padding(.horizontal)
                                    }
                                } else {
                                    if isCategoryExpanded {
                                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 8) {
                                            ForEach(IncomeCategory.allCases) { category in
                                                categoryButton(
                                                    icon: category.icon,
                                                    color: category.color,
                                                    name: category.displayName,
                                                    isSelected: selectedIncomeCategory == category
                                                ) {
                                                    selectedIncomeCategory = category
                                                }
                                            }
                                        }
                                        .padding()
                                        .background(theme.cardBackground)
                                        .cornerRadius(20)
                                        .padding(.horizontal)
                                    } else {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 16) {
                                                ForEach(IncomeCategory.allCases) { category in
                                                    categoryButton(
                                                        icon: category.icon,
                                                        color: category.color,
                                                        name: category.displayName,
                                                        isSelected: selectedIncomeCategory == category
                                                    ) {
                                                        selectedIncomeCategory = category
                                                    }
                                                }
                                            }
                                            .padding()
                                        }
                                        .background(theme.cardBackground)
                                        .cornerRadius(20)
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }

                        // MARK: - Note

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Note")
                                .font(.headline)
                                .foregroundColor(theme.textSecondary)
                                .padding(.horizontal)

                            HStack {
                                Image(systemName: "square.and.pencil")
                                    .foregroundColor(theme.textSecondary)
                                TextField("Add a description...", text: $description)
                                    .focused($focusedField, equals: .description)
                            }
                            .padding()
                            .background(theme.cardBackground)
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }

                        // MARK: - Sub Transactions (Expense Only)

                        if type == .expense {
                            subTransactionsSection
                        }

                        // MARK: - Slip Image

                        if loadedImage != nil || transactionToEdit?.imagePath != nil {
                            slipImageSection
                                .padding(.horizontal)
                        }

                        // MARK: - More Details (Bank, etc)

                        DisclosureGroup(
                            isExpanded: $showMoreDetails,
                            content: {
                                VStack(spacing: 16) {
                                    Divider()

                                    HStack {
                                        Text("Bank")
                                        Spacer()
                                        Picker("Bank", selection: $selectedBank) {
                                            ForEach(Bank.allCases) { bank in
                                                Text(bank.rawValue).tag(bank)
                                            }
                                        }
                                        .labelsHidden()
                                    }

                                    customTextField(title: "Sender", text: $sender, field: .sender)
                                    customTextField(title: "Receiver", text: $receiver, field: .receiver)
                                    customTextField(title: "Reference ID", text: $refId, field: .refId)
                                }
                                .padding(.top, 8)
                            },
                            label: {
                                Text("More Details")
                                    .font(.headline)
                                    .foregroundColor(theme.textPrimary)
                            }
                        )
                        .padding()
                        .background(theme.cardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)

                        // Bottom Spacer
                        Spacer(minLength: 50)
                    }
                }
                .background(theme.background)
                .navigationTitle(transactionToEdit == nil ? "New Transaction" : "Edit Transaction")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button(transactionToEdit == nil ? "Add" : "Save") {
                            saveTransaction()
                        }
                        .disabled(amount.isEmpty)
                        .fontWeight(.bold)
                    }

                    ToolbarItem(placement: .keyboard) {
                        HStack {
                            Spacer()
                            Button("Done") { focusedField = nil }
                        }
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
                if #available(iOS 16.4, *) {
                    DatePicker("Select Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.graphical)
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.visible)
                        .padding()
                } else {
                    DatePicker("Select Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.graphical)
                        .padding()
                }
            }

            // ✅ Overlay in the SAME hierarchy (smooth matchedGeometryEffect)
            if isShowSlip {
                fullScreenSlipOverlay
                    .transition(.opacity)
                    .zIndex(999)
            }
        }
    }

    // MARK: - Custom Views

    private func categoryButton(icon: String, color: Color, name: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? color : theme.cardBackground.opacity(0.7))
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .white : color)
                }

                if isCategoryExpanded {
                    Text(name)
                        .font(.caption)
                        .foregroundColor(isSelected ? theme.textPrimary : theme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
    }

    private func customTextField(title: String, text: Binding<String>, field: Field) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(theme.textSecondary)
            TextField(title, text: text)
                .textFieldStyle(.plain)
                .focused($focusedField, equals: field)
                .padding(10)
                .background(theme.cardBackground.opacity(0.7))
                .cornerRadius(8)
        }
    }

    // MARK: - Sections

    private var slipImageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Slip Image")
                .font(.headline)
                .foregroundColor(theme.textSecondary)

            if let loadedImage = loadedImage {
                if !isShowSlip {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(theme.cardBackground)
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
                .background(theme.cardBackground)
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

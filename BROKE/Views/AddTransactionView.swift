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
    @State private var subTransactions: [SubTransaction] = []

    // For custom date picker
    @State private var showDatePicker: Bool = false

    // For collapsing details
    @State private var showMoreDetails: Bool = false

    @State private var newSubAmount: String = ""
    @State private var newSubCategory: ExpenseCategory = .others

    @State private var subTransactionError: String? = nil

    @State private var isCategoryExpanded: Bool = false

    @FocusState private var focusedField: Field?

    @Namespace private var smoothImage

    enum Field {
        case amount
        case description
        case sender
        case receiver
        case refId
        case subAmount
    }

    init(slipData: SlipData? = nil, transactionToEdit: Transaction? = nil) {
        self.slipData = slipData
        self.transactionToEdit = transactionToEdit
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            NavigationView {
                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Type & Amount

                        VStack(spacing: 20) {
                            Picker("Type", selection: $type) {
                                Text("Expense").tag(TransactionType.expense)
                                Text("Income").tag(TransactionType.income)
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
                                        .foregroundColor(.blue)
                                    Text(dateFormatted)
                                        .foregroundColor(.primary)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(uiColor: .tertiarySystemGroupedBackground))
                                .cornerRadius(10)
                            }
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(20)
                        .padding(.horizontal)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)

                        // MARK: - Category

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Category")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button(action: {
                                    withAnimation(.spring()) {
                                        isCategoryExpanded.toggle()
                                    }
                                }) {
                                    Image(systemName: isCategoryExpanded ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                        .padding(8)
                                        .background(Color(uiColor: .tertiarySystemGroupedBackground))
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
                                    .background(Color(uiColor: .secondarySystemGroupedBackground))
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
                                    .background(Color(uiColor: .secondarySystemGroupedBackground))
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
                                    .background(Color(uiColor: .secondarySystemGroupedBackground))
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
                                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                                    .cornerRadius(20)
                                    .padding(.horizontal)
                                }
                            }
                        }

                        // MARK: - Note

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Note")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)

                            HStack {
                                Image(systemName: "square.and.pencil")
                                    .foregroundColor(.secondary)
                                TextField("Add a description...", text: $description)
                                    .focused($focusedField, equals: .description)
                            }
                            .padding()
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
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
                                    .foregroundColor(.primary)
                            }
                        )
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)

                        // Bottom Spacer
                        Spacer(minLength: 50)
                    }
                }
                .background(Color(uiColor: .systemGroupedBackground))
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
                        .fill(isSelected ? color : Color(uiColor: .tertiarySystemGroupedBackground))
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .white : color)
                }

                if isCategoryExpanded {
                    Text(name)
                        .font(.caption)
                        .foregroundColor(isSelected ? .primary : .secondary)
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
                .foregroundColor(.secondary)
            TextField(title, text: text)
                .focused($focusedField, equals: field)
                .padding(10)
                .background(Color(uiColor: .tertiarySystemGroupedBackground))
                .cornerRadius(8)
        }
    }

    // MARK: - Sections

    private var slipImageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Slip Image")
                .font(.headline)
                .foregroundColor(.secondary)

            if let loadedImage = loadedImage {
                if !isShowSlip {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
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
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(16)
            }
        }
    }

    private var subTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sub Transactions")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach($subTransactions) { $sub in
                    HStack {
                        // Amount Field
                        TextField("Amount", value: $sub.amount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color(uiColor: .tertiarySystemGroupedBackground))
                            .cornerRadius(6)
                            .frame(width: 100)

                        Spacer()

                        // Category Picker
                        Picker("Category", selection: $sub.categoryId) {
                            ForEach(ExpenseCategory.allCases) { category in
                                HStack {
                                    Image(systemName: category.icon)
                                        .foregroundColor(category.color)
                                    Text(category.displayName)
                                }
                                .tag(category)
                            }
                        }
                        .labelsHidden()
                        .fixedSize()

                        // Delete Button
                        Button(action: {
                            if let index = subTransactions.firstIndex(where: { $0.id == sub.id }) {
                                subTransactions.remove(at: index)
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                                .font(.title3)
                        }
                        .padding(.leading, 8)
                    }
                    .padding()

                    if sub.id != subTransactions.last?.id {
                        Divider().padding(.leading)
                    }
                }

                if !subTransactions.isEmpty {
                    Divider()
                }

                // Add New Sub Transaction Row
                HStack {
                    TextField("Amount", text: $newSubAmount)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .subAmount)
                        .padding(8)
                        .background(Color(uiColor: .tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(subTransactionError != nil ? Color.red : Color.clear, lineWidth: 1)
                        )
                        .onChange(of: newSubAmount) { _ in
                            subTransactionError = nil
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()

                    Picker("Category", selection: $newSubCategory) {
                        ForEach(ExpenseCategory.allCases) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(category.color)
                                Text(category.displayName)
                            }
                            .tag(category)
                        }
                    }
                    .labelsHidden()

                    Button(action: addSubTransaction) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .disabled(newSubAmount.isEmpty)
                }
                .padding()

                if let error = subTransactionError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(16)
            .padding()
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

    private func addSubTransaction() {
        guard let amountValue = Double(newSubAmount) else { return }

        let mainAmount = Double(amount) ?? 0.0
        let currentSubTotal = subTransactions.reduce(0) { $0 + $1.amount }

        if currentSubTotal + amountValue > mainAmount {
            subTransactionError = "Exceeds total amount"
            return
        }

        let newSub = SubTransaction(amount: amountValue, categoryId: newSubCategory)
        subTransactions.append(newSub)

        newSubAmount = ""
        newSubCategory = .others
        subTransactionError = nil
    }

    private func populateFromTransaction(_ transaction: Transaction) {
        amount = String(transaction.amount)
        description = transaction.description
        date = transaction.date
        type = transaction.type
        if let category = transaction.categoryId { selectedCategory = category }
        if let incomeCategory = transaction.incomeCategoryId { selectedIncomeCategory = incomeCategory }
        if let bank = transaction.bank { selectedBank = bank }
        sender = transaction.sender ?? ""
        receiver = transaction.receiver ?? ""
        refId = transaction.refId ?? ""
        subTransactions = transaction.subTransactions ?? []
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

    private func saveTransaction() {
        guard let amountValue = Double(amount) else { return }

        if var transaction = transactionToEdit {
            transaction.amount = amountValue
            transaction.description = description.isEmpty ? (type == .income ? "Income" : "Expense") : description
            transaction.date = date
            transaction.type = type
            transaction.sender = sender.isEmpty ? nil : sender
            transaction.receiver = receiver.isEmpty ? nil : receiver
            transaction.categoryId = type == .expense ? selectedCategory : nil
            transaction.incomeCategoryId = type == .income ? selectedIncomeCategory : nil
            transaction.bank = selectedBank == .unknown ? nil : selectedBank
            transaction.refId = refId.isEmpty ? nil : refId
            transaction.subTransactions = subTransactions.isEmpty ? nil : subTransactions

            transactionStore.updateTransaction(transaction)
        } else {
            let transaction = Transaction(
                refId: refId.isEmpty ? nil : refId,
                amount: amountValue,
                description: description.isEmpty ? (type == .income ? "Income" : "Expense") : description,
                date: date,
                sender: sender.isEmpty ? nil : sender,
                receiver: receiver.isEmpty ? nil : receiver,
                type: type,
                source: slipData != nil ? .scan : .manual,
                categoryId: type == .expense ? selectedCategory : nil,
                incomeCategoryId: type == .income ? selectedIncomeCategory : nil,
                bank: selectedBank == .unknown ? nil : selectedBank,
                imagePath: nil,
                subTransactions: subTransactions.isEmpty ? nil : subTransactions
            )
            transactionStore.addTransaction(transaction)
        }

        dismiss()
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

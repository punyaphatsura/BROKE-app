//
//  AddTransactionView.swift
//  Meow-Jod-Clone-App
//
//  Created by Punyaphat Surakiatkamjorn on 20/4/2568 BE.
//

import SwiftUI
import Photos

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var transactionStore: TransactionStore
    
    let slipData: SlipData?
    let transactionToEdit: Transaction?
    
    @State private var amount: String = ""
    @State private var description: String = ""
    @State private var date: Date = Date()
    @State private var type: TransactionType = .expense
    @State private var selectedCategory: ExpenseCategory = .others
    @State private var selectedIncomeCategory: IncomeCategory = .other
    @State private var selectedBank: Bank = .unknown
    @State private var sender: String = ""
    @State private var receiver: String = ""
    @State private var refId: String = ""
    @State private var loadedImage: UIImage? = nil
    @State private var isShowSlip: Bool = false
    
    @Namespace private var smoothImage
    
    init(slipData: SlipData? = nil, transactionToEdit: Transaction? = nil) {
        self.slipData = slipData
        self.transactionToEdit = transactionToEdit
    }
    
    var body: some View {
        NavigationView {
            Form {
                detailsSection
                
                categorySection
                
                bankDetailsSection
                
                slipImageSection
                
                saveButtonSection
            }
            .navigationTitle(transactionToEdit == nil ? "Add Transaction" : "Edit Transaction")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
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
            .fullScreenCover(isPresented: $isShowSlip) {
                fullScreenSlipView
            }
        }
    }
    
    // MARK: - Sections
    
    private var detailsSection: some View {
        Section(header: Text("Transaction Details")) {
            Picker("Type", selection: $type) {
                Text("Income").tag(TransactionType.income)
                Text("Expense").tag(TransactionType.expense)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            TextField("Amount", text: $amount)
                .keyboardType(.decimalPad)
            
            TextField("Description", text: $description)
            
            DatePicker("Date", selection: $date, displayedComponents: .date)
        }
    }
    
    private var categorySection: some View {
        Section(header: Text("Category")) {
            if type == .expense {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(ExpenseCategory.allCases) { category in
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(category.color)
                            Text(category.displayName)
                        }
                        .tag(category)
                    }
                }
            } else {
                Picker("Category", selection: $selectedIncomeCategory) {
                    ForEach(IncomeCategory.allCases) { category in
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(category.color)
                            Text(category.displayName)
                        }
                        .tag(category)
                    }
                }
            }
        }
    }
    
    private var bankDetailsSection: some View {
        Section(header: Text("Bank Details")) {
            Picker("Bank", selection: $selectedBank) {
                ForEach(Bank.allCases) { bank in
                    HStack {
                        Text(bank.rawValue)
                    }
                    .tag(bank)
                }
            }
            
            TextField("Sender", text: $sender)
            TextField("Receiver", text: $receiver)
            TextField("Reference ID", text: $refId)
        }
    }
    
    private var slipImageSection: some View {
        Group {
            if let loadedImage = loadedImage {
                if !isShowSlip {
                    HStack {
                        Spacer()
                        Image(uiImage: loadedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .matchedGeometryEffect(
                                id: "slipImage",
                                in: smoothImage
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.35,
                                                      dampingFraction: 0.85)) {
                                    isShowSlip = true
                                }
                            }
                            .zIndex(2)
                        Spacer()
                    }
                }
            } else if transactionToEdit?.imagePath != nil {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
    }
    
    private var saveButtonSection: some View {
        Section {
            Button(action: saveTransaction) {
                Text(transactionToEdit == nil ? "Add Transaction" : "Save Changes")
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
            }
            .listRowBackground(Color.blue)
            .disabled(amount.isEmpty)
        }
    }
    
    private var fullScreenSlipView: some View {
        Group {
            if let loadedImage = loadedImage {
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                isShowSlip = false
                            }
                        }
                    
                    VStack {
                        HStack {
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    isShowSlip = false
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.primary.opacity(0.8))
                                    .padding(8)
                            }
                            .padding(.top, 50)
                            .padding(.trailing, 20)
                            Spacer()
                        }
                        Spacer()
                    }
                    .zIndex(2)
                    
                    ZoomableScrollView {
                        Image(uiImage: loadedImage)
                            .resizable()
                            .scaledToFit()
                            .matchedGeometryEffect(id: "slipImage", in: smoothImage)
                    }
                    .padding()
                }
                .background(BackgroundClearView())
                .opacity(isShowSlip ? 1 : 0)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func populateFromTransaction(_ transaction: Transaction) {
        amount = String(transaction.amount)
        description = transaction.description
        date = transaction.date
        type = transaction.type
        if let category = transaction.categoryId {
            selectedCategory = category
        }
        if let incomeCategory = transaction.incomeCategoryId {
            selectedIncomeCategory = incomeCategory
        }
        if let bank = transaction.bank {
            selectedBank = bank
        }
        sender = transaction.sender ?? ""
        receiver = transaction.receiver ?? ""
        refId = transaction.refId ?? ""
    }
    
    private func populateFromSlipData() {
        guard let slipData = slipData else { return }
        
        if let parsedAmount = slipData.parsedAmount {
            amount = String(parsedAmount)
        }
        
        if let parsedDate = slipData.parsedDate {
            date = parsedDate
        }
        
        if let detectedBank = slipData.detectedBank {
            selectedBank = detectedBank
        }
        
        sender = slipData.sender
        receiver = slipData.receiver
        refId = slipData.refId
        description = "Transfer to \(slipData.receiver)"
        type = .expense // Assuming slips are mostly expenses
    }
    
    private func loadImage(from localIdentifier: String?) {
        guard let localIdentifier = localIdentifier else { return }
        
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        guard let asset = assets.firstObject else { return }
        
        let manager = PHCachingImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        
        manager.requestImage(for: asset, targetSize: CGSize(width: 500, height: 500), contentMode: .aspectFit, options: options) { image, _ in
            DispatchQueue.main.async {
                self.loadedImage = image
            }
        }
    }
    
    private func saveTransaction() {
        guard let amountValue = Double(amount) else { return }
        
        if var transaction = transactionToEdit {
            // Update existing
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
            
            transactionStore.updateTransaction(transaction)
        } else {
            // Create new
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
                imagePath: nil // Assuming we don't save new image path here for now unless it was passed
            )
            transactionStore.addTransaction(transaction)
        }
        
        dismiss()
    }
    
    // Wrapper for Zoomable ScrollView
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
            
            let hostingController = UIHostingController(rootView: content)
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            hostingController.view.backgroundColor = .clear
            
            scrollView.addSubview(hostingController.view)
            
            NSLayoutConstraint.activate([
                hostingController.view.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
                hostingController.view.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
                hostingController.view.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
                hostingController.view.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor)
            ])
            
            return scrollView
        }
        
        func updateUIView(_ uiView: UIScrollView, context: Context) {}
        
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
    
    // Helper for transparent fullScreenCover background
    struct BackgroundClearView: UIViewRepresentable {
        func makeUIView(context: Context) -> UIView {
            let view = UIView()
            DispatchQueue.main.async {
                view.superview?.superview?.backgroundColor = .clear
            }
            return view
        }
        
        func updateUIView(_ uiView: UIView, context: Context) {}
    }
}

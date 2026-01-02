# BROKE

A personal expense tracking iOS application built with SwiftUI, designed to simplify financial management through manual entry and automated bank slip scanning. This project mimics the core functionality of the popular "Meow Jod" application.

## Features

- **Expense & Income Tracking**: 
  - Manually add daily transactions with detailed categories.
  - Visualize income vs. expenses with a monthly dashboard.
  - Navigate through transaction history by month/year.

- **Auto-Fetch Bank Slips**:
  - Seamlessly integrates with your Photo Library to find bank transfer slips.
  - Automatically monitors albums from major Thai banking apps:
    - **SCB Easy**
    - **MAKE by KBank**
    - **K PLUS**
    - **Krungthai NEXT**
    - **UOB TMRW**
    - **Bualuang mBanking**
  - Smart filtering to process only new slips based on the app's installation date.

- **Smart Slip Scanning**:
  - **Hybrid Extraction Engine**:
    - **QR Code**: Validates and parses Thai banking QR codes using the **SlipOK API** for 100% accuracy.
    - **AI / OCR**: Fallback to **Google Gemini 2.5 Flash** (via Firebase Vertex AI) for slips without QR codes or when SlipOK limit is reached.
  - Automatically extracts: Amount, Date, Sender, Receiver, Bank, and Reference ID.
  - **Intelligent Categorization**: Auto-suggests expense categories (Food, Transport, Shopping, etc.) based on the receiver/payee name.

- **Data Management**:
  - **CSV Export**: Export your entire transaction history to CSV for external analysis.
  - **CSV Import**: Import existing data (supports specific Thai formats).
  - **Local Storage**: Data is persisted securely on-device using `UserDefaults`.

## Tech Stack

- **Language**: Swift
- **UI Framework**: SwiftUI
- **Architecture**: MVVM (Model-View-ViewModel)
- **AI & Machine Learning**:
  - **Firebase Vertex AI (Gemini 2.5 Flash)**: Advanced text extraction and image analysis.
  - **Apple Vision Framework**: Native QR code detection.
- **Backend Services**:
  - **SlipOK API**: For validating Thai banking slips.
  - **Firebase**: App configuration and AI model hosting.

## Project Structure

```
BROKE/
├── Models/              # Data models (Transaction, SlipData, Bank, Categories)
├── Views/               # SwiftUI Views (Home, TransactionList, Settings)
├── ViewModels/          # Business logic and state management
├── Services/            # Core services
│   ├── SlipExtractionService.swift  # Logic for SlipOK + Gemini integration
│   ├── PhotoService.swift           # Photo Library monitoring
│   ├── CSVExportService.swift       # Data export
│   └── CSVImportService.swift       # Data import
├── Utils/               # Helpers, Extensions, and Secrets
└── Resources/           # Assets and Localization
```

## Setup & Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   ```

2. **Open the project**:
   Open `BROKE.xcodeproj` in Xcode.

3. **Configure API Keys**:
   - Create a `Secrets.swift` file in `BROKE/Utils/` (see `Secrets.example.swift`).
   - You need a valid **SlipOK** API Key and Branch ID.
   
   *Example `Secrets.swift`:*
   ```swift
   struct Secrets {
       static let slipOKBranch = "YOUR_SLIPOK_BRANCH_ID"
       static let slipOKAuthorization = "YOUR_SLIPOK_API_KEY"
   }
   ```

4. **Firebase Setup**:
   - Create a Firebase project and enable **Vertex AI in Firebase**.
   - Download `GoogleService-Info.plist` and add it to the project root.

5. **Run the App**:
   - Select an iOS Simulator or physical device.
   - Run (Cmd+R).
   - **Note**: Photo Library access is required for the auto-fetch feature to work.

## Requirements

- iOS 16.0+
- Xcode 14.0+
- Swift 5.7+

## Acknowledgements

- Inspired by the original "Meow Jod" application.
- Powered by [SlipOK](https://slipok.com/) and [Google Gemini](https://deepmind.google/technologies/gemini/).

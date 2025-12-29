# BROKE

A personal expense tracking iOS application built with SwiftUI, designed to simplify financial management through manual entry and automated bank slip scanning. This project mimics the core functionality of the popular "Meow Jod" application.

## Features

- **Expense & Income Tracking**: Manually add daily transactions with detailed categories.
- **Auto-Fetch Bank Slips**:
  - Seamlessly integrates with your Photo Library to find bank transfer slips.
  - Automatically monitors albums from major Thai banking apps: **SCB Easy, MAKE by KBank, K PLUS, Krungthai NEXT**.
  - Filters for recent slips (configurable date) to streamline processing.
- **Smart Slip Scanning**:
  - Automatically extracts transaction details (Amount, Date, Sender, Receiver, Bank).
  - Hybrid extraction engine using **SlipOK API** (QR Code) and **Google Gemini AI** (OCR/Text Analysis).
  - Intelligent category suggestions based on the receiver/payee name.
- **Dashboard**: View monthly transaction summaries and navigate between months.
- **Data Persistence**: Local storage of transactions using UserDefaults.
- **Privacy Focused**: Processes images locally or via secure API calls; user data remains on device.

## Tech Stack

- **Language**: Swift
- **UI Framework**: SwiftUI
- **Architecture**: MVVM (Model-View-ViewModel)
- **AI & Machine Learning**:
  - **Firebase Vertex AI (Gemini 2.5 Flash model)**: Advanced text extraction from slip images.
  - **Apple Vision Framework**: QR code detection.
- **External Services**:
  - **SlipOK API**: For validating and parsing Thai banking QR codes.
  - **Firebase**: App configuration and AI backend.

## Project Structure

```
BROKE/
├── Models/              # Data models (Transaction, SlipData, Bank, Categories)
├── Views/               # SwiftUI Views (Home, TransactionList, Settings)
├── ViewModels/          # Business logic and state management
├── Services/            # API integration (SlipExtractionService, PhotoService)
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
   - This project requires a `Secrets.swift` file in `BROKE/Utils/` containing your API keys.
   - You will also need a valid `GoogleService-Info.plist` for Firebase integration.

   *Example `Secrets.swift`:*
   ```swift
   struct Secrets {
       static let slipOKBranch = "YOUR_SLIPOK_BRANCH_ID"
       static let slipOKAuthorization = "YOUR_SLIPOK_API_KEY"
   }
   ```

4. **Run the App**:
   Select an iOS Simulator or connected device and run (Cmd+R).

## Requirements

- iOS 16.0+
- Xcode 14.0+
- Swift 5.7+

## Acknowledgements

- Inspired by the original Meow Jod application concepts.
- Powered by [SlipOK](https://slipok.com/) and [Google Gemini](https://deepmind.google/technologies/gemini/).

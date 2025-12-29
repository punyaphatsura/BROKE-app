//
//  SettingsView.swift
//  BROKE
//
//  Created by Punyaphat Surakiatkamjorn on 20/4/2568 BE.
//

import PhotosUI
import SwiftUI

struct SettingsView: View {
    @AppStorage("lastScannedDate") private var lastScannedDate: Date?
    @State private var isRequestingAccess = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Photo Library Access")) {
                    Button("Request Photo Access") {
                        isRequestingAccess = true
                    }
                    .sheet(isPresented: $isRequestingAccess) {
                        RequestPhotoAccessView()
                    }
                }

                Section(header: Text("Scanning Information")) {
                    if let lastScanned = lastScannedDate {
                        HStack {
                            Text("Last Scan")
                            Spacer()
                            Text(lastScanned, style: .date)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("No scans performed yet")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

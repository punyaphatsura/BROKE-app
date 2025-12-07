//
//  SettingsView.swift
//  Meow-Jod-Clone-App
//
//  Created by Punyaphat Surakiatkamjorn on 20/4/2568 BE.
//

import SwiftUI
import PhotosUI

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
                
                Section(header: Text("About")) {
                    HStack {
                        Text("App Name")
                        Spacer()
                        Text("BROKE — Bank Slip Recorder, Organizer & Knowledge Extractor")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Developer")
                        Spacer()
                        Text("Your Name")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

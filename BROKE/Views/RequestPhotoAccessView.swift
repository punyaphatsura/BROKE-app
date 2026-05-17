//
//  RequestPhotoAccessView.swift
//  BROKE
//
//  Created by Punyaphat Surakiatkamjorn on 20/4/2568 BE.
//

import SwiftUI
import PhotosUI

struct RequestPhotoAccessView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var theme: ThemeManager
    @State private var accessStatus: PHAuthorizationStatus = .notDetermined
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 72))
                .foregroundColor(theme.primary)
            
            Text("Photo Library Access")
                .font(.title)
                .bold()
            
            Text("This app needs access to your photo library to scan bank slips and extract transaction data.")
                .multilineTextAlignment(.center)
                .padding()
            
            Button(action: {
                requestPhotoLibraryAccess()
            }) {
                Text(accessStatus == .authorized ? "Access Granted" : "Allow Access")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(accessStatus == .authorized ? theme.income : theme.primary)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(accessStatus == .authorized)
            .padding(.horizontal)
            
            Button("Close") {
                dismiss()
            }
            .padding()
        }
        .padding()
        .background(theme.background.ignoresSafeArea())
        .onAppear {
            checkPhotoLibraryAccess()
        }
    }
    
    private func checkPhotoLibraryAccess() {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        accessStatus = currentStatus
    }
    
    private func requestPhotoLibraryAccess() {
        if accessStatus == .authorized {
            return
        }

        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                self.accessStatus = status
            }
        }
    }
}

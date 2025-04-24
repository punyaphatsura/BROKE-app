//
//  RequestPhotoAccessView.swift
//  Meow-Jod-Clone-App
//
//  Created by Punyaphat Surakiatkamjorn on 20/4/2568 BE.
//

import SwiftUI
import PhotosUI

struct RequestPhotoAccessView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var accessStatus: PHAuthorizationStatus = .notDetermined
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 72))
                .foregroundColor(.blue)
            
            Text("Photo Library Access")
                .font(.title)
                .bold()
            
            Text("This app needs access to your photo library to scan bank slips and extract transaction data.")
                .multilineTextAlignment(.center)
                .padding()
            
            Button(action: {
                print("[DEBUG] Allow Access button tapped")
                requestPhotoLibraryAccess()
            }) {
                Text(accessStatus == .authorized ? "Access Granted" : "Allow Access")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(accessStatus == .authorized ? Color.green : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(accessStatus == .authorized)
            .padding(.horizontal)
            
            Button("Close") {
                print("[DEBUG] Close button tapped")
                dismiss()
            }
            .padding()
        }
        .padding()
        .onAppear {
            print("[DEBUG] View appeared — checking photo access status")
            checkPhotoLibraryAccess()
        }
    }
    
    private func checkPhotoLibraryAccess() {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        print("[DEBUG] Current access status: \(currentStatus.rawValue)")
        accessStatus = currentStatus
    }
    
    private func requestPhotoLibraryAccess() {
        if accessStatus == .authorized {
            print("[DEBUG] Access is already granted — nothing to do")
            return
        }
        print("[DEBUG] Requesting photo access...")

        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            print("[DEBUG] Photo access status received: \(status.rawValue)")
            DispatchQueue.main.async {
                self.accessStatus = status
                if status == .authorized {
                    print("[DEBUG] Access granted ✅")
                } else {
                    print("[DEBUG] Access denied or limited ❌")
                }
            }
        }
    }
}

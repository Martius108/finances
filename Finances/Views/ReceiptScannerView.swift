//
//  ReceiptScannerView.swift
//  Finances
//
//  Created by Martin Lanius on 29.05.25.
//

import SwiftUI

struct ReceiptScannerView: View {
    @Environment(\.dismiss) private var dismiss
    var onTotalDetected: ((Double) -> Void)?
    @StateObject private var viewModel = ReceiptScannerViewModel()
    @State private var showImagePicker = false

    var body: some View {
        VStack(spacing: 50) {
            if let image = viewModel.image {
                Spacer()
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            } else {
                Spacer()
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .overlay(Text("No Image Selected"))
            }

            HStack {
                Spacer()
                Button("Take a Photo") {
                    viewModel.source = .camera
                    showImagePicker = true
                }
                Spacer()
                Button("Picture Library") {
                    viewModel.source = .library
                    showImagePicker = true
                }
                Spacer()
            }

            if viewModel.isProcessing {
                ProgressView("Getting amount ...")
            } else if let total = viewModel.grossTotal {
                Text(String(format: "Total: %.2f €", total))
                    .font(.title2)
                    .bold()
                    .onAppear {
                        onTotalDetected?(total)
                        dismiss()
                    }
            }
            Spacer()
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: viewModel.source.uiImagePickerSource) { image in
                viewModel.process(image: image)
            }
        }
    }
}

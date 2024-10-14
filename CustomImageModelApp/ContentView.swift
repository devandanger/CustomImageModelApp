//
//  ContentView.swift
//  CustomImageModelApp
//
//  Created by Evan Anger on 10/14/24.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
  @StateObject var viewModel: ImageViewModel
  
    var body: some View {
        VStack {
            if let image = viewModel.photoPickerViewModel.selectedPhoto?.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                
                HStack {
                    Spacer()
                    Button("Run model request") {
                        viewModel.runInference()
                    }
                    .padding()
                    Spacer()
                }
                if let identifier = viewModel.identifier {
                    Text("Model request complete: \(identifier)")
                        .foregroundColor(.green)
                        .padding()
                }
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            } else {
                Text("No image available")
            }
        }
    }
}

#Preview {
    NavigationView {
        ContentView(viewModel: .init(photoPickerViewModel: PhotoPickerViewModel()))
    }
}

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
    @State var showCamera: Bool = false
    
    init() {
        _viewModel = StateObject(wrappedValue:
                                    ImageViewModel(photoPickerViewModel: PhotoPickerViewModel()))
    }
  
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
            Spacer()
            HStack {
                PhotosPicker(
                    selection: $viewModel.photoPickerViewModel.imageSelection,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .imageScale(.large)
                        Text("From Library")
                    }
                }
                Button {
                    showCamera = true
                } label: {
                    HStack {
                        Image(systemName: "camera")
                            .imageScale(.large)
                        Text("From Camera")
                    }
                }
                .sheet(isPresented: $showCamera) {
                    CameraPickerView { image in
                        viewModel.photoPickerViewModel.selectedPhoto = Photo(image: image)
                        print("Receive image")
                    }
                }
            }
        }
        .onChange(of: viewModel.photoPickerViewModel.selectedPhoto) { _, newValue in
            print("Received new value")
        }
        
    }
}

#Preview {
    NavigationView {
        ContentView()
    }
}

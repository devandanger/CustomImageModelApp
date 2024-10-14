//
//  CustomImageModelAppApp.swift
//  CustomImageModelApp
//
//  Created by Evan Anger on 10/14/24.
//

import SwiftUI
import PhotosUI

@main
struct CustomImageModelApp: App {
    @StateObject private var photoPickerViewModel = PhotoPickerViewModel()
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView(viewModel: .init(photoPickerViewModel: photoPickerViewModel))
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            PhotosPicker(
                                selection: $photoPickerViewModel.imageSelection,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .imageScale(.large)
                            }
                        }
                    }
            }
        }
    }
}

//
//  OpenAIProvider.swift
//  CustomImageModelApp
//
//  Created by Evan Anger on 5/1/25.
//

import Foundation
import Combine

class OpenAIProvider: ObservableObject {
    @Published var prompt: String = "Hello world"
    @Published var results: String = "Hello world"
    
    func callWithResult(_ input: String) {
        sendPromptToOpenAI(prompt: (prompt + "\n" + input)) { results in
            DispatchQueue.main.async {   
                self.results = results ?? "No results"
            }
        }
    }
    
}

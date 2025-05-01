//
//  OpenAI.swift
//  CustomImageModelApp
//
//  Created by Evan Anger on 5/1/25.
//

import Foundation

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let temperature: Double
}

struct OpenAIResponse: Codable {
    struct Choice: Codable {
        let message: OpenAIMessage
    }
    let choices: [Choice]
}

func sendPromptToOpenAI(prompt: String, completion: @escaping (String?) -> Void) {
    let url = URL(string: "https://api.openai.com/v1/chat/completions")!
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("Bearer YOUR_API_KEY", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = OpenAIRequest(
        model: "gpt-3.5-turbo",
        messages: [OpenAIMessage(role: "user", content: prompt)],
        temperature: 0.7
    )

    request.httpBody = try? JSONEncoder().encode(body)

    URLSession.shared.dataTask(with: request) { data, response, error in
        guard
            let data = data,
            let decoded = try? JSONDecoder().decode(OpenAIResponse.self, from: data),
            let reply = decoded.choices.first?.message.content
        else {
            print("Error: \(error?.localizedDescription ?? "Unknown error")")
            completion(nil)
            return
        }

        completion(reply)
    }.resume()
}

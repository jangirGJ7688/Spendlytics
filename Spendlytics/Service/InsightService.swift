//
//  InsightService.swift
//  Spendlytics
//
//  Created by Ganpat Jangir on 14/03/26.
//

import Foundation

class InsightService {
    
    private let apiKey: String = "AIzaSyC98G5VLl9I8emFl4DhhLVBT6E5tQe3W3w"
    
    func generateInsights(prompt: String) async throws -> [String] {
        
        let url = URL(string:
                        "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-lite-latest:generateContent?key=\(apiKey)")!
        
        let body = InsightRequest(
            contents: [
                Content(parts: [Part(text: prompt)])
            ], generationConfig: GenerationConfig(
                temperature: 0.2,
                maxOutputTokens: 60
            )
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check HTTP response
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            
            let errorResponse = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "GeminiAPI", code: 0, userInfo: [
                NSLocalizedDescriptionKey: errorResponse
            ])
        }
        
        let decoded = try JSONDecoder().decode(InsightResponse.self, from: data)
        
        let text = decoded.candidates.first?.content.parts.first?.text ?? ""
        
        return extractInsights(from: text, limit: 2)
    }
    
    func extractInsights(from text: String, limit: Int = 2) -> [String] {
        
        text
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .map {
                $0.replacingOccurrences(of: #"^\d+\.\s"#,
                                        with: "",
                                        options: .regularExpression)
            }
            .filter { !$0.isEmpty }
            .prefix(limit)
            .map { $0 }
    }
}

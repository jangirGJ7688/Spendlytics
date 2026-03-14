//
//  InsightModel.swift
//  Spendlytics
//
//  Created by Ganpat Jangir on 14/03/26.
//

import Foundation

struct InsightRequest: Codable {
    let contents: [Content]
    let generationConfig: GenerationConfig
}

struct InsightResponse: Codable {
    let candidates: [Candidate]
}

struct Candidate: Codable {
    let content: Content
}


struct Content: Codable {
    let parts: [Part]
}

struct Part: Codable {
    let text: String
}

struct GenerationConfig: Codable {
    let temperature: Double
    let maxOutputTokens: Int
}

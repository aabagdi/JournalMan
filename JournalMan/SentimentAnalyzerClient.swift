//
//  SentimentAnalyzerClient.swift
//  JournalMan
//
//  Created by Aadit Bagdi on 12/28/25.
//

import Foundation
import Dependencies
import DependenciesMacros
import NaturalLanguage

@DependencyClient
struct SentimentAnalyzerClient {
  var predict: @Sendable (_ text: String?) async throws -> (String?)
}

extension SentimentAnalyzerClient: DependencyKey {
  static let liveValue: Self = {
    // Simplified to 5 sentiment categories that map to the 5 emotions
    let sentimentEmojis = [
      "🤬",
      "😔",
      "🙂",
      "😊",
      "😍",
    ]
    
    nonisolated(unsafe) let tagger = NLTagger(tagSchemes: [.tokenType, .sentimentScore])
    
    return Self { text in
      guard let text, !text.isEmpty else {
        return "😶"
      }
      
      tagger.string = text
      
      let (sentiment, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
      
      let sentimentValue = (sentiment?.rawValue as? NSString)?.doubleValue ?? 0.0
      
      let emojiIndex: Int
      if sentimentValue <= -0.6 {
        emojiIndex = 0
      } else if sentimentValue <= -0.2 {
        emojiIndex = 1
      } else if sentimentValue <= 0.2 {
        emojiIndex = 2
      } else if sentimentValue <= 0.6 {
        emojiIndex = 3
      } else {
        emojiIndex = 4
      }
      
      return sentimentEmojis[emojiIndex]
    }
  }()
  
  static let testValue = Self { _ in
    return "🙂"
  }
}

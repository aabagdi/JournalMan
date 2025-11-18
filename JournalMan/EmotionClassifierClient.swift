//
//  EmotionClassifierClient.swift
//  JournalMan
//
//  Created by Aadit Bagdi on 8/23/25.
//

import Foundation
import Dependencies
import DependenciesMacros
import CoreML

@DependencyClient
struct EmotionClassifierClient {
  var predict: @Sendable (EmotionClassifierInput) async throws -> (EmotionClassifierOutput)
}

extension EmotionClassifierClient: DependencyKey {
  static let liveValue: Self = {
    nonisolated(unsafe) let model = try! EmotionClassifier(configuration: .init())
    
    return Self { input in
      return try model.prediction(input: input)
    }
  }()
  
  static let testValue = Self { _ in
    EmotionClassifierOutput(
      target: "positive",
      targetProbability: [
        "positive": 0.7,
        "calm": 0.2,
        "sad": 0.1
      ]
    )
  }
}

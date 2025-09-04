//
//  TopicClassifierClient.swift
//  JournalMan
//
//  Created by Aadit Bagdi on 8/27/25.
//

import Foundation
import Dependencies
import DependenciesMacros
import CoreML

@DependencyClient
struct TopicClassifierClient {
  var predict: @Sendable (TopicClassifierInput) async throws -> (TopicClassifierOutput)
}

extension TopicClassifierClient: DependencyKey {
  static let liveValue: Self = {
    let model = try! TopicClassifier(configuration: .init())
    return Self { input in
      try await model.prediction(input: input)
    }
  }()
  
  static let testValue = Self { _ in
    let features = try MLDictionaryFeatureProvider(dictionary: ["family": 0.9, "relationships": 0.1])
    return await TopicClassifierOutput(features: features)
  }
}

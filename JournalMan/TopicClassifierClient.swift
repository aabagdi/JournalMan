//
//  TopicClassifierClient.swift
//  JournalMan
//
//  Created by Aadit Bagdi on 8/27/25.
//

import Foundation
import NaturalLanguage
import Dependencies
import DependenciesMacros
import CoreML

@DependencyClient
struct TopicClassifierClient {
  var predict: @Sendable (String) async throws -> (String?)
}

extension TopicClassifierClient: DependencyKey {
  static let liveValue: Self = {
    let mlModel = try! TopicClassifier(configuration: MLModelConfiguration()).model
    let nlModel = try! UncheckedSendable(NLModel(mlModel: mlModel))
    
    return Self { input in
      let unwrappedModel = nlModel.wrappedValue
      let output = unwrappedModel.predictedLabel(for: input)
      return output
    }
  }()
  
  static let testValue = Self { _ in
    return "test"
  }
}

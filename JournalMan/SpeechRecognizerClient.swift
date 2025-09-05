//
//  SpeechRecognizerClient.swift
//  JournalMan
//
//  Created by Aadit Bagdi on 9/1/25.
//

import Foundation
import AVFoundation
@preconcurrency import Speech
import Dependencies
import DependenciesMacros

@DependencyClient
struct SpeechRecognizerClient {
  var requestAuthorization: @Sendable () async -> SFSpeechRecognizerAuthorizationStatus = { .notDetermined }
  var transcribeFile: @Sendable (_ url: URL) async throws -> String? = { _ in nil }
  
  enum Failure: Error, Equatable {
    case recognizerNotAvailable
    case transcriptionFailed
  }
}

extension SpeechRecognizerClient: DependencyKey {
  static var liveValue: Self {
    let speechRecognizer = SpeechRecognizer()
    return Self(
      requestAuthorization: {
        await withCheckedContinuation { continuation in
          SFSpeechRecognizer.requestAuthorization { status in
            continuation.resume(returning: status)
          }
        }
      },
      transcribeFile: { url in
        return try await speechRecognizer.transcribeFile(at: url)
      }
    )
  }
}

private actor SpeechRecognizer {
  func transcribeFile(at url: URL) async throws -> String? {
    guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")),
          recognizer.isAvailable else {
      throw SpeechRecognizerClient.Failure.recognizerNotAvailable
    }
    
    let request = SFSpeechURLRecognitionRequest(url: url)
    request.shouldReportPartialResults = false
    request.requiresOnDeviceRecognition = true
    
    let stream = AsyncThrowingStream<String, Error> { continuation in
      let task = recognizer.recognitionTask(with: request) { result, error in
        if let error {
          continuation.finish(throwing: error)
        } else if let result {
          if result.isFinal {
            continuation.yield(result.bestTranscription.formattedString)
            continuation.finish()
          }
        }
      }
      continuation.onTermination = { @Sendable _ in
        task.cancel()
      }
    }
    
    for try await transcription in stream {
      return transcription
    }
    
    throw SpeechRecognizerClient.Failure.transcriptionFailed
  }
}

extension SpeechRecognizerClient: TestDependencyKey {
  static var previewValue: Self {
    return Self(
      requestAuthorization: { .authorized },
      transcribeFile: { _ in
        """
        This is a test transcription. The weather is nice today and I'm feeling great about 
        the progress we're making on this project.
        """
      }
    )
  }
  
  static let testValue = Self()
}

extension DependencyValues {
  var speechRecognizerClient: SpeechRecognizerClient {
    get { self[SpeechRecognizerClient.self] }
    set { self[SpeechRecognizerClient.self] = newValue }
  }
}

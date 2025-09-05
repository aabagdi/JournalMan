//
//  AudioRecorderClient.swift
//  JournalMan
//
//  Created by Aadit Bagdi on 8/22/25.
//

import Foundation
@preconcurrency import AVFoundation
import Speech
import ComposableArchitecture
import SharingGRDB
import CoreML

@DependencyClient
struct AudioRecorderClient {
  var currentTime: @Sendable () async -> TimeInterval?
  var isRecording: @Sendable () async -> Bool = { false }
  var requestRecordPermission: @Sendable () async -> Bool = { false }
  var startRecording: @Sendable () async throws -> Bool
  var stopRecording: @Sendable () async -> Void
  
  enum Failure: Error, Equatable {
    case speechRecognitionError
    case speechRecognitionNotAuthorized
    case emotionClassificationError
    case topicClassificationError
  }
}

extension AudioRecorderClient: TestDependencyKey {
  static var previewValue: Self {
    let isRecording = LockIsolated(false)
    let currentTime = LockIsolated<TimeInterval?>(nil)
    let recordingTask = LockIsolated<Task<Void, Never>?>(nil)
    
    return Self(
      currentTime: {
        currentTime.value
      },
      isRecording: {
        isRecording.value
      },
      requestRecordPermission: {
        true
      },
      startRecording: {
        recordingTask.value?.cancel()
        recordingTask.setValue(nil)
        
        isRecording.setValue(true)
        currentTime.setValue(0)
        
        let task = Task {
          let startTime = Date()
          while !Task.isCancelled {
            let elapsed = Date().timeIntervalSince(startTime)
            currentTime.setValue(elapsed)
            
            if elapsed >= 20 {
              break
            }
            
            if !isRecording.value {
              break
            }
            
            try? await Task.sleep(for: .milliseconds(100))
          }
          
          if !Task.isCancelled {
            isRecording.setValue(false)
            currentTime.setValue(nil)
          }
        }
        
        recordingTask.setValue(task)
        
        return true
      },
      stopRecording: {
        recordingTask.value?.cancel()
        recordingTask.setValue(nil)
        
        isRecording.setValue(false)
        currentTime.setValue(nil)
      }
    )
  }
  
  static let testValue = Self()
}

extension DependencyValues {
  var audioRecorder: AudioRecorderClient {
    get { self[AudioRecorderClient.self] }
    set { self[AudioRecorderClient.self] = newValue }
  }
}

extension AudioRecorderClient: DependencyKey {
  static var liveValue: Self {
    let audioRecorder = AudioRecorder()
    return Self(
      currentTime: { await audioRecorder.currentTime },
      isRecording: { await audioRecorder.isRecording },
      requestRecordPermission: { await AudioRecorder.requestPermission() },
      startRecording: { try await audioRecorder.start() },
      stopRecording: { await audioRecorder.stop() }
    )
  }
}

private class AudioRecorder {
  var delegate: Delegate?
  var recorder: AVAudioRecorder?
  
  private var currentRecordingID: UUID?
  
  private var currentRecordingURL: URL? {
    get { recorder?.url }
  }
  
  @Dependency(\.uuid) var uuid
  @Dependency(\.date.now) var now
  @Dependency(\.defaultDatabase) var database
  @Dependency(TopicClassifierClient.self) var topicClassifier
  @Dependency(EmotionClassifierClient.self) var emotionClassifier
  @Dependency(FileManagerClient.self) var fileManager
  @Dependency(SpeechRecognizerClient.self) var speechRecognizer
  
  var currentTime: TimeInterval? {
    guard
      let recorder = self.recorder,
      recorder.isRecording
    else { return nil }
    return recorder.currentTime
  }
  
  var isRecording: Bool {
    guard let recorder else { return false }
    return recorder.isRecording
  }
  
  static func requestPermission() async -> Bool {
    await AVAudioApplication.requestRecordPermission()
  }
  
  func stop() async {
    let wasRecording = self.recorder?.isRecording ?? false
    let recordingURL = self.recorder?.url
    let recordingID = self.currentRecordingID
    
    self.recorder?.stop()
    self.recorder = nil
    self.delegate = nil
    
    if wasRecording, let url = recordingURL, let id = recordingID {
      do {
        _ = try await processRecording(at: url, recordingID: id)
      } catch {
        print("Failed to process recording on manual stop: \(error)")
      }
    }
    
    if let url = recordingURL {
      await cleanupTempFile(at: url)
    }
    
    try? AVAudioSession.sharedInstance().setActive(false)
    
    self.currentRecordingID = nil
  }
  
  func start() async throws -> Bool {
    await cleanupOrphanedFiles()
    
    await self.stop()
    
    let speechStatus = await speechRecognizer.requestAuthorization()
    guard speechStatus == .authorized else {
      throw AudioRecorderClient.Failure.speechRecognitionNotAuthorized
    }
    
    self.currentRecordingID = uuid()
    
    do {
      try AVAudioSession.sharedInstance().setCategory(
        .playAndRecord,
        mode: .default,
        options: .defaultToSpeaker
      )
      try AVAudioSession.sharedInstance().setActive(true)
      
      self.delegate = Delegate(
        didFinishRecording: { [weak self] flag in
          guard let self else { return }
          
          print("Delegate: Recording finished with flag: \(flag)")
          
          Task {
            guard flag,
                  let recorder = await self.recorder,
                  let recordingID = await self.currentRecordingID else {
              return
            }
            
            let recordingURL = recorder.url
            
            do {
              _ = try await self.processRecording(at: recordingURL, recordingID: recordingID)
            } catch {
              print("Failed to process recording: \(error)")
            }
            
            await self.cleanupTempFile(at: recordingURL)
            
            try? AVAudioSession.sharedInstance().setActive(false)
          }
        },
        encodeErrorDidOccur: { error in
          print("Recording encode error: \(error?.localizedDescription ?? "unknown")")
          try? AVAudioSession.sharedInstance().setActive(false)
        }
      )
      
      let url = createTemporaryURL()
      
      let recorder = try AVAudioRecorder(
        url: url,
        settings: [
          AVFormatIDKey: Int(kAudioFormatLinearPCM),
          AVSampleRateKey: 44100,
          AVNumberOfChannelsKey: 1,
          AVLinearPCMBitDepthKey: 16,
          AVLinearPCMIsFloatKey: false,
          AVLinearPCMIsBigEndianKey: false
        ]
      )
      self.recorder = recorder
      recorder.delegate = self.delegate
      
      let didStartRecording = recorder.record(forDuration: 20)
      
      print("Recording started successfully: \(didStartRecording)")
      
      return didStartRecording
      
    } catch {
      print("Error in start(): \(error)")
      await self.stop()
      throw error
    }
  }
  
  private func processRecording(at recordingURL: URL, recordingID: UUID) async throws -> Bool {
    let transcript = try await speechRecognizer.transcribeFile(recordingURL)
    
    print("Transcription result: \(transcript ?? "No transcript available")")
    
    let audioData = try Data(contentsOf: recordingURL)
    
    let windows = try AudioRecorder.extractAudioSamples(
      from: recordingURL,
      targetSampleCount: 15600
    )
    
    var weightedVotes = [String: Double]()
    var predictions = [(emotion: String, confidence: Double)]()
    
    for window in windows {
      let input = EmotionClassifierInput(audioSamples: window)
      let output = try await self.emotionClassifier.predict(input)
      
      let topEmotion = output.target
      let confidence = output.targetProbability[topEmotion] ?? 0.0
      
      weightedVotes[topEmotion, default: 0] += confidence
      predictions.append((emotion: topEmotion, confidence: confidence))
    }
    
    let dominantEmotion = weightedVotes.max { $0.value < $1.value }
    
    let totalWeight = weightedVotes.values.reduce(0, +)
    let winningWeightPercentage = (dominantEmotion?.value ?? 0) / totalWeight
    let actualVoteCount = predictions.filter { $0.emotion == dominantEmotion?.key }.count
    
    print("=== Weighted Voting Results ===")
    print("Dominant emotion: \(dominantEmotion?.key ?? "unknown")")
    print("Weighted score: \(String(format: "%.2f", dominantEmotion?.value ?? 0))")
    print("Actual vote count: \(actualVoteCount) out of \(predictions.count) windows")
    print("Weighted percentage: \(String(format: "%.1f%%", winningWeightPercentage * 100))")
    print("\nWeighted scores:")
    for (emotion, score) in weightedVotes.sorted(by: { $0.value > $1.value }) {
      print("  \(emotion): \(String(format: "%.2f", score))")
    }
    
    let topicClassifierInput = TopicClassifierInput(text: transcript ?? "")
    let topic = try await self.topicClassifier.predict(topicClassifierInput).label
    
    try self.saveRecordingInDB(
      audioData: audioData,
      recordingID: recordingID,
      emotion: dominantEmotion?.key.capitalized,
      topic: topic.capitalized,
      transcript: transcript
    )
    
    return true
  }
}

private final class Delegate: NSObject, AVAudioRecorderDelegate, Sendable {
  let didFinishRecording: @Sendable (Bool) -> Void
  let encodeErrorDidOccur: @Sendable ((any Error)?) -> Void
  
  init(
    didFinishRecording: @escaping @Sendable (Bool) -> Void,
    encodeErrorDidOccur: @escaping @Sendable ((any Error)?) -> Void
  ) {
    self.didFinishRecording = didFinishRecording
    self.encodeErrorDidOccur = encodeErrorDidOccur
  }
  
  func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
    self.didFinishRecording(flag)
  }
  
  func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: (any Error)?) {
    self.encodeErrorDidOccur(error)
  }
}

extension AudioRecorder {
  private func createTemporaryURL() -> URL {
    let tempURL = fileManager.createTemporaryFileURL(withExtension: "caf", with: currentRecordingID!)
    return tempURL
  }
  
  static func extractAudioSamples(from url: URL, targetSampleCount: Int = 15600) throws -> [MLMultiArray] {
    let audioFile = try AVAudioFile(forReading: url)
    
    let fileFormat = audioFile.fileFormat
    let frameCount = AVAudioFrameCount(audioFile.length)
    
    guard let buffer = AVAudioPCMBuffer(pcmFormat: fileFormat, frameCapacity: frameCount) else {
      throw AudioProcessingError.bufferCreationFailed
    }
    
    try audioFile.read(into: buffer)
    
    let targetSampleRate: Double = 16000
    let convertedBuffer = try convertToMonoAndResample(
      buffer: buffer,
      targetSampleRate: targetSampleRate
    )
    
    return try extractWindows(
      from: convertedBuffer,
      windowSizeInSamples: targetSampleCount,
      overlapFactor: 0.5
    )
  }
  
  private static func convertToMonoAndResample(
    buffer: AVAudioPCMBuffer,
    targetSampleRate: Double
  ) throws -> AVAudioPCMBuffer {
    let sourceFormat = buffer.format
    
    guard let targetFormat = AVAudioFormat(
      commonFormat: .pcmFormatFloat32,
      sampleRate: targetSampleRate,
      channels: 1,
      interleaved: false
    ) else {
      throw AudioProcessingError.invalidAudioFormat
    }
    
    if sourceFormat.sampleRate == targetSampleRate && sourceFormat.channelCount == 1 {
      return buffer
    }
    
    guard let converter = AVAudioConverter(from: sourceFormat, to: targetFormat) else {
      throw AudioProcessingError.conversionFailed
    }
    
    let outputFrameCapacity = AVAudioFrameCount(
      Double(buffer.frameLength) * targetSampleRate / sourceFormat.sampleRate
    )
    
    guard let outputBuffer = AVAudioPCMBuffer(
      pcmFormat: targetFormat,
      frameCapacity: outputFrameCapacity
    ) else {
      throw AudioProcessingError.bufferCreationFailed
    }
    
    var error: NSError?
    converter.convert(to: outputBuffer, error: &error) { inNumberOfPackets, outStatus in
      outStatus.pointee = .haveData
      return buffer
    }
    
    if let error = error {
      throw error
    }
    
    return outputBuffer
  }
  
  private static func extractWindows(
    from buffer: AVAudioPCMBuffer,
    windowSizeInSamples: Int,
    overlapFactor: Double
  ) throws -> [MLMultiArray] {
    guard let floatChannelData = buffer.floatChannelData else {
      throw AudioProcessingError.invalidAudioFormat
    }
    
    let totalSamples = Int(buffer.frameLength)
    let stride = Int(Double(windowSizeInSamples) * (1.0 - overlapFactor))
    
    var windows: [MLMultiArray] = []
    var startIndex = 0
    
    while startIndex + windowSizeInSamples <= totalSamples {
      let multiArray = try MLMultiArray(
        shape: [windowSizeInSamples as NSNumber],
        dataType: .float32
      )
      
      for i in 0..<windowSizeInSamples {
        multiArray[i] = NSNumber(value: floatChannelData[0][startIndex + i])
      }
      
      windows.append(multiArray)
      startIndex += stride
    }
    
    if startIndex < totalSamples && totalSamples > windowSizeInSamples {
      let multiArray = try MLMultiArray(
        shape: [windowSizeInSamples as NSNumber],
        dataType: .float32
      )
      
      let remainingSamples = totalSamples - startIndex
      
      for i in 0..<remainingSamples {
        multiArray[i] = NSNumber(value: floatChannelData[0][startIndex + i])
      }
      
      for i in remainingSamples..<windowSizeInSamples {
        multiArray[i] = 0
      }
      
      windows.append(multiArray)
    }
    
    if windows.isEmpty {
      let multiArray = try MLMultiArray(
        shape: [windowSizeInSamples as NSNumber],
        dataType: .float32
      )
      
      for i in 0..<min(totalSamples, windowSizeInSamples) {
        multiArray[i] = NSNumber(value: floatChannelData[0][i])
      }
      
      for i in totalSamples..<windowSizeInSamples {
        multiArray[i] = 0
      }
      
      windows.append(multiArray)
    }
    
    return windows
  }
  
  private func cleanupTempFile(at url: URL) async {
    if fileManager.fileExists(url) {
      do {
        try await fileManager.removeItem(url)
        print("Cleaned up temp file: \(url.lastPathComponent)")
      } catch {
        print("Failed to clean up temp file: \(error)")
      }
    }
  }
  
  private func cleanupOrphanedFiles() async {
    let tempDir = fileManager.temporaryDirectory()
    
    do {
      let contents = try await fileManager.contentsOfDirectory(tempDir)
      let oneHourAgo = now.addingTimeInterval(-3600)
      
      for url in contents where url.pathExtension == "caf" {
        if let creationDate = try? await fileManager.creationDate(url),
           creationDate < oneHourAgo {
          try await fileManager.removeItem(url)
          print("Cleaned up orphaned recording: \(url.lastPathComponent)")
        }
      }
    } catch {
      print("Error cleaning up orphaned files: \(error)")
    }
  }
  
  private func saveRecordingInDB(audioData: Data, recordingID: UUID, emotion: String?, topic: String?, transcript: String?) throws {
    let journalEntry = JournalEntry(
      id: recordingID,
      date: now,
      emotion: emotion,
      topic: topic,
      transcript: transcript
    )
    
    let journalEntryAsset = JournalEntryAsset(
      assetID: recordingID,
      audioData: audioData
    )
    
    withErrorReporting {
      try database.write { db in
        try JournalEntry.insert {
          journalEntry
        }
        .execute(db)
        
        try JournalEntryAsset.insert {
          journalEntryAsset
        }
        .execute(db)
      }
    }
  }
}

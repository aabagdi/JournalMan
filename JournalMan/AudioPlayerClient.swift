//
//  AudioPlayerClient.swift
//  JournalMan
//
//  Created by Aadit Bagdi on 11/17/25.
//

import Foundation
import ComposableArchitecture
import Dependencies
import SQLiteData
@preconcurrency import AVFoundation

@DependencyClient
struct AudioPlayerClient {
  var play: @Sendable (_ date: Date) async throws -> Bool
  var pause: @Sendable () -> Void
  var stop: @Sendable () -> Void
  var seek: @Sendable (_ position: TimeInterval) -> Void
}

extension AudioPlayerClient: TestDependencyKey {
  static let previewValue = Self(
    play: { _ in
      try await Task.sleep(for: .seconds(5))
      return true
    },
    
    pause: { },
    
    stop: { },
    
    seek: { _ in }
  )
  
  static let testValue = Self()
}

extension DependencyValues {
  var audioPlayer: AudioPlayerClient {
    get { self[AudioPlayerClient.self] }
    set { self[AudioPlayerClient.self] = newValue }
  }
}

extension AudioPlayerClient: DependencyKey {
  static let liveValue: AudioPlayerClient = {
    @Dependency(\.defaultDatabase) var database
    @Dependency(FileManagerClient.self) var fileManager
    
    let getURLfromDate: @Sendable (Date) throws -> URL = { date in
      print("🔍 Fetching audio for date: \(date)")
      
      let result: (JournalEntry, JournalEntryAsset?) = try database.read { db in
        try JournalEntry
          .where { $0.date.eq(date.startOfDay()) }
          .leftJoin(JournalEntryAsset.all) { $0.id.eq($1.assetID) }
          .fetchOne(db)!
      }
      
      print("📊 Database query result - Entry: \(result.0.id), Asset exists: \(result.1 != nil)")
      
      guard let asset = result.1 else {
        print("❌ No audio asset found in database for date: \(date)")
        throw AudioPlaybackError.noAssetFound
      }
      
      print("✅ Found audio asset with ID: \(asset.assetID), data size: \(asset.audioData.count) bytes")
      
      guard !asset.audioData.isEmpty else {
        print("❌ Audio data is empty!")
        throw AudioPlaybackError.noAssetFound
      }
      
      let tempURL = fileManager.createTemporaryFileURL(
        withExtension: "caf",
        with: asset.assetID
      )
      
      print("📝 Writing audio data to: \(tempURL.path)")
      print("📁 Temp directory: \(fileManager.temporaryDirectory().path)")
      
      try asset.audioData.write(to: tempURL, options: .atomic)
      
      guard fileManager.fileExists(tempURL) else {
        print("❌ File was not written successfully to: \(tempURL.path)")
        throw AudioPlaybackError.fileWriteFailed
      }
      
      if let attributes = try? FileManager.default.attributesOfItem(atPath: tempURL.path),
         let fileSize = attributes[.size] as? Int {
        print("✅ Audio file written successfully. File size: \(fileSize) bytes")
        
        if fileSize != asset.audioData.count {
          print("⚠️ Warning: File size (\(fileSize)) doesn't match data size (\(asset.audioData.count))")
        }
      }
      
      return tempURL
    }
    
    actor PlayerState {
      var currentDelegate: Delegate?
      
      func setDelegate(_ delegate: Delegate) {
        currentDelegate?.cancel()
        currentDelegate = delegate
      }
      
      func pause() {
        currentDelegate?.player.pause()
      }
      
      func stop() {
        currentDelegate?.cancel()
        currentDelegate = nil
      }
      
      func seek(to position: TimeInterval) {
        currentDelegate?.player.currentTime = position
      }
      
      func clear() {
        currentDelegate = nil
      }
    }
    
    let playerState = PlayerState()
    
    return Self(
      play: { date in
        let url: URL = try getURLfromDate(date)
        
        let result: Bool = try await withCheckedThrowingContinuation { continuation in
          do {
            let delegate = try Delegate(
              url: url,
              didFinishPlaying: { success in
                continuation.resume(returning: success)
                Task { await playerState.clear() }
              },
              decodeErrorDidOccur: { error in
                continuation.resume(throwing: error ?? AudioPlaybackError.unknownDecodeError)
                Task { await playerState.clear() }
              }
            )
            
            Task { await playerState.setDelegate(delegate) }
            delegate.player.play()
          } catch {
            continuation.resume(throwing: error)
          }
        }
        
        return result
      },
      
      pause: {
        Task { await playerState.pause() }
      },
      
      stop: {
        Task { await playerState.stop() }
      },
      
      seek: { position in
        Task { await playerState.seek(to: position) }
      }
    )
  }()
}

private final class Delegate: NSObject, AVAudioPlayerDelegate, Sendable {
  let didFinishPlaying: @Sendable (Bool) -> Void
  let decodeErrorDidOccur: @Sendable (Error?) -> Void
  let player: AVAudioPlayer
  private nonisolated(unsafe) var hasResumed = false
  
  init(
    url: URL,
    didFinishPlaying: @escaping @Sendable (Bool) -> Void,
    decodeErrorDidOccur: @escaping @Sendable (Error?) -> Void
  ) throws {
    self.didFinishPlaying = didFinishPlaying
    self.decodeErrorDidOccur = decodeErrorDidOccur
    
    try AVAudioSession.sharedInstance().setCategory(
      .playback,
      mode: .default,
      options: []
    )
    try AVAudioSession.sharedInstance().setActive(true)
    
    print("🎵 Initializing AVAudioPlayer with file: \(url.path)")
    self.player = try AVAudioPlayer(contentsOf: url)
    print("🎵 AVAudioPlayer created successfully. Duration: \(player.duration)s")
    
    super.init()
    self.player.delegate = self
    
    guard self.player.prepareToPlay() else {
      print("❌ Failed to prepare audio player")
      throw AudioPlaybackError.playbackFailed
    }
    
    print("✅ AVAudioPlayer prepared and ready to play")
  }
  
  func cancel() {
    resumeOnce(successfully: false)
    player.stop()
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }
  
  private func resumeOnce(successfully flag: Bool) {
    if !hasResumed {
      hasResumed = true
      didFinishPlaying(flag)
      try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
  }
  
  private func resumeOnce(withError error: Error?) {
    if !hasResumed {
      hasResumed = true
      decodeErrorDidOccur(error)
      try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
  }
  
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    resumeOnce(successfully: flag)
  }
  
  func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?) {
    resumeOnce(withError: error)
  }
}

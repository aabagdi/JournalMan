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
      let result: (JournalEntry, JournalEntryAsset?) = try database.read { db in
        try JournalEntry
          .where { $0.date.eq(date.startOfDay()) }
          .leftJoin(JournalEntryAsset.all) { $0.id.eq($1.assetID) }
          .fetchOne(db)!
      }
      
      guard let asset = result.1 else {
        throw AudioPlaybackError.noAssetFound
      }
      
      let tempURL = fileManager.createTemporaryFileURL(
        withExtension: ".caf",
        with: asset.assetID
      )
      
      try asset.audioData.write(to: tempURL)
      
      return tempURL
    }
    
    actor PlayerState {
      var currentDelegate: Delegate?
      
      func setDelegate(_ delegate: Delegate) {
        currentDelegate = delegate
      }
      
      func pause() {
        currentDelegate?.player.pause()
      }
      
      func stop() {
        currentDelegate?.player.stop()
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
  
  init(
    url: URL,
    didFinishPlaying: @escaping @Sendable (Bool) -> Void,
    decodeErrorDidOccur: @escaping @Sendable (Error?) -> Void
  ) throws {
    self.didFinishPlaying = didFinishPlaying
    self.decodeErrorDidOccur = decodeErrorDidOccur
    self.player = try AVAudioPlayer(contentsOf: url)
    super.init()
    self.player.delegate = self
  }
  
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    self.didFinishPlaying(flag)
  }
  
  func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?) {
    self.decodeErrorDidOccur(error)
  }
}

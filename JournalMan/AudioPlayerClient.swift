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
  var play: @Sendable (_ date: Date) async throws -> Void
  var pause: @Sendable () -> Void
  private var getURLfromDate: @Sendable (_ date: Date) throws -> URL
}

extension AudioPlayerClient: TestDependencyKey {
  static let previewValue = Self(
    play: { _ in
      try await Task.sleep(for: .seconds(5))
    },
    
    pause: { _ in
      try await Task.sleep(for: .seconds(5))
    },
    
    getURLfromDate: { _ in
      URL(fileURLWithPath: "/tmp/preview_audio.m4a")
    }
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
      try database.read { db in
        let entryAndAsset = try JournalEntry
          .where { $0.date.eq(date.startOfDay()) }
          .leftJoin(JournalEntryAsset.all) { $0.id.eq($1.assetID) }
          .fetchOne(db)
        
        let tempURL = fileManager.createTemporaryFileURL(withExtension: .caf, with: entryAndAsset.1.assetID)
        
        entryAndAsset.1.audioData.write(to: tempURL)
        
        return tempURL
      }
    }
    
    actor PlayerState {
      var currentDelegate: Delegate?
      
      func setDelegate(_ delegate: Delegate) {
        currentDelegate = delegate
      }
      
      func pause() {
        currentDelegate?.player.pause()
      }
      
      func clear() {
        currentDelegate = nil
      }
    }
    
    let playerState = PlayerState()
    
    return Self(
      play: { date in
        let url = try getURLfromDate(date)
        let stream = AsyncThrowingStream<Bool, any Error> { continuation in
          do {
            let delegate = Delegate(
              url: url,
              didFinishPlaying: { success in
                continuation.yield(success)
                continuation.finish()
                Task { await playerState.clear() }
              },
              decodeErrorDidOccur: { error in
                continuation.finish(throwing: error)
                Task { await playerState.clear() }
              }
            )
            
            Task { await playerState.setDelegate(delegate) }
            delegate.player.play()
            
            continuation.onTermination { _ in
              delegate.player.stop()
              Task { await playerState.clear() }
            }
          } catch {
            continuation.finish(throwing: error)
          }
        }
        
        return try await stream.first(where: { _ in true }) ?? false
      },
      
      pause: {
        Task { await playerState.pause() }
      },
      
      getURLfromDate: getURLfromDate
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

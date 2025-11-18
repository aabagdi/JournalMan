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
  private var getURLfromDate: @Sendable (_ date: Date) throws -> URL
}

extension AudioPlayerClient: TestDependencyKey {
  static let previewValue = Self(
    play: { _ in
      try await Task.sleep(for: .seconds(5))
      return true
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
    @Dependency(\.calendar) var calendar
    @Dependency(FileManagerClient.self) var fileManager
    
    let getURLfromDate: @Sendable (Date) throws -> URL = { date in
      @FetchOne(JournalEntry.where { calendar.compare($0.date, to: date, toGranularity: .day) == .orderedSame }) var entryToday: JournalEntry?
      
      guard let entryToday else { throw AudioPlaybackError.noEntryFound }
      
      @FetchOne(JournalEntryAsset.where { $0.assetID == entryToday.id }) var assetToday: JournalEntryAsset?
      
      guard let assetToday else { throw AudioPlaybackError.noDataFound }
      
      let tempURL = fileManager.createTemporaryFileURL(withExtension: "caf", with: entryToday.id)
      
      try? assetToday.audioData?.write(to: tempURL)
      
      return tempURL
    }
    
    return Self(
      play: { date in
        let url = try getURLfromDate(date)
        let success = try await withCheckedThrowingContinuation { continuation in
          do {
            let delegate = try Delegate(
              url: url,
              didFinishPlaying: { success in
                continuation.resume(returning: success)
              },
              decodeErrorDidOccur: { error in
                if let error {
                  continuation.resume(throwing: error)
                } else {
                  continuation.resume(returning: false)
                }
              }
            )
            delegate.player.play()
          } catch {
            continuation.resume(throwing: error)
          }
        }
        
        try? await fileManager.removeItem(url)
        return success
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

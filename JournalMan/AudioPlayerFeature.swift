//
//  AudioPlayerFeature.swift
//  JournalMan
//
//  Created by Aadit Bagdi on 11/18/25.
//

import Foundation
import ComposableArchitecture

@Reducer
struct AudioPlayerFeature {
  @ObservableState
  struct State: Equatable {
    var date: Date
    var currentSeekPosition: TimeInterval?
    var isPlaying: Bool
  }
  
  enum Action: Equatable {
    case playButtonTapped
    case pauseButtonTapped
    case deleteButtonTapped
    case sheetDismissed
    case seekingPlayhead(TimeInterval?)
    case playbackFailed(Error)
    
    static func == (lhs: Action, rhs: Action) -> Bool {
      switch (lhs, rhs) {
      case (.playButtonTapped, .playButtonTapped),
        (.pauseButtonTapped, .pauseButtonTapped),
        (.deleteButtonTapped, .deleteButtonTapped),
        (.sheetDismissed, .sheetDismissed):
        return true
      case let (.seekingPlayhead(lhs), .seekingPlayhead(rhs)):
        return lhs == rhs
      case let (.playbackFailed(lhs), .playbackFailed(rhs)):
        return lhs.localizedDescription == rhs.localizedDescription
      default:
        return false
      }
    }
  }
  
  @Dependency(AudioPlayerClient.self) var audioPlayer
  @Dependency(\.defaultDatabase) var database
  @Dependency(\.continuousClock) var clock
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .playButtonTapped:
        if !state.isPlaying {
          state.isPlaying = true
          return .run { [date = state.date] send in
            do {
              try await audioPlayer.play(date: date)
            } catch {
              await send(.playbackFailed(error))
            }
          }
        } else {
          return .none
        }
        
      case .pauseButtonTapped:
        state.isPlaying = false
        return .run { _ in
          await audioPlayer.pause()
        }
        
      case .playbackFailed(let error):
        state.isPlaying = false
        print("Playback failed: \(error.localizedDescription)")
        return .none
        
      case .deleteButtonTapped:
        return .run { [date = state.date] _ in
          try await database.write { db in
            let entryAndAsset = try JournalEntry
              .where { $0.date.eq(date.startOfDay()) }
              .leftJoin(JournalEntryAsset.all) { $0.id.eq($1.assetID) }
              .fetchOne(db)
            
            try entryAndAsset.1?.delete(db)
            try entryAndAsset.2?.delete(db)
          }
        }
        
      case .sheetDismissed:
        return .run { _ in
          await audioPlayer.stop()
        }
        
      case .seekingPlayhead(let position):
        state.currentSeekPosition = position
        if let position = position {
          return .run { _ in
            await audioPlayer.seek(to: position)
          }
        } else {
          return .none
        }
      }
    }
  }
}

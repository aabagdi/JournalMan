//
//  AudioPlayerFeature.swift
//  JournalMan
//
//  Created by Aadit Bagdi on 11/18/25.
//

import Foundation
import ComposableArchitecture
import SQLiteData

@Reducer
struct AudioPlayerFeature {
  @ObservableState
  struct State: Equatable {
    var date: Date
    var currentSeekPosition: TimeInterval?
    var isPlaying: Bool
    var journalEntry: JournalEntry?
    var hasAudioAsset: Bool = false
    var isLoading: Bool = true
    var loadError: String?
  }
  
  enum Action: Equatable {
    case onAppear
    case journalEntryLoaded(JournalEntry, hasAudio: Bool)
    case loadFailed(String)
    case playButtonTapped
    case pauseButtonTapped
    case deleteButtonTapped
    case entryDeleted
    case sheetDismissed
    case playbackFailed(Error)
    case delegate(Delegate)
    
    enum Delegate: Equatable {
      case entryDeleted
    }
    
    static func == (lhs: Action, rhs: Action) -> Bool {
      switch (lhs, rhs) {
      case (.onAppear, .onAppear),
        (.playButtonTapped, .playButtonTapped),
        (.pauseButtonTapped, .pauseButtonTapped),
        (.deleteButtonTapped, .deleteButtonTapped),
        (.entryDeleted, .entryDeleted),
        (.sheetDismissed, .sheetDismissed):
        return true
      case let (.journalEntryLoaded(lhsEntry, lhsHasAudio), .journalEntryLoaded(rhsEntry, rhsHasAudio)):
        return lhsEntry == rhsEntry && lhsHasAudio == rhsHasAudio
      case let (.loadFailed(lhs), .loadFailed(rhs)):
        return lhs == rhs
      case let (.playbackFailed(lhs), .playbackFailed(rhs)):
        return lhs.localizedDescription == rhs.localizedDescription
      case let (.delegate(lhs), .delegate(rhs)):
        return lhs == rhs
      default:
        return false
      }
    }
  }
  
  @Dependency(AudioPlayerClient.self) var audioPlayer
  @Dependency(\.defaultDatabase) var database
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .run { [date = state.date] send in
          do {
            let result: (JournalEntry, JournalEntryAsset?) = try await database.read { db in
              try JournalEntry
                .where { $0.date.eq(date.startOfDay()) }
                .leftJoin(JournalEntryAsset.all) { $0.id.eq($1.assetID) }
                .fetchOne(db)!
            }
            
            await send(.journalEntryLoaded(result.0, hasAudio: result.1 != nil))
          } catch {
            await send(.loadFailed(error.localizedDescription))
          }
        }
      
      case let .journalEntryLoaded(entry, hasAudio):
        state.journalEntry = entry
        state.hasAudioAsset = hasAudio
        state.isLoading = false
        return .none
      
      case let .loadFailed(errorMessage):
        state.loadError = errorMessage
        state.isLoading = false
        return .none
        
      case .playButtonTapped:
        if !state.isPlaying {
          state.isPlaying = true
          return .run { [date = state.date] send in
            do {
             _ = try await audioPlayer.play(date: date)
            } catch {
              print(error.localizedDescription)
              await send(.playbackFailed(error))
            }
          }
        } else {
          return .none
        }
        
      case .pauseButtonTapped:
        state.isPlaying = false
        return .run { _ in
          audioPlayer.pause()
        }

      case .playbackFailed(let error):
        state.isPlaying = false
        print("Playback failed: \(error.localizedDescription)")
        return .none

      case .deleteButtonTapped:
        return .run { [date = state.date] send in
          try await database.write { db in
            let entry = try JournalEntry
              .where { $0.date.eq(date.startOfDay()) }
              .fetchOne(db)
            
            if let entry {
              try JournalEntryAsset
                .where { $0.assetID.eq(entry.id) }
                .delete()
                .execute(db)
              
              try JournalEntry
                .where { $0.id.eq(entry.id) }
                .delete()
                .execute(db)
            }
          }
          await send(.entryDeleted)
        }
      
      case .entryDeleted:
        return .send(.delegate(.entryDeleted))

      case .sheetDismissed:
        return .run { _ in
          audioPlayer.stop()
        }
      
      case .delegate:
        return .none
      }
    }
  }
}

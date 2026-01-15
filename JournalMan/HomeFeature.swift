//
//  HomeFeature.swift
//  JournalMan
//
//  Created by Aadit Bagdi on 8/25/25.
//

import Foundation
import ComposableArchitecture

@Reducer
struct HomeFeature {
  @Reducer
  enum Path {
    case record(AudioRecorderFeature)
    case player(AudioPlayerFeature)
  }
  
  enum CancelID {
    case path
  }
  
  @ObservableState
  struct State {
    var path = StackState<Path.State>()
    var calendar = CalendarViewFeature.State()
  }
  
  enum Action {
    case path(StackActionOf<Path>)
    case calendar(CalendarViewFeature.Action)
    case popRecordingScreen
    case popPlayerScreen
  }
  
  var body: some Reducer<State, Action> {
    Scope(state: \.calendar, action: \.calendar) {
      CalendarViewFeature()
    }
    
    Reduce { state, action in
      switch action {
      case .calendar(.recordButtonTapped):
        state.path.append(.record(AudioRecorderFeature.State()))
        return .none
        
      case let .calendar(.dateTapped(date)):
        if state.calendar.hasEntry(for: date) {
          state.path.append(.player(AudioPlayerFeature.State(
            date: date,
            currentSeekPosition: nil,
            isPlaying: false
          )))
        } else {
          state.path.append(.record(AudioRecorderFeature.State()))
        }
        return .none
        
      case .path(.element(_, .record(.delegate(.recordingCompleted)))):
        state.path.removeLast()
        return .run { send in
          try await Task.sleep(for: .milliseconds(100))
          await send(.calendar(.reloadEntries))
        }
        
      case .popRecordingScreen:
        state.path.removeLast()
        return .none
        
      case .path(.element(_, .player(.delegate(.entryDeleted)))):
        state.path.removeLast()
        return .run { send in
          // Small delay for navigation animation to complete
          try await Task.sleep(for: .milliseconds(100))
          await send(.calendar(.reloadEntries))
        }
        
      case .popPlayerScreen:
        state.path.removeLast()
        return .none
        
      case .path:
        return .none
        
      case .calendar:
        return .none
      }
    }
    .forEach(\.path, action: \.path)
  }
}

extension HomeFeature.Path.State: Equatable { }

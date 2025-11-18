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
  }
  
  @ObservableState
  struct State {
    var path = StackState<Path.State>()
    var calendar = CalendarViewFeature.State()
  }
  
  enum Action {
    case path(StackActionOf<Path>)
    case calendar(CalendarViewFeature.Action)
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
        
      case .path(.popFrom):
        // Reload entries when user comes back from recording
        return .send(.calendar(.reloadEntries))
        
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

//
//  AppFeature.swift
//  JournalMan
//
//  Created by Aadit Bagdi on 8/25/25.
//

import Foundation
import ComposableArchitecture

@Reducer
struct AppFeature {
  @ObservableState
  struct State: Equatable {
    var currentMonth: Date = Date()
    var selectedDate: Date = Date()
    var today: Date = Date()
  }
  
  enum Action {
    
  }
}

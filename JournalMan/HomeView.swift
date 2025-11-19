//
//  HomeView.swift
//  JournalMan
//
//  Created by Aadit Bagdi on 8/26/25.
//

import SwiftUI
import SQLiteData
import ComposableArchitecture

struct HomeView: View {
  @Bindable var store: StoreOf<HomeFeature>
  
  var body: some View {
    NavigationStack(
      path: $store.scope(state: \.path, action: \.path)
    ) {
      CalendarView(
        store: store.scope(
          state: \.calendar,
          action: \.calendar
        )
      )
      .scrollIndicators(.never)
      .navigationTitle("Calendar")
      .navigationBarTitleDisplayMode(.large)
    } destination: { store in
      switch store.case {
      case let .record(store):
        AudioRecorderView(store: store)
          .navigationTitle("Record Journal")
          .navigationBarTitleDisplayMode(.inline)
          
      case let .player(store):
        AudioPlayerView(store: store)
          .navigationTitle("Journal Entry")
          .navigationBarTitleDisplayMode(.inline)
      }
    }
  }
}

#Preview {
  let _ = prepareDependencies {
    $0.defaultDatabase = try! appDatabase()
  }
  
  HomeView(
    store: Store(
      initialState: HomeFeature.State()
    ) {
      HomeFeature()
    }
  )
}

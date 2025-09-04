//
//  HomeView.swift
//  JournalMan
//
//  Created by Aadit Bagdi on 8/26/25.
//

import SwiftUI
import SharingGRDB
import ComposableArchitecture

struct HomeView: View {
  var body: some View {
    CalendarView(
      store: Store(
        initialState: CalendarViewFeature.State()
      ) {
        CalendarViewFeature()
      }
    )
    .scrollIndicators(.never)
  }
}

#Preview {
  let _ = prepareDependencies {
    $0.defaultDatabase = try! appDatabase()
  }
  HomeView()
}

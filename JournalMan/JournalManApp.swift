//
//  JournalManApp.swift
//  JournalMan
//
//  Created by Aadit Bagdi on 8/20/25.
//

import SwiftUI
import SharingGRDB
import ComposableArchitecture

@main
struct JournalManApp: App {
  init() {
    prepareDependencies {
      $0.defaultDatabase = try! appDatabase()
    }
  }
  
  var body: some Scene {
    WindowGroup {
      AudioRecorderView(
        store: Store(
          initialState: AudioRecorderFeature.State()
        ) {
          AudioRecorderFeature()
        }
      )
    }
  }
}

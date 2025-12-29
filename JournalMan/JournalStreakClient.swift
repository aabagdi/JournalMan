//
//  JournalStreakClient.swift
//  JournalMan
//
//  Created by Aadit Bagdi on 11/19/25.
//

import Foundation
import Dependencies
import DependenciesMacros

@DependencyClient
struct JournalStreakClient {
  var setStreak: @Sendable (Int) -> Void
  var getStreak: @Sendable () -> Int = { 0 }
}

extension JournalStreakClient: TestDependencyKey {
  static let testValue = Self()
  
  static var previewValue: Self {
    Self(
      setStreak: { _ in },
      getStreak: { 3 }
    )
  }
}

extension DependencyValues {
  var userDefaults: JournalStreakClient {
    get { self[JournalStreakClient.self] }
    set { self[JournalStreakClient.self] = newValue }
  }
}

extension JournalStreakClient: DependencyKey {
  static var liveValue: Self {
    return Self(
      setStreak: { streak in
        let currentStreak = UserDefaults().integer(forKey: "streak")
        if streak > currentStreak {
          UserDefaults().set(streak, forKey: "streak")
        }
      },
      getStreak: {
        UserDefaults().integer(forKey: "streak")
      }
    )
  }
}

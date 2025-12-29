//
//  JournalStreakClient.swift
//  JournalMan
//
//  Created by Aadit Bagdi on 11/19/25.
//

import Foundation
import Dependencies
import DependenciesMacros

struct StreakInfo: Equatable, Sendable {
  var currentStreak: Int
  var longestStreak: Int
  var lastEntryDate: Date?
  
  var isActive: Bool {
    guard let lastDate = lastEntryDate else { return false }
    return Calendar.current.isDateInToday(lastDate) || Calendar.current.isDateInYesterday(lastDate)
  }
}

@DependencyClient
struct JournalStreakClient {
  var recordEntry: @Sendable (Date) -> StreakInfo = { _ in StreakInfo(currentStreak: 0, longestStreak: 0) }
  
  var getStreakInfo: @Sendable () -> StreakInfo = { StreakInfo(currentStreak: 0, longestStreak: 0) }
  
  var resetStreak: @Sendable () -> Void
}

extension JournalStreakClient: TestDependencyKey {
  static let testValue = Self()
  
  static var previewValue: Self {
    Self(
      recordEntry: { _ in StreakInfo(currentStreak: 3, longestStreak: 7, lastEntryDate: Date()) },
      getStreakInfo: { StreakInfo(currentStreak: 3, longestStreak: 7, lastEntryDate: Date()) },
      resetStreak: { }
    )
  }
}

extension DependencyValues {
  var journalStreak: JournalStreakClient {
    get { self[JournalStreakClient.self] }
    set { self[JournalStreakClient.self] = newValue }
  }
}

extension JournalStreakClient: DependencyKey {
  static var liveValue: Self {
    nonisolated(unsafe) let streakManager = StreakManager()
    
    return Self(
      recordEntry: { date in
        streakManager.recordEntry(date: date)
      },
      getStreakInfo: {
        streakManager.getStreakInfo()
      },
      resetStreak: {
        streakManager.resetStreak()
      }
    )
  }
}

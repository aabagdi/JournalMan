//
//  StreakManager.swift
//  JournalMan
//
//  Created by Aadit Bagdi on 12/29/25.
//

import Foundation
import Dependencies

class StreakManager {
  @Dependency(\.calendar) var calendar
  
  let userDefaults = UserDefaults.standard
  
  let currentStreakKey = "journalman.streak.current"
  let longestStreakKey = "journalman.streak.longest"
  let lastEntryDateKey = "journalman.streak.lastEntryDate"
  
  
  func recordEntry(date: Date) -> StreakInfo {
    let lastEntryDate = userDefaults.object(forKey: lastEntryDateKey) as? Date
    var currentStreak = userDefaults.integer(forKey: currentStreakKey)
    var longestStreak = userDefaults.integer(forKey: longestStreakKey)
    
    let entryDay = calendar.startOfDay(for: date)
    
    if let lastDate = lastEntryDate {
      let lastDay = calendar.startOfDay(for: lastDate)
      
      if entryDay == lastDay {
        return StreakInfo(
          currentStreak: currentStreak,
          longestStreak: longestStreak,
          lastEntryDate: lastDate
        )
      } else if calendar.isDate(entryDay, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: lastDay)!) {
        currentStreak += 1
      } else if entryDay > lastDay {
        currentStreak = 1
      }
      else {
        return StreakInfo(
          currentStreak: currentStreak,
          longestStreak: longestStreak,
          lastEntryDate: lastDate
        )
      }
    } else {
      currentStreak = 1
    }
    
    if currentStreak > longestStreak {
      longestStreak = currentStreak
      userDefaults.set(longestStreak, forKey: longestStreakKey)
    }
    
    userDefaults.set(currentStreak, forKey: currentStreakKey)
    userDefaults.set(date, forKey: lastEntryDateKey)
    
    return StreakInfo(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastEntryDate: date
    )
  }
  
  func getStreakInfo() -> StreakInfo {
    let currentStreak = userDefaults.integer(forKey: currentStreakKey)
    let longestStreak = userDefaults.integer(forKey: longestStreakKey)
    let lastEntryDate = userDefaults.object(forKey: lastEntryDateKey) as? Date
    
    var adjustedCurrentStreak = currentStreak
    if let lastDate = lastEntryDate {
      let lastDay = calendar.startOfDay(for: lastDate)
      let today = calendar.startOfDay(for: Date())
      
      let daysSinceLastEntry = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
      
      if daysSinceLastEntry > 1 {
        adjustedCurrentStreak = 0
        userDefaults.set(0, forKey: currentStreakKey)
      }
    }
    
    return StreakInfo(
      currentStreak: adjustedCurrentStreak,
      longestStreak: longestStreak,
      lastEntryDate: lastEntryDate
    )
  }
  
  func resetStreak() {
    userDefaults.removeObject(forKey: currentStreakKey)
    userDefaults.removeObject(forKey: longestStreakKey)
    userDefaults.removeObject(forKey: lastEntryDateKey)
  }
}

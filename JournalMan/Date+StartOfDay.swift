//
//  Date+StartOfDay.swift
//  JournalMan
//
//  Created by Aadit Bagdi on 11/18/25.
//

import Foundation
import Dependencies
import SQLiteData

extension Date {
  @DatabaseFunction
  func startOfDay() -> Date {
    @Dependency(\.calendar) var calendar
    
    return calendar.startOfDay(for: self)
  }
}

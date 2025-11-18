//
//  CalendarViewFeature.swift
//  JournalMan
//
//  Created by Aadit Bagdi on 8/26/25.
//

import Foundation
import ComposableArchitecture
import Dependencies
import SQLiteData

@Reducer
struct CalendarViewFeature {
  @ObservableState
  struct State: Equatable {
    var currentMonth: Date
    var today: Date
    var datesWithEntries: Set<Date> = []
    
    init(
      currentMonth: Date = Date(),
      today: Date = Date()
    ) {
      self.currentMonth = currentMonth
      self.today = today
    }
    
    var calendarDays: [Date?] {
      guard let monthRange = Calendar.current.range(of: .day, in: .month, for: currentMonth),
            let firstOfMonth = Calendar.current.date(
              from: Calendar.current.dateComponents([.year, .month], from: currentMonth)
            ) else {
        return []
      }
      
      let firstWeekday = Calendar.current.component(.weekday, from: firstOfMonth) - 1
      var days: [Date?] = Array(repeating: nil, count: firstWeekday)
      
      for day in monthRange {
        if let date = Calendar.current.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
          days.append(date)
        }
      }
      
      while days.count % 7 != 0 {
        days.append(nil)
      }
      
      return days
    }
  }
  
  enum Action: Equatable {
    case nextMonthButtonTapped
    case prevMonthButtonTapped
    case todayButtonTapped
    case recordButtonTapped
    case onAppear
    case reloadEntries
    case datesWithEntriesLoaded(Set<Date>)
  }
  
  @Dependency(\.date.now) var now
  @Dependency(\.calendar) var calendar
  @Dependency(\.defaultDatabase) var database
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .nextMonthButtonTapped:
        state.currentMonth = calendar.date(byAdding: .month, value: 1, to: state.currentMonth) ?? state.currentMonth
        return .none
        
      case .prevMonthButtonTapped:
        state.currentMonth = calendar.date(byAdding: .month, value: -1, to: state.currentMonth) ?? state.currentMonth
        return .none
        
      case .todayButtonTapped:
        state.currentMonth = now
        return .none
        
      case .recordButtonTapped:
        return .none
        
      case .onAppear, .reloadEntries:
        state.today = now
        return .run { send in
          let dates = try await loadDatesWithEntries()
          await send(.datesWithEntriesLoaded(dates))
        }
        
      case let .datesWithEntriesLoaded(dates):
        state.datesWithEntries = dates
        return .none
      }
    }
  }
  
  private func loadDatesWithEntries() async throws -> Set<Date> {
    try await database.read { db in
      @FetchAll var entries: [JournalEntry]
      let calendar = Calendar.current
      return Set(entries.map { calendar.startOfDay(for: $0.date) })
    }
  }
}

extension CalendarViewFeature.State {
  func isSameDay(date: Date, compareDate: Date) -> Bool {
    Calendar.current.isDate(date, inSameDayAs: compareDate)
  }
  
  func isSameMonth(date: Date) -> Bool {
    Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month)
  }
  
  func isDateToday(date: Date) -> Bool {
    Calendar.current.isDate(date, inSameDayAs: today)
  }
  
  func hasEntry(for date: Date) -> Bool {
    let startOfDay = Calendar.current.startOfDay(for: date)
    return datesWithEntries.contains(startOfDay)
  }
}

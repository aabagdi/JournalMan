//
//  CalendarViewFeature.swift
//  JournalMan
//
//  Created by Aadit Bagdi on 8/26/25.
//

import Foundation
import ComposableArchitecture
import Dependencies

@Reducer
struct CalendarViewFeature {
  @ObservableState
  struct State: Equatable {
    var currentMonth: Date
    var selectedDate: Date
    var today: Date
    
    init(
      currentMonth: Date = Date(),
      selectedDate: Date = Date(),
      today: Date = Date()
    ) {
      self.currentMonth = currentMonth
      self.selectedDate = selectedDate
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
    case dateTapped(Date)
    case onAppear
  }
  
  @Dependency(\.date.now) var now
  @Dependency(\.calendar) var calendar
  
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
        state.selectedDate = now
        return .none
        
      case let .dateTapped(date):
        state.selectedDate = date
        return .none
        
      case .onAppear:
        state.today = now
        return .none
      }
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
}

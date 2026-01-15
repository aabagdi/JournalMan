//
//  CalendarView.swift
//  JournalMan
//
//  Created by Aadit Bagdi on 8/20/25.
//

import SwiftUI
import SQLiteData
import ComposableArchitecture

struct CalendarView: View {
  @Dependency(JournalStreakClient.self) var journalStreak
  
  let store: StoreOf<CalendarViewFeature>
  let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
  
  var body: some View {
    ZStack {
      VStack(spacing: 20) {
        monthHeader
        
        weekDaysHeader
        
        calendarGrid
        
        recordButton
        
        Spacer()
      }
      .toolbar {
        let info = journalStreak.getStreakInfo()
        Text("Longest streak: \(String(info.currentStreak))")
          .padding()
      }
      .padding(.top)
      .disabled(store.isLoading)
      .blur(radius: store.isLoading ? 3 : 0)
      .animation(.easeInOut(duration: 0.2), value: store.isLoading)
      
      if store.isLoading {
        ZStack {
          Color.clear
            .background(.ultraThinMaterial)
            .ignoresSafeArea()
          
          VStack(spacing: 16) {
            ProgressView()
              .progressViewStyle(.circular)
              .scaleEffect(1.5)
            
            Text("Updating...")
              .font(.headline)
          }
          .padding(32)
          .background(
            RoundedRectangle(cornerRadius: 16)
              .fill(.regularMaterial)
          )
        }
        .transition(.opacity)
      }
    }
    .animation(.easeInOut(duration: 0.2), value: store.isLoading)
  }
  
  // MARK: - Subviews
  
  private var monthHeader: some View {
    HStack(spacing: 20) {
      VStack(alignment: .leading, spacing: 10) {
        Text(store.currentMonth, format: .dateTime.year())
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundColor(.secondary)
        
        Text(store.currentMonth, format: .dateTime.month(.wide))
          .font(.title.bold())
      }
      
      Spacer()
      
      Button {
        store.send(.prevMonthButtonTapped)
      } label: {
        Image(systemName: "chevron.left")
          .font(.title2)
          .foregroundColor(.primary)
      }
      
      Button {
        store.send(.todayButtonTapped)
      } label: {
        Text("Today")
          .font(.callout)
          .fontWeight(.semibold)
      }
      
      Button {
        store.send(.nextMonthButtonTapped)
      } label: {
        Image(systemName: "chevron.right")
          .font(.title2)
          .foregroundColor(.primary)
      }
    }
    .padding(.horizontal)
  }
  
  private var weekDaysHeader: some View {
    HStack(spacing: 0) {
      ForEach(days, id: \.self) { day in
        Text(day)
          .font(.callout)
          .fontWeight(.semibold)
          .frame(maxWidth: .infinity)
          .foregroundColor(.secondary)
      }
    }
    .padding(.horizontal)
  }
  
  private var calendarGrid: some View {
    LazyVGrid(
      columns: Array(repeating: GridItem(.flexible()), count: 7),
      spacing: 20
    ) {
      ForEach(0..<store.calendarDays.count, id: \.self) { index in
        calendarDayView(at: index)
      }
    }
    .padding(.horizontal)
  }
  
  @ViewBuilder
  private func calendarDayView(at index: Int) -> some View {
    let date = store.calendarDays[index]
    
    if let date {
      let isToday = store.state.isDateToday(date: date)
      let hasEntry = store.state.hasEntry(for: date)
      let isTappable = isToday || hasEntry
      
      if isTappable {
        Button {
          store.send(.dateTapped(date))
        } label: {
          CalendarCellView(
            date: date,
            isToday: isToday,
            isCurrentMonth: store.state.isSameMonth(date: date),
            hasEntry: hasEntry
          )
        }
        .buttonStyle(.plain)
      } else {
        CalendarCellView(
          date: date,
          isToday: isToday,
          isCurrentMonth: store.state.isSameMonth(date: date),
          hasEntry: hasEntry
        )
      }
    } else {
      Color.clear
        .frame(width: 40, height: 40)
    }
  }
  
  private var recordButton: some View {
    let hasEntryToday = store.state.hasEntry(for: store.state.today)
    
    return Button {
      store.send(.recordButtonTapped)
    } label: {
      HStack {
        Image(systemName: "mic.fill")
          .font(.title3)
        Text("Record Journal Entry")
          .font(.headline)
      }
      .frame(maxWidth: .infinity)
      .padding()
      .background(hasEntryToday ? Color.gray : Color.accentColor)
      .foregroundColor(.white)
      .cornerRadius(12)
    }
    .padding(.horizontal)
    .padding(.top, 10)
    .disabled(hasEntryToday)
  }
}

#Preview {
  let _ = prepareDependencies {
    $0.defaultDatabase = try! appDatabase()
  }
  
  CalendarView(
    store: Store(
      initialState: CalendarViewFeature.State()
    ) {
      CalendarViewFeature()
    }
  )
}

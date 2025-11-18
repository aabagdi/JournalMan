//
//  CalendarCellView.swift
//  JournalMan
//
//  Created by Aadit Bagdi on 8/26/25.
//

import SwiftUI

struct CalendarCellView: View {
  let date: Date
  let isToday: Bool
  let isCurrentMonth: Bool
  let hasEntry: Bool
  
  private var dayNumber: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "d"
    return formatter.string(from: date)
  }
  
  var body: some View {
    ZStack {
      if isToday && hasEntry {
        Circle()
          .fill(Color.accentColor)
          .frame(width: 40, height: 40)
      } else if isToday {
        Circle()
          .strokeBorder(Color.accentColor, lineWidth: 2)
          .frame(width: 40, height: 40)
      } else if hasEntry {
        Circle()
          .fill(Color.accentColor.opacity(0.7))
          .frame(width: 40, height: 40)
      }
      
      Text(dayNumber)
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(textColor)
        .frame(width: 40, height: 40)
    }
    .opacity(isCurrentMonth ? 1.0 : 0.3)
    .allowsHitTesting(isToday)
  }
  
  private var textColor: Color {
    if isToday && hasEntry {
      return .white
    } else if isToday {
      return .black
    } else if isCurrentMonth {
      return .gray
    } else {
      return .secondary
    }
  }
  
  private var opacity: Double {
    if !isToday {
      return 0.4
    } else if isCurrentMonth {
      return 1.0
    } else {
      return 0.3
    }
  }
}

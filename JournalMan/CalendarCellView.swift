//
//  CalendarCellView.swift
//  JournalMan
//
//  Created by Aadit Bagdi on 8/26/25.
//

import SwiftUI

struct CalendarCellView: View {
  let date: Date
  let isSelected: Bool
  let isToday: Bool
  let isCurrentMonth: Bool
  let isFutureDate: Bool
  
  private var dayNumber: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "d"
    return formatter.string(from: date)
  }
  
  var body: some View {
    ZStack {
      if isSelected {
        Circle()
          .fill(Color.accentColor)
          .frame(width: 40, height: 40)
      } else if isToday {
        Circle()
          .strokeBorder(Color.accentColor, lineWidth: 2)
          .frame(width: 40, height: 40)
      }
      
      Text(dayNumber)
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(textColor)
        .frame(width: 40, height: 40)
    }
    .opacity(isCurrentMonth ? 1.0 : 0.3)
    .allowsHitTesting(!isFutureDate)
  }
  
  private var textColor: Color {
    if isFutureDate {
      return .secondary.opacity(0.5)
    } else if isSelected {
      return .white
    } else if isToday {
      return .accentColor
    } else if isCurrentMonth {
      return .primary
    } else {
      return .secondary
    }
  }
  
  private var opacity: Double {
    if isFutureDate {
      return 0.4
    } else if isCurrentMonth {
      return 1.0
    } else {
      return 0.3
    }
  }
}

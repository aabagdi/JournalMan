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
  }
  
  private var textColor: Color {
    if isSelected {
      return .white
    } else if isToday {
      return .accentColor
    } else if isCurrentMonth {
      return .primary
    } else {
      return .secondary
    }
  }
}

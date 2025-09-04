//
//  AudioRecorderView.swift
//  JournalMan
//
//  Created by Aadit Bagdi on 9/1/25.
//

import SwiftUI
import ComposableArchitecture
import SharingGRDB

struct AudioRecorderView: View {
  let store: StoreOf<AudioRecorderFeature>
  
  var body: some View {
    NavigationStack {
      VStack {
        GeometryReader { g in
          ZStack {
            Button(action: {
              store.send(.recordButtonTapped)
            }) {
              Circle()
                .fill(store.isRecording ? Color.red : Color("ManPurple"))
                .frame(width: g.size.width/4, height: g.size.width/4)
                .overlay(
                  Image(systemName: "mic.fill")
                    .font(.system(size: g.size.width/12))
                    .imageScale(.medium)
                    .foregroundColor(.white)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(store.isRecording ? 1.0 : 1.0)
            .overlay(
              Circle()
                .stroke(store.isRecording ? Color.red : Color("ManPurple"), lineWidth: 3)
                .scaleEffect(store.animationAmount)
                .opacity(2.0 - store.animationAmount)
                .animation(
                  store.isRecording ?
                  Animation.easeOut(duration: 1)
                    .repeatForever(autoreverses: false) :
                    Animation.easeOut(duration: 0.3),
                  value: store.animationAmount
                )
            )
          }
          .frame(width: g.size.width, height: g.size.height, alignment: .center)
        }
        
        if store.isRecording, let currentTime = store.currentTime {
          Text(String(format: "%.0f", max(0, 20 - currentTime)))
            .font(.title2)
            .foregroundColor(.red)
            .transition(.scale.combined(with: .opacity))
        } else {
          Text("Tap to Record")
            .font(.title2)
            .foregroundColor(.secondary)
            .transition(.scale.combined(with: .opacity))
        }
      }
      .animation(.easeInOut(duration: 0.3), value: store.isRecording)
    }
  }
}

#Preview {
  let _ = prepareDependencies {
    $0.defaultDatabase = try! appDatabase()
  }
  
  AudioRecorderView(
    store: Store(
      initialState: AudioRecorderFeature.State()
    ) {
      AudioRecorderFeature()
    }
  )
}

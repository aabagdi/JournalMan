//
//  AudioRecorderFeature.swift
//  JournalMan
//
//  Created by Aadit Bagdi on 9/4/25.
//

import Foundation
import ComposableArchitecture

@Reducer
struct AudioRecorderFeature {
  @ObservableState
  struct State: Equatable {
    var currentTime: TimeInterval?
    var isRecording = false
    var fadeInOut = false
    var animationAmount = 1.0
  }
  
  enum Action: Equatable {
    case recordButtonTapped
    case sheetDismissed
    case recordingStarted
    case recordingStopped
    case updateCurrentTime(TimeInterval?)
  }
  
  @Dependency(AudioRecorderClient.self) var audioRecorder
  @Dependency(\.continuousClock) var clock
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .recordButtonTapped:
        if !state.isRecording {
          return .run { send in
            do {
              let started = try await audioRecorder.startRecording()
              
              if started {
                await send(.recordingStarted)
                
                for await _ in await clock.timer(interval: .seconds(0.1)) {
                  let currentTime = await audioRecorder.currentTime()
                  await send(.updateCurrentTime(currentTime))
                  
                  if let time = currentTime, time >= 20 {
                    await audioRecorder.stopRecording()
                    await send(.recordingStopped)
                    break
                  }
                  
                  let isStillRecording = await audioRecorder.isRecording()
                  if !isStillRecording {
                    await send(.recordingStopped)
                    break
                  }
                }
              }
            } catch {
              await send(.recordingStopped)
            }
          }
        } else {
          return .run { send in
            await audioRecorder.stopRecording()
            await send(.recordingStopped)
          }
        }
        
      case .sheetDismissed:
        return .run { _ in
          await audioRecorder.stopRecording()
        }
        
      case .recordingStarted:
        state.isRecording = true
        state.currentTime = 0
        state.animationAmount = 2.0
        return .none
        
      case .recordingStopped:
        state.isRecording = false
        state.currentTime = nil
        state.animationAmount = 1.0
        return .none
        
      case let .updateCurrentTime(time):
        state.currentTime = time
        return .none
      }
    }
  }
}

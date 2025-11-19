//
//  AudioPlayerView.swift
//  JournalMan
//
//  Created by Aadit Bagdi on 11/18/25.
//

import SwiftUI
import ComposableArchitecture
import SQLiteData

struct AudioPlayerView: View {
  let store: StoreOf<AudioPlayerFeature>
  
  var body: some View {
    VStack(spacing: 20) {
      if store.isLoading {
        ProgressView("Loading...")
      } else if let error = store.loadError {
        ContentUnavailableView(
          "Unable to Load Entry",
          systemImage: "exclamationmark.triangle",
          description: Text(error)
        )
      } else if let entry = store.journalEntry {
        VStack(spacing: 8) {
          Text(store.date, style: .date)
            .font(.headline)
          
          if let emotion = entry.emotion {
            Text(emotion)
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          
          if let topic = entry.topic {
            Text(topic)
              .font(.title3)
              .fontWeight(.semibold)
          }
        }
        .padding()
        
        if store.hasAudioAsset {
          VStack(spacing: 24) {
            RoundedRectangle(cornerRadius: 12)
              .fill(.quaternary)
              .frame(height: 80)
              .overlay {
                Image(systemName: "waveform")
                  .font(.largeTitle)
                  .foregroundStyle(.secondary)
              }
              .padding(.horizontal)
            
            Button {
              if store.isPlaying {
                store.send(.pauseButtonTapped)
              } else {
                store.send(.playButtonTapped)
              }
            } label: {
              Image(systemName: store.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            }
            .buttonStyle(.plain)
            
            if let transcript = entry.transcript, !transcript.isEmpty {
              VStack(alignment: .leading, spacing: 8) {
                Text("Transcript")
                  .font(.headline)
                
                ScrollView {
                  Text(transcript)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 200)
              }
              .padding()
              .background {
                RoundedRectangle(cornerRadius: 12)
                  .fill(.quaternary)
              }
              .padding(.horizontal)
            }
          }
        } else {
          ContentUnavailableView(
            "No Audio Recording",
            systemImage: "waveform.slash",
            description: Text("This journal entry doesn't have an audio recording.")
          )
        }
        
        Spacer()
        
        // Delete button
        if store.hasAudioAsset {
          Button(role: .destructive) {
            store.send(.deleteButtonTapped)
          } label: {
            Label("Delete Recording", systemImage: "trash")
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.bordered)
          .controlSize(.large)
          .padding()
        }
      }
    }
    .onAppear {
      store.send(.onAppear)
    }
    .onDisappear {
      store.send(.sheetDismissed)
    }
  }
}

extension AudioPlayerView {
  static func getJournalEntryAndAsset(_ date: Date, database: any DatabaseReader) throws -> (JournalEntry, JournalEntryAsset?) {
    let result: (JournalEntry, JournalEntryAsset?) = try database.read { db in
      try JournalEntry
        .where { $0.date.eq(date.startOfDay()) }
        .leftJoin(JournalEntryAsset.all) { $0.id.eq($1.assetID) }
        .fetchOne(db)!
    }
    
    return result
  }
}

#Preview {
  let _ = prepareDependencies {
    $0.defaultDatabase = try! appDatabase()
  }
  
  @Dependency(\.date.now) var now
  
  AudioPlayerView(
    store: Store(
      initialState: AudioPlayerFeature.State(
        date: now,
        currentSeekPosition: nil,
        isPlaying: false
      )
    ) {
      AudioPlayerFeature()
    }
  )
}

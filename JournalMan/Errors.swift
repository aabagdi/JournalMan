//
//  Errors.swift
//  JournalMan
//
//  Created by Aadit Bagdi on 8/30/25.
//

import Foundation

enum AudioProcessingError: Error {
  case bufferCreationFailed
  case invalidAudioFormat
  case insufficientSamples
  case conversionFailed
}

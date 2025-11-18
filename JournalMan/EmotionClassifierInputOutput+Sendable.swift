//
//  EmotionClassifierInputOutput+Sendable.swift
//  JournalMan
//
//  Created by Aadit Bagdi on 11/15/25.
//

import Foundation
import CoreML

extension EmotionClassifierInput: @unchecked Sendable { }
extension EmotionClassifierOutput: @unchecked Sendable { }

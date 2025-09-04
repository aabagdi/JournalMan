//
//  MLMultiArray+Sendable.swift
//  JournalMan
//
//  Created by Aadit Bagdi on 8/31/25.
//

import Foundation
import CoreML

extension MLMultiArray: @unchecked @retroactive Sendable { }

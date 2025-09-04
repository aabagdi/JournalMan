//
//  FileManagerClient.swift
//  JournalMan
//
//  Created by Aadit Bagdi on 9/1/25.
//

import Foundation
import Dependencies
import DependenciesMacros

@DependencyClient
struct FileManagerClient {
  var fileExists: @Sendable (URL) -> Bool = { _ in false }
  var removeItem: @Sendable (URL) async throws -> Void
  var contentsOfDirectory: @Sendable (URL) async throws -> [URL]
  var temporaryDirectory: @Sendable () -> URL = { URL(fileURLWithPath: NSTemporaryDirectory()) }
  var creationDate: @Sendable (URL) async throws -> Date?
}

extension FileManagerClient: TestDependencyKey {
  static let testValue = Self()
  
  static var previewValue: Self {
    Self(
      fileExists: { _ in true },
      removeItem: { _ in },
      contentsOfDirectory: { _ in [] },
      temporaryDirectory: { URL(fileURLWithPath: "/tmp") },
      creationDate: { _ in Date() }
    )
  }
}

extension DependencyValues {
  var fileManager: FileManagerClient {
    get { self[FileManagerClient.self] }
    set { self[FileManagerClient.self] = newValue }
  }
}

extension FileManagerClient: DependencyKey {
  static var liveValue: Self {
    return Self(
      fileExists: { url in
        FileManager.default.fileExists(atPath: url.path)
      },
      
      removeItem: { url in
        try FileManager.default.removeItem(at: url)
      },
      
      contentsOfDirectory: { url in
        try FileManager.default.contentsOfDirectory(
          at: url,
          includingPropertiesForKeys: nil,
          options: .skipsHiddenFiles
        )
      },
      
      temporaryDirectory: {
        FileManager.default.temporaryDirectory
      },
      
      creationDate: { url in
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        return attributes[.creationDate] as? Date
      }
    )
  }
}

extension FileManagerClient {
  func createTemporaryFileURL(withExtension ext: String, with uuid: UUID) -> URL {
    temporaryDirectory()
      .appendingPathComponent(uuid.uuidString)
      .appendingPathExtension(ext)
  }
}

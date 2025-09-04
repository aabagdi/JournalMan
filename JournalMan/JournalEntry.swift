//
//  JournalEntry.swift
//  JournalMan
//
//  Created by Aadit Bagdi on 8/22/25.
//

import Foundation
import SharingGRDB

@Table
struct JournalEntry: Identifiable {
  var id: UUID
  var date: Date
  var emotion: String?
  var topic: String?
  var transcript: String?
}

@Table
struct JournalEntryAsset: Hashable, Identifiable {
  @Column(primaryKey: true)
  let assetID: JournalEntry.ID
  var audioData: Data?
  var id: JournalEntry.ID { assetID }
}

func appDatabase() throws -> any DatabaseWriter {
  @Dependency(\.context) var context
  
  var configuration = Configuration()
  configuration.foreignKeysEnabled = true
  configuration.prepareDatabase { db in
#if DEBUG
    db.trace(options: .profile) {
      print("\($0.expandedDescription)")
    }
#endif
  }
  
  let database: any DatabaseWriter
  
  switch context {
  case .live:
    let path = URL.documentsDirectory.appending(component: "VisualManDB.sqlite").path()
    print("open \(path)")
    database = try DatabasePool(path: path, configuration: configuration)
  case .test, .preview:
    database = try DatabaseQueue(configuration: configuration)
  }
  
  var migrator = DatabaseMigrator()
  
#if DEBUG
  migrator.eraseDatabaseOnSchemaChange = true
#endif
  
  migrator.registerMigration("Create tables") { db in
    try #sql(
    """
      CREATE TABLE "JournalEntries" (
        "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
        "date" TEXT NOT NULL,
        "emotion" TEXT,
        "topic" TEXT,
        "transcript" TEXT
      )
    """
    )
    .execute(db)
    
    try #sql(
    """
      CREATE TABLE "JournalEntryAssets" (
        "assetID" TEXT PRIMARY KEY NOT NULL REFERENCES "JournalEntries"("id") ON DELETE CASCADE,
        "audioData" BLOB 
      ) STRICT
    """
    )
    .execute(db)
  }
  
  try migrator.migrate(database)
  
  return database
}

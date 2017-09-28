//
//  Migrations.swift
//  Doughnut
//
//  Created by Chris Dyer on 27/09/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Foundation
import GRDB

class LibraryMigrations {
  static func migrate(db: DatabaseQueue) throws {
    var migrator = DatabaseMigrator()
    
    migrator.registerMigration("v1") { db in
      try db.create(table: "podcasts") { t in
        t.column("id", .integer).primaryKey()
        t.column("title", .text).notNull()
        t.column("path", .text).notNull()
        t.column("feed", .text)
        t.column("description", .text)
        t.column("link", .text)
        t.column("author", .text)
        t.column("language", .text)
        t.column("copyright", .text)
        t.column("pub_date", .datetime)
        t.column("image_url", .text)
        t.column("last_parsed", .datetime)
        t.column("subscribed_at", .datetime)
        t.column("download_new", .boolean).notNull().defaults(to: true)
        t.column("delete_played", .boolean).notNull().defaults(to: false)
      }
      
      try db.create(table: "episodes", body: { t in
        t.column("id", .integer).primaryKey()
        t.column("title", .text).notNull()
        t.column("description", .text)
        t.column("guid", .text)
        t.column("pub_date", .datetime)
        t.column("link", .text)
        t.column("enclosure_url", .text)
        t.column("enclosure_size", .integer)
        t.column("favourite", .boolean).notNull().defaults(to: false)
        t.column("downloaded", .boolean).notNull().defaults(to: false)
        t.column("played", .boolean).notNull().defaults(to: false)
        t.column("playPosition", .integer).notNull().defaults(to: 0)
        t.column("duration", .integer)
        t.column("created_at", .datetime)
      })
    }
    
    try migrator.migrate(db)
  }
}

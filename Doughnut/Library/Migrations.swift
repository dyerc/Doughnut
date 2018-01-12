/*
 * Doughnut Podcast Client
 * Copyright (C) 2017 Chris Dyer
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

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
        t.column("image", .blob)
        t.column("image_url", .text)
        t.column("last_parsed", .datetime)
        t.column("subscribed_at", .datetime)
        t.column("download_new", .boolean).notNull().defaults(to: true)
        t.column("delete_played", .boolean).notNull().defaults(to: false)
      }
      
      try db.create(table: "episodes", body: { t in
        t.column("id", .integer).primaryKey()
        t.column("podcast_id", .integer).references("podcasts", onDelete: .cascade)
        t.column("title", .text).notNull()
        t.column("description", .text)
        t.column("guid", .text)
        t.column("pub_date", .datetime)
        t.column("link", .text)
        t.column("enclosure_url", .text)
        t.column("enclosure_size", .integer)
        t.column("file_name", .text)
        t.column("favourite", .boolean).notNull().defaults(to: false)
        t.column("downloaded", .boolean).notNull().defaults(to: false)
        t.column("played", .boolean).notNull().defaults(to: false)
        t.column("play_position", .integer).notNull().defaults(to: 0)
        t.column("duration", .integer)
      })
    }
    
    migrator.registerMigration("v2") { db in
      try db.alter(table: "podcasts", body: { t in
        t.add(column: "reload_frequency", .integer).notNull().defaults(to: 0)
      })
    }
    
    migrator.registerMigration("v3") { db in
      try db.alter(table: "podcasts", body: { t in
        t.add(column: "auto_download", .boolean).notNull().defaults(to: false)
      })
    }
    
    try migrator.migrate(db)
  }
}

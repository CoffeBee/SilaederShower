//
//  TimestampConference.swift
//
//
//  Created by Ivan Podvorniy on 02.10.2022.
//

import Fluent

struct TimestampConference: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Conference.schema)
            .field("created_at", .datetime, .required)
            .update()
            
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Conference.schema).deleteField("created_at").update()
    }
}


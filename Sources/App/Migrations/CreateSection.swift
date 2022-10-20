//
//  CreateConference.swift
//
//
//  Created by Ivan Podvorniy on 02.10.2022.
//

import Fluent

struct CreateSection: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Section.schema)
            .field("id", .uuid)
            .unique(on: "id")
            .field("name", .string, .required)
            .field("next_id", .uuid, .references(Section.schema, "id"))
            .field("conference_id", .uuid, .required, .references(Conference.schema, "id"))
            .create()
            
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Section.schema).delete()
    }
}


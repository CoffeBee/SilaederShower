//
//  CreateConference.swift
//
//
//  Created by Ivan Podvorniy on 02.10.2022.
//

import Fluent

struct CreateConference: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Conference.schema)
            .field("id", .uuid)
            .unique(on: "id")
            .field("title", .string, .required)
            .field("detail", .string, .required)
            .field("secret_hash", .string, .required)
            .create()
            
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Conference.schema).delete()
    }
}


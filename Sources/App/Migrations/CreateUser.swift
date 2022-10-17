//
//  CreateUser.swift
//
//
//  Created by Ivan Podvorniy on 02.10.2022.
//

import Fluent

struct CreateUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(User.schema)
            .field("id", .uuid)
            .unique(on: "id")
            .field("username", .string, .required)
            .field("name", .string, .required)
            .unique(on: "username")
            .field("password_hash", .string, .required)
            .field("is_admin", .bool, .required)
            .create()
            .flatMap {
                database.schema(Token.schema)
                    .field("id", .uuid)
                    .field("user_id", .uuid, .references(User.schema, "id"))
                    .field("value", .string, .required)
                    .unique(on: "value")
                    .field("source", .int, .required)
                    .field("created_at", .datetime, .required)
                    .field("expires_at", .datetime)
                    .create()
            }
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Token.schema).delete().flatMap { database.schema(User.schema).delete() }
    }
}


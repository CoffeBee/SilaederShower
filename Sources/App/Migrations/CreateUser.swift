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
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(User.schema).delete()
    }
}


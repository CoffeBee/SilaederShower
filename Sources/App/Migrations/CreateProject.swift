//
//  CreateProject.swift
//  
//
//  Created by Ivan Podvorniy on 20.10.2022.
//

import Fluent

struct CreateProject: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Project.schema)
            .field("id", .uuid)
            .unique(on: "id")
            .field("frgn_id", .int, .required)
            .field("section_id", .uuid, .required, .references(Section.schema, "id"))
            .field("next_id", .uuid, .references(Project.schema, "id"))
            .create().flatMap {
                database.schema(Section.schema)
                    .field("first_id", .uuid, .references(Project.schema, "id"))
                    .update()
            }
            
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Section.schema).deleteField("first_id").update().flatMap {
            database.schema(Project.schema).delete()
        }
    }
}


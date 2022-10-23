//
//  AddTimestampsProject.swift
//
//
//  Created by Ivan Podvorniy on 20.10.2022.
//

import Fluent

struct AddTimestampsProject: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Project.schema)
            .field("started_at", .datetime)
            .field("stopped_at", .datetime)
            .update()
        
            
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Project.schema)
            .deleteField("started_at")
            .deleteField("stopped_at")
            .update()
    }
}


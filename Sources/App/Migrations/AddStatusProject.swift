//
//  AddStatusProject.swift
//
//
//  Created by Ivan Podvorniy on 20.10.2022.
//

import Fluent

struct AddStatusProject: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.enum("prj_status")
            .case("none")
            .case("active")
            .case("done")
            .create().flatMap { statusType in
                database.schema(Project.schema)
                    .field("status", statusType)
                    .update()
            }
        
            
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Project.schema)
            .deleteField("status")
            .update().flatMap {
                database.enum("prj_status").delete()
            }
    }
}


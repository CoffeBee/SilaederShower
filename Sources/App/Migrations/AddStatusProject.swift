//
//  AddStatusProject.swift
//
//
//  Created by Ivan Podvorniy on 20.10.2022.
//

import Fluent

struct AddStatusProject: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.enum("p_status")
            .case("none")
            .case("active")
            .case("done")
            .create().flatMap { statusType in
                database.schema(Project.schema)
                    .field("status", statusType)
                    .update()
            }.flatMap {
                Project.query(on: database).all().flatMap {
                    $0.map {
                        $0.status = .none
                        return $0.save(on: database)
                    }.flatten(on: database.eventLoop)
                }
            }
        
            
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Project.schema)
            .deleteField("p_status")
            .update().flatMap {
                database.enum("prj_status").delete()
            }
    }
}


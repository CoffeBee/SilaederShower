//
//  Section.swift
//
//
//  Created by Ivan Podvorniy on 02.10.2022.
//

import Fluent
import Vapor

final class Section: Model {
    
    struct Public {
        let id: UUID
        let name: String
    }
    
    static let schema = "sections"
    
    @ID(key: "id")
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @OptionalParent(key: "next_id")
    var nextSection: Section?
    
    @Parent(key: "conference_id")
    var conference: Conference
    
    init() {}
    
    init(id: UUID? = nil, conferenceID: Conference.IDValue) throws {
        self.id = id
        self.name = "Новая секция"
        self.$conference.id = conferenceID
    }
    
}

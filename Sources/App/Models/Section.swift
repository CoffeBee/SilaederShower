//
//  Section.swift
//
//
//  Created by Ivan Podvorniy on 02.10.2022.
//

import Fluent
import Vapor
import Foundation

final class Section: Model {
    
    struct Public: Content {
        let id: UUID
        let name: String
        let projects: [Project.Public]
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
    
    @OptionalParent(key: "first_id")
    var firstProject: Project?
    
    init() {}
    
    init(id: UUID? = nil, conferenceID: Conference.IDValue) throws {
        self.id = id
        self.name = "Новая секция"
        self.$conference.id = conferenceID
    }
    
}

final class Project: Model {
    
    static let schema = "projects"
    
    struct Public: Content {
        let id: UUID
        let frgnID: Int
        
    }
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "frgn_id")
    var frgnID: Int
    
    @OptionalParent(key: "next_id")
    var nextProject: Project?
    
    @Parent(key: "section_id")
    var section: Section
    
    init() {}
    
    init(id: UUID? = nil, frgnID: Int, sectionID: Section.IDValue) {
        self.id = id
        self.frgnID = frgnID
        self.$section.id = sectionID
    }
}

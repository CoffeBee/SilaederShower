//
//  Section.swift
//
//
//  Created by Ivan Podvorniy on 02.10.2022.
//

import Fluent
import Vapor
import Foundation

enum ProjectStatus: String, Codable {
    case none, active, done
}

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
        init (project: Project) {
            self.id = project.id
            self.frgnID = project.frgnID
            self.status = project.status
            self.stoppedAt = project.stoppedAt?.timeIntervalSince1970
            self.startedAt = project.startedAt?.timeIntervalSince1970
        }
        let id: UUID?
        let frgnID: Int
        let status: ProjectStatus
        let startedAt: Double?
        let stoppedAt: Double?
        
    }
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "frgn_id")
    var frgnID: Int
    
    @OptionalParent(key: "next_id")
    var nextProject: Project?
    
    @Parent(key: "section_id")
    var section: Section
    
    @Enum(key: "status")
    var status: ProjectStatus
    
    @Timestamp(key: "started_at", on: .none)
    var startedAt: Date?
    
    @Timestamp(key: "stopped_at", on: .none)
    var stoppedAt: Date?
    
    init() {}
    
    init(id: UUID? = nil, frgnID: Int, sectionID: Section.IDValue) {
        self.id = id
        self.frgnID = frgnID
        self.$section.id = sectionID
        self.status = .none
    }
}

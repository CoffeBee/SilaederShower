//
//  Conference.swift
//
//
//  Created by Ivan Podvorniy on 02.10.2022.
//

import Fluent
import Vapor

final class Conference: Model {
    struct Public: Content {
        let id: UUID
        let title: String
        let selected: Bool
    }
    
    static let schema = "conferences"
    
    @ID(key: "id")
    var id: UUID?
    
    @Field(key: "title")
    var title: String
    
    @Field(key: "detail")
    var detail: String
    
    @Field(key: "secret_hash")
    var secretHash: String
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @OptionalParent(key: "first_id")
    var firstSection: Section?
    
    init() {}
    
    init(id: UUID? = nil, new: Bool) throws {
        self.id = id
        self.title = "Очередная конференция"
        self.detail = "Описание очередной конференции"
        self.secretHash = try Conference.genSecretHash()
    }
    
    static private func genSecretHash() throws -> String {
        return try Bcrypt.hash([UInt8].random(count: 16).base64)
    }
}

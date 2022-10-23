//
//  User.swift
//
//
//  Created by Ivan Podvorniy on 02.10.2022.
//

import Fluent
import Vapor
import Leaf


final class User: Model {
    struct Public: Content {
        let username: String
        let id: UUID
        let name: String
    }
    
    static let schema = "users"
    
    @ID(key: "id")
    var id: UUID?
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "password_hash")
    var passwordHash: String
    
    @Field(key: "is_admin")
    var isAdmin: Bool
    
    init() {}
    
    init(id: UUID? = nil, username: String, name: String, passwordHash: String) {
        self.id = id
        self.name = name
        self.username = username
        self.passwordHash = passwordHash
        self.isAdmin = false
        
    }
}

struct UserSignup: Content {
    let username: String
    let password: String
    let name: String
}


extension User {
    static func create(from userSignup: UserSignup) throws -> User {
        User(username: userSignup.username, name: userSignup.name, passwordHash: try Bcrypt.hash(userSignup.password))
    }
    
    func asPublic() throws -> Public {
        Public(username: self.username,
               id: try self.requireID(),
               name: self.name)
    }
}

extension User: SessionAuthenticatable {
    typealias SessionID = UUID

    var sessionID: SessionID { self.id! }
}

struct UserSessionAuthenticator: SessionAuthenticator {
    typealias User = App.User
    

    
    func authenticate(sessionID: User.SessionID, for req: Request) -> EventLoopFuture<Void> {
        User.find(sessionID, on: req.db).map { user  in
            if let user = user {
                req.auth.login(user)
            }
        }
    }
}

struct UserCredentialsAuthenticator: CredentialsAuthenticator {
    
    struct Input: Content {
        let username: String
        let password: String
    }

    typealias Credentials = Input

    func authenticate(credentials: Credentials, for req: Request) -> EventLoopFuture<Void> {
        User.query(on: req.db)
            .filter(\.$username == credentials.username)
            .first()
            .map {
                do {
                    if let user = $0, try Bcrypt.verify(credentials.password, created: user.passwordHash) {
                        req.auth.login(user)
                    }
                }
                catch {
                    // do nothing...
                }
            }
    }
}

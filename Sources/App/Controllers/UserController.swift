//
//  UserController.swift
//
//
//  Created by Ivan Podvorniy on 02.10.2022.
//

import Vapor
import Fluent

struct UserAuth: Content {
    let login: String
    let password: String
}

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let usersRoute = routes.grouped("users")
        
        usersRoute.get("login", use: loginGet)
        usersRoute.post("login", use: loginPost)
    }
    
    
    fileprivate func loginGet(req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("reg", ["error": false])
    }
   
    
    fileprivate func loginPost(req: Request) throws -> EventLoopFuture<View> {
        let authForm = try req.content.decode(UserAuth.self)
        return User.query(on: req.db).filter(\.$username == authForm.login).first().flatMapThrowing { userOptional in
            if let user = userOptional {
                if try Bcrypt.verify(authForm.password, created: user.passwordHash) {
                    throw Abort.redirect(to: "/cf")
                }
                return req.view.render("reg", ["error": true])
            }
            return req.view.render("reg", ["error": true])
            
        }.flatMap { $0 }
    }
    
}


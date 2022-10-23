//
//  UserController.swift
//
//
//  Created by Ivan Podvorniy on 02.10.2022.
//

import Vapor
import Fluent
import AsyncHTTPClient

struct Pin: Content {
    let code: String
}

struct UserController: RouteCollection {
    
    let app: Application
    
    init(app: Application) {
        self.app = app
    }
    
    func boot(routes: RoutesBuilder) throws {
        let session = routes.grouped([
            SessionsMiddleware(session: self.app.sessions.driver),
                UserSessionAuthenticator(),
                UserCredentialsAuthenticator(),
            ])
        routes.get("login", use: loginGet)
        routes.get("guest", use: guestGet)
        session.post("login", use: loginPost)
        routes.get("video", ":pb", use: video)
        session.post("guest", use: guestPost)
        session.get { req -> Response in
            guard let _ = req.auth.get(User.self) else {
                return req.redirect(to: "/login")
            }
            return req.redirect(to: "/cf")

        }
    }
    
    
    fileprivate func loginGet(req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("reg", ["error": false])
    }
    
    fileprivate func guestGet(req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("part", ["error": false])
    }
    
    fileprivate func guestPost(req: Request) throws -> EventLoopFuture<Response> {
        let code = try req.content.decode(Pin.self).code
        return Conference.query(on: req.db).filter(\.$secretHash == code).first().flatMap { confOpt in
            guard let conf = confOpt else {
                return req.view.render("part", ["error": false]).flatMapThrowing { $0.encodeResponse(for: req) }.flatMap { $0 }
            }
            return User.query(on: req.db).first().unwrap(or: Abort(.notFound)).flatMap { user  in
                req.auth.login(user)
                req.session.authenticate(user)
                return req.eventLoop.makeSucceededFuture(req.redirect(to: "/cf/" + conf.id!.uuidString))
            }
            
        }
       
    }
   
    
    fileprivate func loginPost(req: Request) throws -> EventLoopFuture<Response> {
        
        guard let user = req.auth.get(User.self) else {
            return req.view.render("reg", ["error": true]).flatMapThrowing { $0.encodeResponse(for: req) }.flatMap { $0 }
       }
        req.session.authenticate(user)
        return req.eventLoop.makeSucceededFuture(req.redirect(to: "/cf"))
    }
    
    
    fileprivate func video(req: Request) throws -> EventLoopFuture<View> {
        let pb = req.parameters.get("pb")!
        return req.view.render("video", ["pb" : pb])
    }
    
}

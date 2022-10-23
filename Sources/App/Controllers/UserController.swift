//
//  UserController.swift
//
//
//  Created by Ivan Podvorniy on 02.10.2022.
//

import Vapor
import Fluent
import AsyncHTTPClient


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
        session.post("login", use: loginPost)
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
   
    
    fileprivate func loginPost(req: Request) throws -> EventLoopFuture<Response> {
        
        guard let user = req.auth.get(User.self) else {
            return req.view.render("reg", ["error": true]).flatMapThrowing { $0.encodeResponse(for: req) }.flatMap { $0 }
       }
        req.session.authenticate(user)
        return req.eventLoop.makeSucceededFuture(req.redirect(to: "/cf"))
    }
    
}

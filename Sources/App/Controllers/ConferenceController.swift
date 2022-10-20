//
//  ConferenceController.swift
//
//
//  Created by Ivan Podvorniy on 02.10.2022.
//

import Vapor
import Fluent



struct ConfInformation: Codable {
    let confs: [Conference.Public]
    let title: String
    let detail: String
    let confID: UUID
}

struct ChangeTitle: Content {
    let title: String
}

struct ChangeDetail: Content {
    let detail: String
}

struct ConferenceController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let conferencesRoute = routes.grouped("cf")
        
        conferencesRoute.get("", use: emptryConf)
        conferencesRoute.post("add", use: addConf)
        conferencesRoute.get(":id", use: viewConf)
        conferencesRoute.post("title", ":id", use: titleChange)
        conferencesRoute.post("detail", ":id", use: detailChange)
    }
    
    
    fileprivate func getConfs(req: Request, selected: UUID?) -> EventLoopFuture<[Conference.Public]> {
        return Conference.query(on: req.db).all().flatMapThrowing { confs in
            try confs.map { conf in
                
                try Conference.Public(id: conf.requireID(), title: conf.title, selected: conf.requireID() == selected)
                
            }
        }
    }
    
    fileprivate func emptryConf(req: Request) throws -> EventLoopFuture<View> {
        return Conference.query(on: req.db).sort(\.$createdAt).first().flatMapThrowing { confOptional in
            if let conf = confOptional {
                throw try Abort.redirect(to: "/cf/" + conf.requireID().uuidString)
            }
            return self.getConfs(req: req, selected: nil).flatMap { confs in
                req.view.render("home", ["confs": confs])
            }
            
        }.flatMap { $0 }
    }
    
    fileprivate func viewConf(req: Request) throws -> EventLoopFuture<View> {
        let confStr = req.parameters.get("id")!
        guard let confID = UUID(uuidString: confStr) else {
            throw Abort.redirect(to: "/cf")
        }
        return Conference.find(confID, on: req.db).unwrap(or: Abort.redirect(to: "/cf")).flatMap { conf in
            return self.getConfs(req: req, selected: confID).flatMap { confs in
                req.view.render("conf", ConfInformation(confs: confs, title: conf.title, detail: conf.detail, confID: confID))
            }
        }
    }
    
    fileprivate func titleChange(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let confStr = req.parameters.get("id")!
        guard let confID = UUID(uuidString: confStr) else {
            throw Abort(.badRequest)
        }
        let title = try req.content.decode(ChangeTitle.self).title
        return Conference.find(confID, on: req.db).unwrap(or: Abort(.badRequest)).flatMap { conf in
            conf.title = title
            return conf.save(on: req.db).map { .ok }
        }
    }
    
    fileprivate func detailChange(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let confStr = req.parameters.get("id")!
        guard let confID = UUID(uuidString: confStr) else {
            throw Abort(.badRequest)
        }
        let detail = try req.content.decode(ChangeDetail.self).detail
        return Conference.find(confID, on: req.db).unwrap(or: Abort(.badRequest)).flatMap { conf in
            conf.detail = detail
            return conf.save(on: req.db).map { .ok }
        }
    }
    
    fileprivate func addConf(req: Request) throws -> EventLoopFuture<Response> {
        let newConf = try Conference(new: true)
        return newConf.save(on: req.db).map {
            return req.redirect(to: "/cf")
        }
    }
    
}


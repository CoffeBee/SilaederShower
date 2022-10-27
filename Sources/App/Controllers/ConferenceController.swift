//
//  ConferenceController.swift
//
//
//  Created by Ivan Podvorniy on 02.10.2022.
//

import Vapor
import Fluent
import Leaf



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

struct ChangeName: Content {
    let name: String
}

struct AddProject: Content {
    let id: Int
    let after: Conference.IDValue?
}

struct ChangePresentation: Content {
    let newID: UUID
}

struct ChangeSlide: Content {
    let slide: Int
}

struct ChangePresentationMessage: Content {
    struct ChangePresentation: Content {
        let newID: Int
    }
    let data: ChangePresentation
    var type = "presentation"
}

struct ChangeSlideMessage: Content {
    let data: ChangeSlide
    var type = "slide"
}

struct ConferenceController: RouteCollection {
    
    let app: Application
    let shower = ShowerStorage()
    
    init (app: Application) {
        self.app = app
    }
    
    func boot(routes: RoutesBuilder) throws {
        let session = routes.grouped([
            SessionsMiddleware(session: self.app.sessions.driver),
                UserSessionAuthenticator(),
                UserCredentialsAuthenticator(),
            ])
        let conferencesRoute = session.grouped("cf")
        
        conferencesRoute.get("", use: emptryConf)
        conferencesRoute.post("add", use: addConf)
        conferencesRoute.get(":id", use: viewConf)
        conferencesRoute.post("title", ":id", use: titleChange)
        conferencesRoute.post("detail", ":id", use: detailChange)
        conferencesRoute.post("section", ":id", use: sectionAdd)
        conferencesRoute.get("section", ":id", use: sections)
        routes.get("cf", "view", ":id", use: showerConf)
        conferencesRoute.get("admin", ":id", use: adminConf)
        routes.webSocket("cf", "ws", ":id", onUpgrade: wsConf)
        let sectionsRoute = conferencesRoute.grouped("sc")
        
        sectionsRoute.post("name", ":id", use: changeName)
        sectionsRoute.post("project", ":id", use: addProject)
        
        let projectsRoute = conferencesRoute.grouped("pr")
        projectsRoute.post("del", ":id", use: delProject)
        
        let showerRoute = conferencesRoute.grouped("sh")
        showerRoute.post("prs", ":id", use: changePresentation)
        showerRoute.post("stop", ":id", use: stopPresentation)
        showerRoute.post("slide", ":id", use: changeSlide)
        
        
    }
    
    
    fileprivate func getConfs(req: Request, selected: UUID?) -> EventLoopFuture<[Conference.Public]> {
        return Conference.query(on: req.db).sort(\.$createdAt).all().flatMapThrowing { confs in
            
            try confs.reversed().map { conf in
                
                try Conference.Public(id: conf.requireID(), title: conf.title, selected: conf.requireID() == selected)
                
            }
        }
    }
    
    fileprivate func emptryConf(req: Request) throws -> EventLoopFuture<View> {
        guard let _ = req.auth.get(User.self) else {
            throw Abort.redirect(to: "/login")
        }
        return Conference.query(on: req.db).sort(\.$createdAt).first().flatMapThrowing { confOptional in
            if let conf = confOptional {
                throw try Abort.redirect(to: "/cf/" + conf.requireID().uuidString)
            }
            return self.getConfs(req: req, selected: nil).flatMap { confs in
                req.view.render("home", ["confs": confs])
            }
            
        }.flatMap { $0 }
    }
    
    fileprivate func getProjects(projects: [Project], firstIDOpt: Project.IDValue?) throws -> [Project.Public] {
        guard var firstID = firstIDOpt else {
            return []
        }
        
        var projectsIDMap = [Project.IDValue: Project]()
        for project in projects {
            try projectsIDMap[project.requireID()] = project
        }
        var result = [Project.Public]()
        while let nextID = projectsIDMap[firstID]?.$nextProject.id {
            result.append(Project.Public(project: projectsIDMap[firstID]!))
            firstID = nextID
        }
        result.append(Project.Public(project: projectsIDMap[firstID]!))
        return result
    }
    
    fileprivate func getSectionsPublics(req: Request, sections: [Section], firstIDOpt: Section.IDValue?) throws -> EventLoopFuture<[Section.Public]> {
        guard var firstID = firstIDOpt else {
            return req.eventLoop.makeSucceededFuture([])
        }
        
        var sectionIDMap = [Section.IDValue: Section]()
        for section in sections {
            try sectionIDMap[section.requireID()] = section
        }
        var order = [UUID]()
        while let nextID = sectionIDMap[firstID]?.$nextSection.id {
            order.append(firstID)
            firstID = nextID
        }
        order.append(firstID)
        var result = [EventLoopFuture<Section.Public>]()
        for sectionID in order {
            result.append(Project.query(on: req.db).filter(\.$section.$id == sectionID).all().flatMapThrowing { projects in
                Section.Public(id: sectionID, name: sectionIDMap[sectionID]!.name, projects: try self.getProjects(projects: projects, firstIDOpt: sectionIDMap[sectionID]!.$firstProject.id))
            })
        }
        return result.flatten(on: req.eventLoop)
    }
    
    fileprivate func viewConf(req: Request) throws -> EventLoopFuture<View> {
        guard let _ = req.auth.get(User.self) else {
            throw Abort.redirect(to: "/login")
        }
        let confStr = req.parameters.get("id")!
        guard let confID = UUID(uuidString: confStr) else {
            throw Abort.redirect(to: "/cf")
        }
        return Conference.find(confID, on: req.db).unwrap(or: Abort.redirect(to: "/cf")).flatMap { conf in
            return self.getConfs(req: req, selected: confID).flatMap { confs in
                return Section.query(on: req.db).filter(\.$conference.$id == confID).all().flatMapThrowing { sections in
                    req.view.render("conf", ConfInformation(confs: confs, title: conf.title, detail: conf.detail, confID: confID))
                }.flatMap { $0 }
            }
        }
    }
    
    fileprivate func showerConf(req: Request) throws -> EventLoopFuture<View> {
        let confStr = req.parameters.get("id")!
        guard let confID = UUID(uuidString: confStr) else {
            throw Abort.redirect(to: "/cf")
        }
        return req.view.render("shower")
    }
    
    fileprivate func adminConf(req: Request) throws -> EventLoopFuture<View> {
        guard let _ = req.auth.get(User.self) else {
            throw Abort.redirect(to: "/login")
        }
        let confStr = req.parameters.get("id")!
        guard let confID = UUID(uuidString: confStr) else {
            throw Abort.redirect(to: "/cf")
        }
        return req.view.render("admin", ["confID" : confID])
    }
    
    fileprivate func wsConf(req: Request, ws: WebSocket) {
        let confStr = req.parameters.get("id")!
        if let confID = UUID(uuidString: confStr) {
            self.shower.addClient(confID: confID, ws: ws)
        }
        
    }
    
    fileprivate func titleChange(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        guard let _ = req.auth.get(User.self) else {
            throw Abort.redirect(to: "/login")
        }
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
        guard let _ = req.auth.get(User.self) else {
            throw Abort.redirect(to: "/login")
        }
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
        guard let _ = req.auth.get(User.self) else {
            throw Abort.redirect(to: "/login")
        }
        let newConf = try Conference(new: true)
        return newConf.save(on: req.db).map {
            return req.redirect(to: "/cf")
        }
    }
    
    fileprivate func sectionAdd(req: Request) throws -> EventLoopFuture<Section.Public> {
        guard let _ = req.auth.get(User.self) else {
            throw Abort.redirect(to: "/login")
        }
        let confStr = req.parameters.get("id")!
        guard let confID = UUID(uuidString: confStr) else {
            throw Abort(.badRequest)
        }
        return Conference.find(confID, on: req.db).unwrap(or: Abort(.notFound)).flatMap { conf in
            return Section.query(on: req.db).filter(\.$conference.$id == confID).filter(\.$nextSection.$id == nil).first().flatMapThrowing { lastSectionOptional in
                let newSection = try Section(conferenceID: confID)
                return newSection.save(on: req.db).flatMapThrowing {
                    Section.Public(id: try newSection.requireID(), name: newSection.name, projects: [])
                }.flatMap { sectionPublic in
                    if let lastSection = lastSectionOptional {
                        lastSection.$nextSection.id = sectionPublic.id
                        return lastSection.save(on: req.db).map { sectionPublic }
                    }
                    conf.$firstSection.id = sectionPublic.id
                    return conf.save(on: req.db).map { sectionPublic }
                }
            }.flatMap { $0 }
        }
        
    }
    
    fileprivate func sections(req: Request) throws -> EventLoopFuture<[Section.Public]> {
        guard let _ = req.auth.get(User.self) else {
            throw Abort.redirect(to: "/login")
        }
        let confStr = req.parameters.get("id")!
        guard let confID = UUID(uuidString: confStr) else {
            throw Abort(.badRequest)
        }
        return Conference.find(confID, on: req.db).unwrap(or: Abort(.notFound)).flatMap { conf in
            return Section.query(on: req.db).filter(\.$conference.$id == confID).all().flatMapThrowing { sections in
                try self.getSectionsPublics(req: req, sections: sections, firstIDOpt: conf.$firstSection.id)
            }.flatMap { $0 }
        }
    }
    
    fileprivate func changeName(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        guard let _ = req.auth.get(User.self) else {
            throw Abort.redirect(to: "/login")
        }
        let sectionStr = req.parameters.get("id")!
        guard let sectionID = UUID(uuidString: sectionStr) else {
            throw Abort(.badRequest)
        }
        let name = try req.content.decode(ChangeName.self).name
        return Section.find(sectionID, on: req.db).unwrap(or: Abort(.notFound)).flatMap { section in
            section.name = name
            return section.save(on: req.db).map { .ok }
        }
    }
    
    fileprivate func addProject(req: Request) throws -> EventLoopFuture<Project.Public> {
        guard let _ = req.auth.get(User.self) else {
            throw Abort.redirect(to: "/login")
        }
        let sectionStr = req.parameters.get("id")!
        guard let sectionID = UUID(uuidString: sectionStr) else {
            throw Abort(.badRequest)
        }
        let proj_id = try req.content.decode(AddProject.self).id
        let before_id = try req.content.decode(AddProject.self).after
        
        return Section.find(sectionID, on: req.db).unwrap(or: Abort(.notFound)).flatMap { section in
            if before_id == nil {
                let newProj = Project(frgnID: proj_id, sectionID: sectionID)
                newProj.$nextProject.id = section.$firstProject.id
                return newProj.save(on: req.db).flatMapThrowing {
                    section.$firstProject.id = try newProj.requireID()
                    return section.save(on: req.db).map { Project.Public(project: newProj) }
                }.flatMap { $0 }
                
            }
            return Project.find(before_id, on: req.db).unwrap(or: Abort(.notFound)).flatMap { project in
                let newProj = Project(frgnID: proj_id, sectionID: sectionID)
                newProj.$nextProject.id = project.$nextProject.id
                return newProj.save(on: req.db).flatMapThrowing {
                    project.$nextProject.id = try newProj.requireID()
                    return project.save(on: req.db).map { Project.Public(project: newProj) }
                }.flatMap { $0 }
            }
            
        }
    }
    
    fileprivate func delProject(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        guard let _ = req.auth.get(User.self) else {
            throw Abort.redirect(to: "/login")
        }
        let projectStr = req.parameters.get("id")!
        guard let projectID = UUID(uuidString: projectStr) else {
            throw Abort(.badRequest)
        }
        return Project.find(projectID, on: req.db).unwrap(or: Abort(.notFound)).flatMap { project in
            return Project.query(on: req.db).filter(\.$nextProject.$id == projectID).first().flatMap { prevOpt in
                if let prev = prevOpt {
                    prev.$nextProject.id = project.$nextProject.id
                    return prev.save(on: req.db)
                }
                return Section.find(project.$section.id, on: req.db).unwrap(or: Abort(.internalServerError)).flatMap { section in
                    section.$firstProject.id = project.$nextProject.id
                    return section.save(on: req.db)
                }
            }.flatMap {
                project.delete(on: req.db).map { .ok }
            }
        }
    }
    
    fileprivate func changePresentation(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        guard let _ = req.auth.get(User.self) else {
            throw Abort.redirect(to: "/login")
        }
        let confStr = req.parameters.get("id")!
        guard let confID = UUID(uuidString: confStr) else {
            throw Abort(.badRequest)
        }
        let prID = try req.content.decode(ChangePresentation.self).newID
        return Project.find(prID, on: req.db).unwrap(or: Abort(.notFound)).flatMapThrowing { project in
            try self.shower.sendMessage(confID: confID,
                                        message: ChangePresentationMessage(data:
                                                                            ChangePresentationMessage.ChangePresentation(newID: project.frgnID)))
            return Project.query(on: req.db).filter(\.$status == .active).all().flatMap { active in
                return active.map { active_project in
                    active_project.status = .done
                    active_project.stoppedAt = Date()
                    return active_project.save(on: req.db)
                }.flatten(on: req.eventLoop)
            }.flatMap {
                project.status = .active
                project.startedAt = Date()
                project.stoppedAt = nil
                return project.save(on: req.db)
            }.map { .ok }
        }.flatMap { $0 }
        
    }
    
    fileprivate func stopPresentation(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        guard let _ = req.auth.get(User.self) else {
            throw Abort.redirect(to: "/login")
        }
        let confStr = req.parameters.get("id")!
        guard let confID = UUID(uuidString: confStr) else {
            throw Abort(.badRequest)
        }
        let prID = try req.content.decode(ChangePresentation.self).newID
        return Project.find(prID, on: req.db).unwrap(or: Abort(.notFound)).flatMapThrowing { project in
            try self.shower.sendMessage(confID: confID,
                                        message: ChangePresentationMessage(data:
                                                                            ChangePresentationMessage.ChangePresentation(newID: -1)))
            return Project.query(on: req.db).filter(\.$status == .active).all().flatMap { active in
                return active.map { active_project in
                    active_project.status = .done
                    active_project.stoppedAt = Date()
                    return active_project.save(on: req.db)
                }.flatten(on: req.eventLoop)
            }.map { .ok }
        }.flatMap { $0 }
        
    }
    
    fileprivate func changeSlide(req: Request) throws -> HTTPStatus {
        guard let _ = req.auth.get(User.self) else {
            throw Abort.redirect(to: "/login")
        }
        let confStr = req.parameters.get("id")!
        guard let confID = UUID(uuidString: confStr) else {
            throw Abort(.badRequest)
        }
        let event = try req.content.decode(ChangeSlide.self)
        try self.shower.sendMessage(confID: confID, message: ChangeSlideMessage(data: event))
        return .ok
    }
}


class ShowerStorage {
    var wsStorage = [Conference.IDValue: [WebSocket]]()
    let jsonEncoder = JSONEncoder()
    init() {
    }
    
    func addClient(confID: Conference.IDValue, ws: WebSocket) {
        if self.wsStorage[confID] == nil {
            self.wsStorage[confID] = [WebSocket]()
        }
        self.wsStorage[confID]?.append(ws)
    }
    
    func sendMessage<T: Content>(confID: UUID, message: T) throws {
        if let wss = wsStorage[confID] {
            for ws in wss {
                let messageData = try jsonEncoder.encode(message)
                let messageJSON = String(data: messageData, encoding: .utf8) ?? "{}"
                ws.send(messageJSON)
            }
        }
    }
    
}

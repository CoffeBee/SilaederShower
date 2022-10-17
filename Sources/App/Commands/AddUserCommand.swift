//
//  AddUserCommand.swift
//
//
//  Created by Ivan Podvorniy on 04.10.2022.
//

import Vapor

struct AddUserCommand: Command {
    struct Signature: CommandSignature {
        
    }

    var help: String {
        "Add new user in database"
    }

    func run(using context: CommandContext, signature: Signature) throws {
        while (true) {
            let username = context.console.ask("Type new username. STOP^ if want stop")
            if (username == "STOP^") {
                context.console.print("GoodBye, have a nice day😃")
                break
            }
            let password = context.console.ask("Type user password 🤫")
            let name = context.console.ask("Type user name 🎫")
            let user = try User.create(from: UserSignup(username: username, password: password, name: name))
            let isAdmin = context.console.confirm("Does new user admin?");
            user.isAdmin = isAdmin
            try user.save(on: context.application.db).wait()
            context.console.success("User 👶🏿 created!!!")
        }
    }
}

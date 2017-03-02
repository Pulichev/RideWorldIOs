//
//  TypeUsersFromBackendlessUser.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 28.02.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import Foundation

class TypeUsersFromBackendlessUser {
    static func returnUser(backendlessUser: BackendlessUser) -> Users {
        let user = Users()
        user.objectId = backendlessUser.getProperty("objectId") as! String?
        user.email = backendlessUser.getProperty("email") as! String?
        user.name = backendlessUser.getProperty("name") as! String?
        user.userBioDescription = backendlessUser.getProperty("userBioDescription") as! String?
        user.userNameAndSename = backendlessUser.getProperty("userNameAndSename") as! String?
        
        return user
    }
}

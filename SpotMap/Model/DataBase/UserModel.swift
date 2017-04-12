//
//  UserModel.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 11.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseDatabase
import FirebaseAuth

class UserModel {
    static var refToUsersNode = FIRDatabase.database().reference(withPath: "MainDataBase/users")
    
    static func getCurrentUserId() -> String {
        return (FIRAuth.auth()?.currentUser?.uid)!
    }
    
    static func getUserItemById(userId: String,
                                completion: @escaping (_ userItem: UserItem) -> Void) {
        let refToUser = self.refToUsersNode.child(userId)
        refToUser.observeSingleEvent(of: .value, with: { snapshot in
            let user = UserItem(snapshot: snapshot)
            completion(user)
        })
    }
    
    static func getUserItemByLogin(userLogin: String,
                                   completion: @escaping (_ userItem: UserItem?) -> Void) {
        self.refToUsersNode.observeSingleEvent(of: .value, with: { snapshot in
            
            for user in snapshot.children {
                let snapshotValue = (user as! FIRDataSnapshot).value as! [String: AnyObject]
                let login = snapshotValue["login"] as! String // getting login of user
                
                if login == userLogin {
                    let userItem = UserItem(snapshot: user as! FIRDataSnapshot)
                    completion(userItem)
                    return
                }
            }
            
            completion(nil) // haven't fouded user
        })
    }
}

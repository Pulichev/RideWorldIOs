//
//  UserModel.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 11.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseDatabase
import FirebaseAuth

struct User {
    static var refToUsersNode = FIRDatabase.database().reference(withPath: "MainDataBase/users")
    
    static func getCurrentUserId() -> String {
        return (FIRAuth.auth()?.currentUser?.uid)!
    }
    
    static func getItemById(for userId: String,
                            completion: @escaping (_ userItem: UserItem) -> Void) {
        let refToUser = self.refToUsersNode.child(userId)
        refToUser.observeSingleEvent(of: .value, with: { snapshot in
            let user = UserItem(snapshot: snapshot)
            completion(user)
        })
    }
    
    static func getItemByLogin(for userLogin: String,
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
    
    static func updateUserInfo(for userId: String, _ bio: String,
                               _ login: String, _ nameAndSename : String) {
        let refToCurrentUser = FIRDatabase.database().reference(withPath: "MainDataBase/users/").child(userId)
        
        refToCurrentUser.updateChildValues([
            "bioDescription" : bio,
            "login": login,
            "nameAndSename": nameAndSename
            ])
    }
    
    static func getFollowersCountString(userId: String,
                                        completion: @escaping (_ followersCount: String) -> Void) {
        let refToUser = self.refToUsersNode.child(userId)
        let refToFollowers = refToUser.child("followers")
        refToFollowers.observe(.value, with: { snapshot in
            if let value = snapshot.value as? [String: Any] {
                completion(String(describing: value.count))
            } else {
                completion("0")
            }
        })
    }
    
    static func getFollowingsCountString(userId: String,
                                         completion: @escaping (_ followingsCount: String) -> Void) {
        let refToUser = self.refToUsersNode.child(userId)
        let refToFollowings = refToUser.child("following")
        refToFollowings.observe(.value, with: { snapshot in
            if let value = snapshot.value as? [String: Any] {
                completion(String(describing: value.count))
            } else {
                completion("0")
            }
        })
    }
    
    static func getPostsIds(for userItem: UserItem,
                            completion: @escaping (_ postIds: [String]?) -> Void) {
        let refToUserPosts = self.refToUsersNode.child(userItem.uid).child("posts")
        
        refToUserPosts.observeSingleEvent(of: .value, with: { snapshot in
            if let value = snapshot.value as? [String: Any] {
                let postsIds = Array(value.keys).sorted(by: { $0 > $1 })
                completion(postsIds)
            }
        })
        
        completion(nil) // if no posts
    }
}

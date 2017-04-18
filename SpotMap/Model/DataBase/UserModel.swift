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
    
    // MARK: - Create user after registration
    static func create(with login: String) {
        let loggedInUser = self.getCurrentUser()
        let currentDate = Date()
        let newUser = UserItem(uid: loggedInUser.uid, email: loggedInUser.email!,
                               login: login, createdDate: String(describing: currentDate))
        
        // Create a child path with a key set to the uid underneath the "users" node
        let refToNewUser = refToUsersNode.child(loggedInUser.uid)
        refToNewUser.setValue(newUser.toAnyObject())
    }
    
    // MARK: - Sign in / Sign up part
    static func signOut() -> Bool {
        do {
            try FIRAuth.auth()!.signOut()
            return true
        } catch {
            print("Error while signing out!")
            return false
        }
    }
    
    // MARK: - Get part
    static func getCurrentUserId() -> String {
        return (FIRAuth.auth()?.currentUser?.uid)!
    }
    
    static func getCurrentUser() -> FIRUser {
        return (FIRAuth.auth()?.currentUser)!
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
    
    // MARK: - Update part
    static func updateUserInfo(for userId: String, _ bio: String,
                               _ login: String, _ nameAndSename : String) {
        let refToCurrentUser = FIRDatabase.database().reference(withPath: "MainDataBase/users/").child(userId)
        
        refToCurrentUser.updateChildValues([
            "bioDescription" : bio,
            "login": login,
            "nameAndSename": nameAndSename
            ])
    }
    
    // MARK: - Posts part
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
    
    static func addPost(_ postItem: PostItem) {
        let refToUserNewPost = self.refToUsersNode.child(postItem.addedByUser).child("posts")
        
        refToUserNewPost.observeSingleEvent(of: .value, with: { snapshot in
            if var value = snapshot.value as? [String : Bool] {
                value[postItem.key] = true
                refToUserNewPost.setValue(value)
            } else {
                refToUserNewPost.setValue([postItem.key : true])
            }
        })
    }
    
    static func deletePost(fromUserNodeWith userId: String, _ postId: String) {
        let refToUserPostNode = self.refToUsersNode.child(userId).child("posts")
        refToUserPostNode.observeSingleEvent(of: .value, with: { snapshot in
            if var posts = snapshot.value as? [String : Bool] {
                posts.removeValue(forKey: postId)
                
                refToUserPostNode.setValue(posts)
            }
        })
    }
    
    // MARK: - Follow part
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
    
    static func getFollowersList(for userId: String,
                                 completion: @escaping (_ followersList: [UserItem]) -> Void) {
        let refToUserFollowers = self.refToUsersNode.child(userId).child("followers")
        
        var followersList = [UserItem]()
        
        refToUserFollowers.observeSingleEvent(of: .value, with: { snapshot in
            let value = snapshot.value as? NSDictionary
            if let followersIds = value?.allKeys as? [String] {
                var countOfLoaded = 0
                for followerId in followersIds {
                    self.getItemById(for: followerId,
                                     completion: { follower in
                                        countOfLoaded += 1
                                followersList.append(follower)
                                        if countOfLoaded == followersIds.count {
                                            completion(followersList)
                                        }
                    })
                }
            }
        })
    }
    
    static func getFollowingsList(for userId: String,
                                 completion: @escaping (_ followingsList: [UserItem]) -> Void) {
        let refToUserFollowings = self.refToUsersNode.child(userId).child("following")
        
        var followingsList = [UserItem]()
        
        refToUserFollowings.observeSingleEvent(of: .value, with: { snapshot in
            let value = snapshot.value as? NSDictionary
            if let followingsIds = value?.allKeys as? [String] {
                var countOfLoaded = 0
                for followingId in followingsIds {
                    self.getItemById(for: followingId,
                                     completion: { following in
                                        countOfLoaded += 1
                                        followingsList.append(following)
                                        if countOfLoaded == followingsIds.count {
                                            completion(followingsList)
                                        }
                    })
                }
            }
        })
    }

    
    static func isCurrentUserFollowing(this userId: String, completion: @escaping(_ isFollowing: Bool) -> Void) {
        let currentUserId = self.getCurrentUserId()
        let refToCurrentUser = self.refToUsersNode.child(currentUserId).child("following")
        
        refToCurrentUser.observeSingleEvent(of: .value, with: { snapshot in
            if var value = snapshot.value as? [String : Bool] {
                if value[userId] != nil {
                    completion(true)
                } else {
                    completion(false)
                }
            } else {
                completion(false)
            }
        })
    }
    
    static func addFollowing(to userId: String) {
        let refToCurrentUser = self.refToUsersNode.child(self.getCurrentUserId()).child("following")
        
        refToCurrentUser.observeSingleEvent(of: .value, with: { snapshot in
            if var value = snapshot.value as? [String : Bool] {
                value[userId] = true
                refToCurrentUser.setValue(value)
            } else {
                refToCurrentUser.setValue([userId])
            }
        })
    }
    
    static func removeFollowing(from userId: String) {
        let refToCurrentUser = self.refToUsersNode.child(self.getCurrentUserId()).child("following")
        
        refToCurrentUser.observeSingleEvent(of: .value, with: { snapshot in
            if var value = snapshot.value as? [String : Bool] {
                value.removeValue(forKey: userId)
                refToCurrentUser.setValue(value)
            }
        })
    }
    
    static func addFollower(to userId: String) {
        let refToRider = self.refToUsersNode.child(userId).child("followers")
        
        refToRider.observeSingleEvent(of: .value, with: { snapshot in
            if var value = snapshot.value as? [String : Bool] {
                value[self.getCurrentUserId()] = true
                refToRider.setValue(value)
            } else {
                refToRider.setValue([userId])
            }
        })
    }
    
    static func removeFollower(from userId: String) {
        let refToRider = self.refToUsersNode.child(userId).child("followers")
        
        refToRider.observeSingleEvent(of: .value, with: { snapshot in
            if var value = snapshot.value as? [String : Bool] {
                value.removeValue(forKey: self.getCurrentUserId())
                refToRider.setValue(value)
            }
        })
    }
}

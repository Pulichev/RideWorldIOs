//
//  UserModel.swift
//  RideWorld
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
      let refToUser = refToUsersNode.child(userId)
      refToUser.observeSingleEvent(of: .value, with: { snapshot in
         let user = UserItem(snapshot: snapshot)
         completion(user)
      })
   }
   
   static func getItemByLogin(for userLogin: String,
                              completion: @escaping (_ userItem: UserItem?) -> Void) {
      refToUsersNode.observeSingleEvent(of: .value, with: { snapshot in
         
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
   static func getPostsIds(for userId: String,
                           completion: @escaping (_ postIds: [String]?) -> Void) {
      let refToUserPosts = refToUsersNode.child(userId).child("posts")
      
      refToUserPosts.observeSingleEvent(of: .value, with: { snapshot in
         if let value = snapshot.value as? [String: Any] {
            let postsIds = Array(value.keys).sorted(by: { $0 > $1 })
            completion(postsIds)
         } else {
            completion(nil) // if no posts
         }
      })
   }
   
   static func addPost(_ postItem: PostItem) {
      let refToUserNewPost = refToUsersNode.child(postItem.addedByUser).child("posts")
      
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
      let refToUserPostNode = refToUsersNode.child(userId).child("posts")
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
      let refToUser = refToUsersNode.child(userId)
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
      let refToUser = refToUsersNode.child(userId)
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
      let refToUserFollowers = refToUsersNode.child(userId).child("followers")
      
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
      let refToUserFollowings = refToUsersNode.child(userId).child("following")
      
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
   
   static func getFollowingsIdsForCurrentUser(
      completion: @escaping (_ followingsIds: [String]) -> Void) {
      
      if self.alreadyLoadedCountOfPosts == 0 { // if we just started
         let currentUserId = getCurrentUserId()
         let refToUserFollowings = refToUsersNode.child(currentUserId).child("following")
         
         refToUserFollowings.observeSingleEvent(of: .value, with: { snapshot in
            var followingsIds = [String]()
            
            if let value = snapshot.value as? NSDictionary {
               followingsIds.append(contentsOf: (value.allKeys as! [String]))
            }
            
            followingsIds.append(currentUserId) // add current user to strip too
            
            completion(followingsIds)
         })
      } else {
         completion(self.followingsIds)
      }
   }
   
   
   static func isCurrentUserFollowing(this userId: String, completion: @escaping(_ isFollowing: Bool) -> Void) {
      let currentUserId = self.getCurrentUserId()
      let refToCurrentUser = refToUsersNode.child(currentUserId).child("following")
      
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
      let refToCurrentUser = refToUsersNode.child(self.getCurrentUserId()).child("following")
      
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
      let refToCurrentUser = refToUsersNode.child(self.getCurrentUserId()).child("following")
      
      refToCurrentUser.observeSingleEvent(of: .value, with: { snapshot in
         if var value = snapshot.value as? [String : Bool] {
            value.removeValue(forKey: userId)
            refToCurrentUser.setValue(value)
         }
      })
   }
   
   static func addFollower(to userId: String) {
      let refToRider = refToUsersNode.child(userId).child("followers")
      
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
      let refToRider = refToUsersNode.child(userId).child("followers")
      
      refToRider.observeSingleEvent(of: .value, with: { snapshot in
         if var value = snapshot.value as? [String : Bool] {
            value.removeValue(forKey: self.getCurrentUserId())
            refToRider.setValue(value)
         }
      })
   }
   
   // MARK: - Get user strip posts part
   static var followingsIds = [String]() // array of user followings + user ids (!NEXT NAMED FOLLOWINGSIDS!)
   // We will update it only in refresh function of PostStripController
   static var postsIds = [String]() // We will update it only in refresh function of PostStripController
   
   static var alreadyLoadedCountOfPosts: Int = 0
   
   static func getStripPostsIds(
      completion: @escaping (_ postsIds: [String]) -> Void) {
      var followingsPostsIds = [String]()
      
      self.getFollowingsIdsForCurrentUser(
         completion: { followingsIds in
            var countOfProcessedFollowings = 0
            
            if self.alreadyLoadedCountOfPosts == 0 { // if we haven't loaded already
               for followingId in followingsIds {
                  self.getPostsIds(for: followingId,
                                   completion: { postsIds in
                                    countOfProcessedFollowings += 1
                                    
                                    if postsIds != nil {
                                       followingsPostsIds.append(contentsOf: postsIds!)
                                    }
                                    
                                    if countOfProcessedFollowings == followingsIds.count {
                                       completion(followingsPostsIds.sorted(by: { $0 > $1 })) // with order by date
                                    }
                  })
               }
            } else {
               completion(self.postsIds)
            }
      })
   }
   
   static func getStripPosts(countOfNewItemsToAdd: Int,
                             completion: @escaping (_ postsForAdding: [PostItem]?) -> Void) {
      self.getStripPostsIds(completion: { postsIds in
         self.postsIds = postsIds
         
         if let nextPostsIds = self.getNextIdsForAdd(countOfNewItemsToAdd) {
            var newPosts = [PostItem]()
            var countOfNewPostsLoaded = 0
            
            for postId in nextPostsIds {
               Post.getItemById(for: postId, completion: { post in
                  if post != nil { // founded without errors
                     newPosts.append(post!)
                     countOfNewPostsLoaded += 1
                     
                     if countOfNewPostsLoaded == nextPostsIds.count {
                        self.alreadyLoadedCountOfPosts += nextPostsIds.count
                        completion(newPosts.sorted(by: { $0.key > $1.key }))
                     }
                  }
               })
            }
         } else {
            completion(nil) // if no more posts
         }
      })
   }
   
   private static func getNextIdsForAdd(_ count: Int) -> [String]? {
      let keysCount = self.postsIds.count
      let startIndex = self.alreadyLoadedCountOfPosts
      var endIndex = startIndex + count
      
      if startIndex > keysCount { // segmentation fault :)
         return nil
      }
      
      if endIndex > keysCount {
         endIndex = keysCount
      }
      
      let nextIds = Array(postsIds[startIndex..<endIndex])
      
      return nextIds
   }
}
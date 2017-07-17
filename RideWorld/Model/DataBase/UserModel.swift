//
//  UserModel.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 11.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseDatabase
import FirebaseAuth

struct UserModel {
   
   static var refToMainDataBase = Database.database().reference(withPath: "MainDataBase")
   static var refToUsersNode = refToMainDataBase.child("users")
   
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
         try Auth.auth().signOut()
         return true
      } catch {
         print("Error while signing out!")
         return false
      }
   }
   
   // MARK: - Get part
   static func getCurrentUserId() -> String {
      return (Auth.auth().currentUser?.uid)!
   }
   
   static func getCurrentUser() -> User {
      return (Auth.auth().currentUser)!
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
            let snapshotValue = (user as! DataSnapshot).value as! [String: AnyObject]
            let login = snapshotValue["login"] as! String // getting login of user
            
            if login == userLogin {
               let userItem = UserItem(snapshot: user as! DataSnapshot)
               completion(userItem)
               return
            }
         }
         
         completion(nil) // haven't fouded user
      })
   }
   
   // MARK: - Update part
   static func updateInfo(for userId: String, _ bio: String,
                          _ login: String, _ nameAndSename : String) {
      let refToCurrentUser = refToUsersNode.child(userId)
      
      refToCurrentUser.updateChildValues([
         "bioDescription": bio,
         "login": login,
         "nameAndSename": nameAndSename
         ])
   }
   
   static func updatePhotoRef(for userId: String, size: Int, url: String) {
      let sizeString = String(describing: size)
      let refToCurrentUser = refToUsersNode.child(userId)
      
      refToCurrentUser.updateChildValues([
         "photo" + sizeString + "ref": url
         ])
   }
   
   // MARK: - Posts part
   static func getPostsIds(for userId: String,
                           completion: @escaping (_ postIds: [String]?) -> Void) {
      let refToUserPosts = refToMainDataBase.child("usersposts").child(userId)
      
      refToUserPosts.observeSingleEvent(of: .value, with: { snapshot in
         if let value = snapshot.value as? [String: Any] {
            let postsIds = Array(value.keys).sorted(by: { $0 > $1 })
            completion(postsIds)
         } else {
            completion(nil) // if no posts
         }
      })
   }
   
   // MARK: - Follow part
   static func getFollowersCountString(userId: String,
                                       completion: @escaping (_ followersCount: String) -> Void) {
      let refToUserFollowers = refToMainDataBase.child("usersfollowers").child(userId)
      
      refToUserFollowers.observe(.value, with: { snapshot in
         if let value = snapshot.value as? [String: Any] {
            completion(String(describing: value.count))
         } else {
            completion("0")
         }
      })
   }
   
   static func getFollowingsCountString(userId: String,
                                        completion: @escaping (_ followingsCount: String) -> Void) {
      let refToUserFollowings = refToMainDataBase.child("usersfollowings").child(userId)
      
      refToUserFollowings.observe(.value, with: { snapshot in
         if let value = snapshot.value as? [String: Any] {
            completion(String(describing: value.count))
         } else {
            completion("0")
         }
      })
   }
   
   static func getFollowersList(for userId: String,
                                completion: @escaping (_ followersList: [UserItem]) -> Void) {
      let refToUserFollowers = refToMainDataBase.child("usersfollowers").child(userId)
      
      var followersList = [UserItem]()
      
      refToUserFollowers.observeSingleEvent(of: .value, with: { snapshot in
         let value = snapshot.value as? NSDictionary
         if let followersIds = value?.allKeys as? [String] {
            var countOfLoaded = 0
            for followerId in followersIds {
               self.getItemById(for: followerId) { follower in
                  countOfLoaded += 1
                  followersList.append(follower)
                  if countOfLoaded == followersIds.count {
                     completion(followersList)
                  }
               }
            }
         }
      })
   }
   
   static func getFollowingsList(for userId: String,
                                 completion: @escaping (_ followingsList: [UserItem]) -> Void) {
      let refToUserFollowings = refToMainDataBase.child("usersfollowings").child(userId)
      
      var followingsList = [UserItem]()
      
      refToUserFollowings.observeSingleEvent(of: .value, with: { snapshot in
         let value = snapshot.value as? NSDictionary
         if let followingsIds = value?.allKeys as? [String] {
            var countOfLoaded = 0
            for followingId in followingsIds {
               self.getItemById(for: followingId) { following in
                  countOfLoaded += 1
                  followingsList.append(following)
                  if countOfLoaded == followingsIds.count {
                     completion(followingsList)
                  }
               }
            }
         }
      })
   }
   
   static func isCurrentUserFollowing(this userId: String,
                                      completion: @escaping(_ isFollowing: Bool) -> Void) {
      let currentUserId = self.getCurrentUserId()
      let refToCurrentUser = refToMainDataBase.child("usersfollowings").child(currentUserId)
      
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
      let refToCurrentUser = refToMainDataBase.child("usersfollowings").child(self.getCurrentUserId()).child(userId)
      
      refToCurrentUser.setValue(true)
   }
   
   static func removeFollowing(from userId: String) {
      let refToCurrentUser = refToMainDataBase.child("usersfollowings").child(self.getCurrentUserId()).child(userId)
      
      refToCurrentUser.removeValue()
   }
   
   static func addFollower(to userId: String) {
      let keyToFeedbackNode = refToMainDataBase.child("feedback").child(userId).childByAutoId().key
      
      let updates: [String: Any?] = [
         "/usersfollowers/" + userId + "/" + getCurrentUserId() : keyToFeedbackNode,
         "/feedback/" + userId + "/" + keyToFeedbackNode :
            [
               "userId" : getCurrentUserId(),
               "datetime" : String(describing: Date()),
               "isViewed" : false
         ]
      ]
      
      refToMainDataBase.updateChildValues(updates)
   }
   
   static func removeFollower(from userId: String) {
      getFeedbackKey(for: userId) { fbKey in
         let updates: [String: Any?] = [
            "/usersfollowers/" + userId + "/" + getCurrentUserId() : nil,
            "/feedback/" + userId + "/" + fbKey: nil
         ]
         
         refToMainDataBase.updateChildValues(updates)
      }
   }
   
   static func addFollowingToSpot(with id: String) {
      let refToUserFollowedSpots = refToMainDataBase.child("userspotfollowings").child(getCurrentUserId())
      
      let refToUserSpotFollowing = refToUserFollowedSpots.child(id)
      
      refToUserSpotFollowing.setValue(true)
   }
   
   static func removeFollowingToSpot(with id: String) {
      let refToUserFollowedSpots = refToMainDataBase.child("userspotfollowings").child(getCurrentUserId())
      
      let refToUserSpotFollowing = refToUserFollowedSpots.child(id)
      
      refToUserSpotFollowing.removeValue()
   }
   
   static func isCurrentUserFollowingSpot(with id: String,
                                          completion: @escaping(_ isFollowing: Bool) -> Void) {
      let refToUserFollowedSpots = refToMainDataBase.child("userspotfollowings").child(getCurrentUserId())
      
      refToUserFollowedSpots.observeSingleEvent(of: .value, with: { snapshot in
         if var value = snapshot.value as? [String : Bool] {
            if value[id] != nil {
               completion(true)
            } else {
               completion(false)
            }
         } else {
            completion(false)
         }
      })
   }
   
   static func getUserFollowedSpots(completion: @escaping (_ spotsIds: [String]) -> Void) {
      let refToUserFollowedSpots = refToMainDataBase.child("userspotfollowings").child(getCurrentUserId())
      
      refToUserFollowedSpots.observeSingleEvent(of: .value, with: { snapshot in
         var spotsIds = [String]()
         
         if let value = snapshot.value as? NSDictionary {
            spotsIds.append(contentsOf: (value.allKeys as! [String]))
         }
         
         completion(spotsIds)
      })
   }
   
   // get feedback key from user, from which we have unsubscribed
   static func getFeedbackKey(for followedUserId: String,
                              completion: @escaping (_ fbId: String) -> Void) {
      let ref = refToMainDataBase.child("/usersfollowers/" + followedUserId + "/" + getCurrentUserId())
      
      ref.observeSingleEvent(of: .value, with: { snapshot in
         let fbKey = snapshot.value as! String
         completion(fbKey)
      })
   }
   
   // MARK: - Get user strip posts part
   public static var lastKey: String! // this is post id from which
   // we will start search for infinite scrolling
   
   static func getStripPosts(countOfNewItemsToAdd: Int,
                             completion: @escaping (_ postsForAdding: [PostItem]?) -> Void) {
      let refToFeedPosts = Database.database().reference(withPath: "MainDataBase/userpostsfeed/").child(getCurrentUserId())
      
      if lastKey == nil {
         refToFeedPosts.queryOrderedByKey().queryLimited(toLast: UInt(countOfNewItemsToAdd)).observeSingleEvent(of: .value, with: { snapshot in
            var postsList: [PostItem] = []
            
            for item in snapshot.children {
               let postItem = PostItem(snapshot: item as! DataSnapshot)
               postsList.append(postItem)
            }
            
            let orderedPostsList = postsList.sorted(by: { $0.key > $1.key })
            let newLastKey = orderedPostsList.last?.key
            
            if newLastKey != lastKey {
               lastKey = newLastKey
               
               completion(orderedPostsList)
            } else {
               completion(nil)
            }
         })
      } else {
         refToFeedPosts.queryOrderedByKey().queryEnding(atValue: lastKey).queryLimited(toLast: UInt(countOfNewItemsToAdd) + 1).observeSingleEvent(of: .value, with: { snapshot in
            var postsList: [PostItem] = []
            
            for item in snapshot.children {
               let postItem = PostItem(snapshot: item as! DataSnapshot)
               postsList.append(postItem)
            }
            
            var orderedPostsList = postsList.sorted(by: { $0.key > $1.key })
            orderedPostsList.removeFirst(1)
            let newLastKey = orderedPostsList.last?.key
            
            if newLastKey != lastKey {
               lastKey = newLastKey
               
               completion(orderedPostsList)
            } else {
               completion(nil)
            }
         })
      }
   }
   
   // for refresh. reload data
   static func dropLastKey() {
      lastKey = nil
   }
   
   // MARK: - Feedback part
   static let refToFeedback = refToMainDataBase.child("feedback")
   
   static func getFeedbackSnapShotData(for userId: String,
                                       completion: @escaping (_ snapshot: [String: AnyObject]?) -> Void) {
      let refToUserFeedback = refToFeedback.child(userId)
      
      refToUserFeedback.queryLimited(toLast: 15).observe(.value, with: { snapshot in
         if let value = snapshot.value as? [String: AnyObject] {
            completion(value)
         }
      })
   }
   
   static func setFeedbackIsViewedToTrue(withKey key: String) {
      let currentUserId = getCurrentUserId()
      let refToEntityIsViewed = refToFeedback.child(currentUserId).child(key).child("isViewed")
      
      refToEntityIsViewed.setValue(true)
   }
   
   // MARK: - Search part
   static func searchUsersWithLogin(startedWith text: String,
                                    completion: @escaping (_ users: [UserItem]) -> Void) {
      refToUsersNode
         .queryOrdered(byChild: "login")
         .queryStarting(atValue: text)
         .queryEnding(atValue: text+"\u{f8ff}")
         .observeSingleEvent(of: .value, with: { snapshot in
            var users = [UserItem]()
            
            for user in snapshot.children {
               let user = UserItem(snapshot: user as! DataSnapshot)
               
               users.append(user)
            }
            
            completion(users)
         })
   }
   
   // MARK: - Reports section
   static func addReportOnPost(with id: String, reason text: String) {
      let refToReport = refToMainDataBase.child("reportedposts").child(id).child(getCurrentUserId())
      
      refToReport.setValue(text)
   }
}

//
//  UserModel.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 11.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseDatabase
import FirebaseAuth
import FirebaseMessaging // for signOut function

struct UserModel {
   
   static private var refToMainDataBase = Database.database().reference(withPath: "MainDataBase")
   static private var refToUsersNode = refToMainDataBase.child("users")
   
   // MARK: - Create user after registration
   static func create(with login: String, completion: @escaping (_ isFinished: Bool) -> Void) {
      let loggedInUser = self.getCurrentUser()
      let newUser = UserItem(uid: loggedInUser.uid, email: loggedInUser.email!,
                             login: login)
      
      // Create a child path with a key set to the uid underneath the "users" node
      let refToNewUser = refToUsersNode.child(loggedInUser.uid)
      refToNewUser.setValue(newUser.toAnyObject()) { _ in
         // add to special node create date and last login update (by default - current date)
         let refToUserDates = refToMainDataBase.child("usersdates").child(loggedInUser.uid)
         let currentDate = String(describing: Date())
         // lastLoginUpdate - need it to prevent login change more ofthen than 100 days
         refToUserDates.setValue(["createdDate": currentDate,
                                  "lastLoginUpdate": currentDate])
         { _ in
            completion(true)
         }
      }
   }
   
   // MARK: - Sign in / Sign up part
   static func signOut() -> Bool {
      do {
         // clear our structs
         UserModel.dropLastKey()
         Spot.dropLastKey()
         
         // remove notifications token
         let token = Messaging.messaging().fcmToken!
         removeFCMToken(from: getCurrentUserId(), token)
         
         try Auth.auth().signOut()
         return true
      } catch {
         print("Error while signing out!")
         return false
      }
   }
   
   static func isBlocked(with userId: String,
                         completion: @escaping (_ isBlocked: Bool) -> Void) {
      let refToBlockForCheck = Database.database().reference(withPath: "blockedusers/" + userId)
      
      refToBlockForCheck.observeSingleEvent(of: .value, with: { snapshot in
         if let _ = snapshot.value as? Bool { // it can have only "true" value
            completion(true)
         } else {
            completion(false)
         }
      })
   }
   
   // get last time login was changed
   static func getCountOfDaysAfterLastLoginChangeDate(
      completion: @escaping (_ countOfDays: Int) -> Void) {
      let currentUserId = getCurrentUserId()
      let refToUserLastLoginChangeDate = refToMainDataBase.child("usersdates").child(currentUserId).child("lastLoginUpdate")
      
      refToUserLastLoginChangeDate.observeSingleEvent(of: .value, with: { snapshot in
         let lastLoginChangeDateString = snapshot.value as! String
         let lastLoginChangeDate = DateTimeParser.stringToDate(lastLoginChangeDateString)
         let countOfDays = DateTimeParser.countOfDaysFromToday(for: lastLoginChangeDate)
         
         completion(countOfDays)
      })
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
                              completion: @escaping (_ userItem: UserItem?, _ error: String) -> Void) {
      let refToUser = refToUsersNode
         .queryOrdered(byChild: "login")
         .queryEqual(toValue: userLogin)
      
      refToUser.observeSingleEvent(of: .value, with: { snapshot in
         if let userData = snapshot.value as? [String: [String: Any]] {
            let userItem = UserItem(userData.first!.value)
            completion(userItem, "")
            return
         } else {
            completion(nil, NSLocalizedString("No user founded with login ", comment: "") + userLogin)
         }
      }, withCancel: { error in
         completion(nil, error.localizedDescription)
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
   
   static func updatePhotoRef(for userId: String, size: Int, url: String,
                              completion: @escaping(_ finished: Bool) -> Void) {
      let sizeString = String(describing: size)
      let refToCurrentUser = refToUsersNode.child(userId)
      
      refToCurrentUser.updateChildValues([
         "photo" + sizeString + "ref": url
      ]) { (_,_) in // finished
         completion(true)
      }
   }
   
   // MARK: - Posts part
   static func getPosts(for userId: String,
                        completion: @escaping (_ posts: [PostItem]) -> Void) {
      let refToUserPosts = refToMainDataBase.child("usersposts").child(userId)
      
      refToUserPosts.observeSingleEvent(of: .value, with: { snapshot in
         var postsList: [PostItem] = []
         
         for item in snapshot.children {
            let postItem = PostItem(snapshot: item as! DataSnapshot)
            postsList.append(postItem)
         }
         
         let sortedPostsList = postsList.sorted(by: { $0.key > $1.key })
         
         completion(sortedPostsList)
      })
   }
   
   // MARK: - Follow part
   static func getFollowersCountString(userId: String,
                                       completion: @escaping (_ followersCount: String) -> Void) {
      var followersCount = 0
      
      let refToUserFollowersCount = refToMainDataBase.child("usersfollowerscount").child(userId)
      
      refToUserFollowersCount.observe(.value, with: { snapshot in
         if let countOfFollowers = snapshot.value as? Int {
            followersCount = countOfFollowers
         }
         
         let followersCountString = String(describing: followersCount)
         
         completion(followersCountString)
      })
   }
   
   static func getFollowingsCountString(userId: String,
                                        completion: @escaping (_ followingsCount: String) -> Void) {
      var followingsCount = 0
      
      let refToUserFollowingsCount = refToMainDataBase.child("usersfollowingscount").child(userId)
      
      refToUserFollowingsCount.observe(.value, with: { snapshot in
         if let countOfFollowings = snapshot.value as? Int {
            followingsCount = countOfFollowings
         }
         
         let followingsCountString = String(describing: followingsCount)
         
         completion(followingsCountString)
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
   
   static func addFollowingAndFollower(to userId: String) {
      let keyToFeedbackNode = refToMainDataBase.child("feedback").child(userId).childByAutoId().key
      
      let updates: [String: Any?] = [
         "/usersfollowings/" + getCurrentUserId() + "/" + userId : true,
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
   
   static func removeFollowingAndFollower(from userId: String) {
      getFeedbackKey(for: userId) { fbKey in
         let updates: [String: Any?] = [
            "/usersfollowings/" + getCurrentUserId() + "/" + userId : nil,
            "/usersfollowers/" + userId + "/" + getCurrentUserId() : nil,
            "/feedback/" + userId + "/" + fbKey: nil
         ]
         
         refToMainDataBase.updateChildValues(updates)
      }
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
   static var lastKey: String! // this is post id from which
   // we will start search for infinite scrolling
   
   static func getStripPosts(countOfNewItemsToAdd: Int,
                             completion: @escaping (_ postsForAdding: [PostItem]?, _ error: String) -> Void) {
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
               
               completion(orderedPostsList, "")
            } else {
               completion(nil, "")
            }
         }, withCancel: { error in
            completion(nil, error.localizedDescription)
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
               
               completion(orderedPostsList, "")
            } else {
               completion(nil, "")
            }
         }, withCancel: { error in
            completion(nil, error.localizedDescription)
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
      }, withCancel: { error in
         print(error.localizedDescription)
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
   
   // MARK: - Notifications part
   static private let refToTokens = refToMainDataBase.child("usersnotificationstokens")
   
   // TIP: all bad token (expired and etc.) will be deleted on call from cloud-function
   static func addFCMToken(to userId: String, _ token: String) {
      let refToUserToken = refToTokens.child(userId).child(token)
      
      refToUserToken.setValue(token)
   }
   
   // is called, when user signed out
   static func removeFCMToken(from userId: String, _ token: String) {
      let refToUserToken = refToTokens.child(userId).child(token)

      refToUserToken.removeValue()
   }
}

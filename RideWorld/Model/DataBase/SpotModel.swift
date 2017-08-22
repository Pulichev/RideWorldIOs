//
//  SpotModel.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 16.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseDatabase

struct Spot {
   static var refToMainDataBase = Database.database().reference(withPath: "MainDataBase")
   static var refToSpotNode = refToMainDataBase.child("spots")
   static var refToSpotPostsNode = refToMainDataBase.child("spotsposts")
   static var refToSpotPhotosNode = refToMainDataBase.child("spotphotos")
   
   static func getNewSpotRefKey() -> String {
      return refToSpotNode.childByAutoId().key
   }
   
   static func getItemById(for spotId: String,
                           completion: @escaping (_ spotItem: SpotItem) -> Void) {
      let refToSpot = refToSpotNode.child(spotId)
      refToSpot.observeSingleEvent(of: .value, with: { snapshot in
         let spot = SpotItem(snapshot: snapshot)
         completion(spot)
      })
   }
   
   static func create(_ spot: SpotItem,
                      completion: @escaping (_ hasFinished: Bool) -> Void) {
      refToSpotNode.child(spot.key).setValue(spot.toAnyObject()) { (error, _) in
         if error == nil {
            completion(true)
         } else {
            completion(false)
         }
      }
   }
   
   static func getAll(completion: @escaping (_ spots: [SpotItem]) -> Void) {
      refToSpotNode.observe(.value, with: { snapshot in
         var spotsList: [SpotItem] = []
         
         for item in snapshot.children {
            let spotDetailsItem = SpotItem(snapshot: item as! DataSnapshot)
            spotsList.append(spotDetailsItem)
         }
         
         completion(spotsList)
      })
   }
   
   static func getSpotFollowingsByUserCount(with userId: String,
                                            completion: @escaping (_ countString: String) -> Void) {
      let refToCount = Database.database().reference(withPath: "MainDataBase/userspotfollowingscount/" + userId)
      
      var count = 0
      
      refToCount.observe(.value, with: { snapshot in
         if let countOfFollowings = snapshot.value as? Int {
            count = countOfFollowings
         }
         
         let countOfFollowingsString = String(describing: count)
         
         completion(countOfFollowingsString)
      })
   }
   
   // MARK: - Get spot posts part
   public static var lastKey: String! // this is post id from which
   // we will start search for infinite scrolling
   
   static func getPosts(for spotId: String, countOfNewItemsToAdd: Int,
                        completion: @escaping (_ postsForAdding: [PostItem]?, _ error: String) -> Void) {
      let refToFeedPosts = Database.database().reference(withPath: "MainDataBase/spotsposts/").child(spotId)
      
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
   
   // MARK: - Photos part
   static func addNewPhotoURL(for spotId: String, _ url: String,
                              completion: @escaping (_ hasFinishedWithNoError: Bool) -> Void) {
      let refToNewPhoto = refToSpotPhotosNode.child(spotId).childByAutoId()
      
      refToNewPhoto.setValue(url) { (error, _) in
         if error == nil {
            completion(true)
         }
      }
   }
   
   static func getAllPhotosURLs(for spotId: String,
                                completion: @escaping (_ urls: [String]) -> Void) {
      let refToPhotos = refToSpotPhotosNode.child(spotId)
      
      refToPhotos.observeSingleEvent(of: .value, with: { snapshot in
         if let value = snapshot.value as? NSDictionary {
            completion(value.allValues as! [String])
         }
      })
   }
   
   // MARK: - Search part
   static func searchSpotsWithName(startedWith text: String,
                                   completion: @escaping (_ spots: [SpotItem]) -> Void) {
      refToSpotNode
         .queryOrdered(byChild: "name")
         .queryStarting(atValue: text)
         .queryEnding(atValue: text+"\u{f8ff}")
         .observeSingleEvent(of: .value, with: { snapshot in
            var spots = [SpotItem]()
            
            for spot in snapshot.children {
               let spot = SpotItem(snapshot: spot as! DataSnapshot)
               
               spots.append(spot)
            }
            
            completion(spots)
         })
   }
   
   // MARK: - Followings part
   static func addFollowingToSpot(with id: String) {
      let refToUserFollowedSpots = refToMainDataBase.child("userspotfollowings").child(UserModel.getCurrentUserId())
      
      let refToUserSpotFollowing = refToUserFollowedSpots.child(id)
      
      refToUserSpotFollowing.setValue(true)
   }
   
   static func removeFollowingToSpot(with id: String) {
      let refToUserFollowedSpots = refToMainDataBase.child("userspotfollowings").child(UserModel.getCurrentUserId())
      
      let refToUserSpotFollowing = refToUserFollowedSpots.child(id)
      
      refToUserSpotFollowing.removeValue()
   }
   
   static func isCurrentUserFollowingSpot(with id: String,
                                          completion: @escaping(_ isFollowing: Bool) -> Void) {
      let refToUserFollowedSpots = refToMainDataBase.child("userspotfollowings").child(UserModel.getCurrentUserId())
      
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
   
   static func getUserFollowedSpots(_ userId: String,
                                    completion: @escaping (_ spotsIds: [SpotItem]) -> Void) {
      let refToUserFollowedSpots = refToMainDataBase.child("userspotfollowings").child(userId)
      
      refToUserFollowedSpots.observeSingleEvent(of: .value, with: { snapshot in
         var spotsIds = [String]()
         
         if let value = snapshot.value as? NSDictionary {
            spotsIds.append(contentsOf: (value.allKeys as! [String]))
         }
         
         var spots = [SpotItem]()
         var countOfProcessedItems = 0
         
         if spotsIds.count == 0 { completion(spots) } // if no spots followed
         
         for spotId in spotsIds {
            let refToSpot = refToSpotNode.child(spotId)
            refToSpot.observeSingleEvent(of: .value, with: { snapshot in
               countOfProcessedItems += 1
               
               let spot = SpotItem(snapshot: snapshot)
               spots.append(spot)
               
               if countOfProcessedItems == spotsIds.count {
                  completion(spots)
               }
            })
         }
      })
   }
}

//
//  SpotModel.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 16.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseDatabase

struct Spot {
   static var refToSpotNode = Database.database().reference(withPath: "MainDataBase/spots")
   static var refToSpotPostsNode = Database.database().reference(withPath: "MainDataBase/spotsposts")
   static var refToSpotPhotosNode = Database.database().reference(withPath: "MainDataBase/spotphotos")
   
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
   
   // MARK: - Get spot posts part
   public static var lastKey: String! // this is post id from which
   // we will start search for infinite scrolling
   
   static func getPosts(for spotId: String, countOfNewItemsToAdd: Int,
                        completion: @escaping (_ postsForAdding: [PostItem]?) -> Void) {
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
}

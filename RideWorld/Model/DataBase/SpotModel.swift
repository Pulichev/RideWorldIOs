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
   static var spotPostsIds = [String]() // full array of spot posts ids.
   // We will update it only in refresh function of PostStripController
   
   static var alreadyLoadedCountOfPosts: Int = 0 // We will update it only
   // in refresh function of PostStripController
   
   static func getSpotPostsIds(for spotId: String,
                               completion: @escaping (_ postsIds: [String]?) -> Void) {
      if alreadyLoadedCountOfPosts == 0 { // if we havent already loaded PostsIds
         let refToSpotPosts = refToSpotPostsNode.child(spotId)
         
         refToSpotPosts.observeSingleEvent(of: .value, with: { snapshot in
            if let value = snapshot.value as? NSDictionary {
               let spotPostsIds = (value.allKeys as! [String]).sorted(by: { $0 > $1 }) // with order by date
               completion(spotPostsIds)
            } else {
               completion(nil)
            }
         })
      } else {
         completion(self.spotPostsIds)
      }
   }
   
   static func getPosts(for spotId: String, countOfNewItemsToAdd: Int,
                        completion: @escaping (_ postsForAdding: [PostItem]?) -> Void) {
      self.getSpotPostsIds(for: spotId) { spotPostsIds in
         if spotPostsIds != nil {
            self.spotPostsIds = spotPostsIds!
         } else { // if no posts
            completion(nil)
         }
         
         guard let nextPostsIds = self.getNextIdsForAdd(countOfNewItemsToAdd)
            else { // if no more posts
               completion(nil)
               return
         }
         var newPosts = [PostItem]()
         var countOfNewPostsLoaded = 0
         
         for postId in nextPostsIds {
            Post.getItemById(for: postId) { post in
               if post != nil { // founded without errors
                  newPosts.append(post!)
                  countOfNewPostsLoaded += 1
                  
                  if countOfNewPostsLoaded == nextPostsIds.count {
                     self.alreadyLoadedCountOfPosts += nextPostsIds.count
                     completion(newPosts.sorted(by: { $0.key > $1.key }))
                  }
               }
            }
         }
      }
   }
   
   private static func getNextIdsForAdd(_ count: Int) -> [String]? {
      let keysCount = self.spotPostsIds.count
      let startIndex = self.alreadyLoadedCountOfPosts
      var endIndex = startIndex + count
      
      if startIndex > keysCount { // segmentation fault :)
         return nil
      }
      
      if endIndex > keysCount {
         endIndex = keysCount
      }
      
      let nextIds = Array(spotPostsIds[startIndex..<endIndex])
      
      return nextIds
   }
   
   static func clearCurrentData() {
      alreadyLoadedCountOfPosts = 0
      spotPostsIds.removeAll()
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
}

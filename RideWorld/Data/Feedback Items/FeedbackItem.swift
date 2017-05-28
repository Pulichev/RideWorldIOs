//
//  FeedbackItem.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 12.05.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

class FeedbackItem {
   var type: Int! // 1 - follower, 2 - comment, 3 - like
   
   static func getArray(
      completion: @escaping (_ fbItems: [FeedbackItem]) -> Void) {
      
      User.getFeedbackSnapShotData(for: User.getCurrentUserId()) { feedItemsSnapshot in
         if feedItemsSnapshot == nil { return }
         
         var feedbackItems = [FeedbackItem]()
         
         let sortedKeys = feedItemsSnapshot!.keys.sorted(by: {$0 > $1}) // order by date
         
         var countOfProccessedItems = 0
         for key in sortedKeys {
            let value = feedItemsSnapshot![key] as? [String:  Any]
            
            getProperItem(value) { item in
               if item != nil {
                  feedbackItems.append(item!)
               }
               
               countOfProccessedItems += 1
               
               if countOfProccessedItems == sortedKeys.count {
                  completion(feedbackItems)
               }
            }
         }
      }
   }
   
   static private func getProperItem(_ value: [String: Any]?,
                                     completion: @escaping(_ item: FeedbackItem?) -> Void) {
      var feedBackItem: FeedbackItem!
      // what type of feedbacK?
      if value!["commentary"] != nil { // comment
         let _ = CommentFBItem(snapshot: value!) { item in
            if item.postItem != nil {
               completion(item)
            } else {
               completion(nil)
            }
         }
      } else if value!["likePlacedTime"] != nil { // like
         let _ = LikeFBItem(snapshot: value!) { item in
            if item.postItem != nil {
               completion(item)
            } else {
               completion(nil)
            }
         }
      } else { // follow
         feedBackItem = FollowerFBItem(snapshot: value!)
         completion(feedBackItem)
      }
   }
}

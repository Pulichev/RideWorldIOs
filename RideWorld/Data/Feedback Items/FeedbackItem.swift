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
         
         for key in sortedKeys {
            let value = feedItemsSnapshot![key] as? [String: Any]
            var feedBackItem: FeedbackItem!
            // what type of feedbacK?
            if value!["commentary"] != nil { // comment
               feedBackItem = CommentFBItem(snapshot: value!)
            } else if value!["likePlacedTime"] != nil { // like
               feedBackItem = LikeFBItem(snapshot: value!)
            } else { // follow
               feedBackItem = FollowerFBItem(snapshot: value!)
            }
            
            feedbackItems.append(feedBackItem)
         }
         
         completion(feedbackItems)
      }
   }
}

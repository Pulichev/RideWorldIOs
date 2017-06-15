//
//  FeedbackModel.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 08.06.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

struct Feedback {
   static func getArray(
      completion: @escaping (_ fbItems: [FeedbackItem]) -> Void) {
      
      UserModel.getFeedbackSnapShotData(for: UserModel.getCurrentUserId()) { feedItemsSnapshot in
         if feedItemsSnapshot == nil { return }
         
         var feedbackItems = [FeedbackItem]()
         
         let sortedKeys = feedItemsSnapshot!.keys.sorted(by: {$0 > $1}) // order by date
         
         var countOfProccessedItems = 0
         for key in sortedKeys {
            let value = feedItemsSnapshot![key] as? [String:  Any]
            
            getProperItem(value, key) { item in
               if item != nil {
                  feedbackItems.append(item!)
               }
               
               countOfProccessedItems += 1
               
               if countOfProccessedItems == sortedKeys.count {
                  completion(feedbackItems.sorted(by: { $0.key > $1.key }))
               }
            }
         }
      }
   }
   
   static private func getProperItem(_ value: [String: Any]?, _ key: String,
                                     completion: @escaping(_ item: FeedbackItem?) -> Void) {
      var feedBackItem: FeedbackItem!
      // what type of feedbacK?
      if value!["commentary"] != nil { // comment
         let _ = CommentFBItem(snapshot: value!, key) { item in
            if item.postItem != nil, item.userItem != nil {
               completion(item)
            } else {
               completion(nil)
            }
         }
      } else if value!["likePlacedTime"] != nil { // like
         let _ = LikeFBItem(snapshot: value!, key) { item in
            if item.postItem != nil, item.userItem != nil {
               completion(item)
            } else {
               completion(nil)
            }
         }
      } else { // follow
         let _ = FollowerFBItem(snapshot: value!, key) { item in
            if item.userItem != nil {
               completion(item)
            } else {
               completion(nil)
            }
         }
      }
   }
}

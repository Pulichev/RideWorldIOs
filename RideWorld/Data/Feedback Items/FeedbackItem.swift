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
      var feedbackItems = [FeedbackItem]()
      
      User.getFeedbackSnapShotData(for: User.getCurrentUserId(),
                                   completion: { feedItemsSnapshot in
                                    if feedItemsSnapshot == nil { return }
                                    let sortedKeys = feedItemsSnapshot!.keys.sorted(by: {$0 > $1}) // order by date
                                    
                                    for key in sortedKeys {
                                       let value = feedItemsSnapshot![key] as? [String: Any]
                                       var feedBackItem: FeedbackItem!
                                       // what type of feedbacK?
                                       if value == nil { // this is not [string: any], so it is follower
                                          feedBackItem = FollowerFBItem(dateTime: feedItemsSnapshot![key] as! String)
                                       } else {
                                          if value!["commentId"] != nil { // comment
                                             feedBackItem = CommentFBItem(snapshot: value!)
                                          }
                                          if value!["likePlacedTime"] != nil { // like
                                             feedBackItem = LikeFBItem(snapshot: value!)
                                          }
                                       }
                                       
                                       feedbackItems.append(feedBackItem)
                                    }
                                    
                                    completion(feedbackItems)
      })
   }
}

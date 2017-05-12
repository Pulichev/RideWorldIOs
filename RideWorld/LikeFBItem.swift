//
//  LikeFBItem.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 13.05.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

class LikeFBItem: FeedbackItem {
   var postId: String!
   var userId: String!
   var postAddedByUserId: String!
   var dateTime: String!
   
   init(snapshot: [String: Any]) {
      super.init()
      self.type = 3
      postId = snapshot["postId"] as! String
      userId = snapshot["userId"] as! String
      postAddedByUserId = snapshot["postAddedByUserId"] as! String
      dateTime = snapshot["likePlacedTime"] as! String
   }
}

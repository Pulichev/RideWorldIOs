//
//  CommentFBItem.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 13.05.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

class CommentFBItem: FeedbackItem {
   var text: String!
   var dateTime: String!
   var postId: String!
   var userId: String!
   
   init(snapshot: [String: Any]) {
      super.init()
      self.type = 2
      text = snapshot["commentary"] as! String
      dateTime = snapshot["datetime"] as! String
      postId = snapshot["postId"] as! String
      userId = snapshot["userId"] as! String
   }
}

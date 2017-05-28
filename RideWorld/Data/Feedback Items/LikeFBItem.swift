//
//  LikeFBItem.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 13.05.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

class LikeFBItem: FeedbackItem {
   var postId: String!
   var postItem: PostItem?
   var userId: String!
   var postAddedByUserId: String!
   var dateTime: String!
   
   init(snapshot: [String: Any],
        completion: @escaping (_ likeFBItem: LikeFBItem) -> Void) {
      super.init()
      self.type = 3
      postId = snapshot["postId"] as! String
      userId = snapshot["userId"] as! String
      postAddedByUserId = snapshot["postAddedByUserId"] as! String
      dateTime = snapshot["likePlacedTime"] as! String
      // get full post item. For what? Bcz post may be deleted already ->
      // we need to dont add this feedback
      Post.getItemById(for: postId) { post in
         self.postItem = post
         completion(self)
      }
   }
}
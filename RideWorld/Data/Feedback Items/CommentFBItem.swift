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
   var postItem: PostItem?
   var postAddedByUser: String!
   var userId: String!
   
   init(snapshot: [String: Any],
        completion: @escaping (_ commentFBItem: CommentFBItem) -> Void) {
      super.init()
      self.type = 2
      text = snapshot["commentary"] as! String
      dateTime = snapshot["datetime"] as! String
      postId = snapshot["postId"] as! String
      postAddedByUser = snapshot["postAddedByUser"] as! String
      userId = snapshot["userId"] as! String
      // get full post item. For what? Bcz post may be deleted already ->
      // we need to dont add this feedback
      Post.getItemById(for: postId) { post in
         self.postItem = post
         completion(self)
      }
   }
}

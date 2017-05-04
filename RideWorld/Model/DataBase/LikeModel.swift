//
//  LikeModel.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 16.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseDatabase

struct Like {
   static func add(_ newLike: LikeItem) {
      let ref = FIRDatabase.database().reference(withPath: "MainDataBase")
      
      let updates: [String: Any?] = [
         "/users/" + newLike.userId + "/likePlaced/onposts/" + newLike.postId: newLike.toAnyObject(),
         "/spotpost/" + newLike.postId + "/likes/" + newLike.userId: newLike.toAnyObject()
      ]
      
      ref.updateChildValues(updates)
   }
   
   static func remove(with userId: String, _ post: PostItem) {
      let ref = FIRDatabase.database().reference(withPath: "MainDataBase")
      
      let updates: [String: Any?] = [
         "/users/" + userId + "/likePlaced/onposts/" + post.key: nil,
         "/spotpost/" + post.key + "/likes/" + userId: nil
      ]
      
      ref.updateChildValues(updates)
   }
}

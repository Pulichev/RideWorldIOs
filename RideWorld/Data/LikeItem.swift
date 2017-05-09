//
//  LikeItem.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 07.03.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseDatabase

struct LikeItem {
   var key: String?
   
   let userId: String // who placed
   let postId: String
   let postAddedByUserId: String? // who posted
   let likePlacedTime: String
   
   let ref: FIRDatabaseReference?
   
   init(who userId: String, what postId: String, postWasAddedBy userIdAddedBy: String, at likePlacedTime: String) {
      self.userId = userId
      self.postId = postId
      self.postAddedByUserId = userIdAddedBy
      self.likePlacedTime = likePlacedTime
      
      self.ref = nil
   }
   
   init(snapshot: FIRDataSnapshot) {
      let snapshotValue = snapshot.value as! [String: AnyObject]
      userId = snapshotValue["userId"] as! String
      postId = snapshotValue["postId"] as! String
      likePlacedTime = snapshotValue["likePlacedTime"] as! String
      postAddedByUserId = snapshotValue["postAddedByUserId"] as? String // delete optional, when will clear db before prod
      key = snapshotValue["key"] as? String // same
      
      ref = snapshot.ref
   }
   
   func toAnyObject() -> Any {
      return [
         "userId" : userId,
         "postId" : postId,
         "postAddedByUserId" : postAddedByUserId!,
         "likePlacedTime" : likePlacedTime,
         "key" : key!
      ]
   }
}


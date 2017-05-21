//
//  FollowerFBItem.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 13.05.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

class FollowerFBItem: FeedbackItem {
   var userId: String!
   var dateTime: String!
   
   init(snapshot: [String: Any]) {
      super.init()
      self.type = 1
      userId = snapshot.keys.first!
      self.dateTime = snapshot.values.first as! String
   }
}

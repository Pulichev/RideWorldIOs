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
   
   init(userId: String, dateTime: String) {
      super.init()
      self.type = 1
      self.userId = userId
      self.dateTime = dateTime
   }
}

//
//  FollowerFBItem.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 13.05.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

class FollowerFBItem: FeedbackItem {
   var dateTime: String!
   
   init(dateTime: String) {
      super.init()
      self.type = 1
      self.dateTime = dateTime
   }
}

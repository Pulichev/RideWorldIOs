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
   
   init(snapshot: [String: Any], _ key: String) {
      super.init()
      self.type = 1
      self.key = key
      self.isViewed = snapshot["isViewed"] as! Bool
      
      userId = snapshot.keys.first!
      self.dateTime = snapshot.values.first as! String
   }
}

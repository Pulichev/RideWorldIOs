//
//  PostItem.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 03.03.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseDatabase

struct PostItem {
   var key: String // its var for creating new items.
   // we are sending to model new PostItem without key.
   // then, after .childByAutoId(), setting it
   
   let isPhoto: Bool
   let description: String
   let createdDate: String
   
   // media
   var mediaRef10: String!
   var mediaRef70: String!
   var mediaRef200: String!
   var mediaRef700: String!
   var videoRef: String!
   var mediaAspectRatio: Double!
   
   var commentsCount: Int! = 0
   
   let spotId: String
   
   let addedByUser: String
   
   let ref: DatabaseReference?
   
   init(_ isPhoto: Bool, _ description: String,
        _ createdDate: String, _ spotId: String,
        _ addedByUser: String, _ key: String = "") {
      self.key = key
      
      self.isPhoto = isPhoto
      self.description = description
      self.createdDate = createdDate
      
      self.spotId = spotId
      
      self.addedByUser = addedByUser
      ref = nil
   }
   
   init(snapshot: DataSnapshot) {
      key = snapshot.key
      
      let snapshotValue = snapshot.value as! [String: AnyObject]
      isPhoto = snapshotValue["isPhoto"] as! Bool
      description = snapshotValue["description"] as! String
      createdDate = snapshotValue["createdDate"] as! String
      
      mediaRef10 = snapshotValue["mediaRef10"] as! String
      mediaRef70 = snapshotValue["mediaRef70"] as? String
      mediaRef200 = snapshotValue["mediaRef200"] as? String
      mediaRef700 = snapshotValue["mediaRef700"] as! String
      
      if !isPhoto {
         videoRef = snapshotValue["videoRef"] as! String
      }
      
      mediaAspectRatio = snapshotValue["mediaAspectRatio"] as! Double
      
      spotId = snapshotValue["spotId"] as! String
      
      addedByUser = snapshotValue["addedByUser"] as! String
      ref = snapshot.ref
      
      initCommentsCount(with: snapshotValue)
   }
   
   private mutating func initCommentsCount(with snapshotValue: [String: AnyObject]) {
      guard let comments = snapshotValue["comments"] as? [String: AnyObject] else { return }
      
      commentsCount = comments.count
   }
   
   // full data
   func toAnyObject() -> Any {
      var valuesArray = [String: Any]()
      
      valuesArray["isPhoto"] = isPhoto
      valuesArray["description"] = description
      valuesArray["createdDate"] = createdDate
      
      valuesArray["mediaRef10"] = mediaRef10
      valuesArray["mediaRef70"] = mediaRef70
      valuesArray["mediaRef200"] = mediaRef200
      valuesArray["mediaRef700"] = mediaRef700
      
      if !isPhoto {
         valuesArray["videoRef"] = videoRef
      }
      
      valuesArray["mediaAspectRatio"] = mediaAspectRatio
      
      valuesArray["spotId"] = spotId
      valuesArray["addedByUser"] = addedByUser
      valuesArray["key"] = key
      
      return valuesArray
   }
   
   // data for posts feed strip
   func toAnyObjectForFeedStrip() -> Any {
      var valuesArray = [String: Any]()
      
      valuesArray["isPhoto"] = isPhoto
      valuesArray["description"] = description
      valuesArray["createdDate"] = createdDate
      
      valuesArray["mediaRef10"] = mediaRef10
      valuesArray["mediaRef700"] = mediaRef700
      // no need for others mediaRefs for post strip. 
      // just thumbnail and original
      
      if !isPhoto {
         valuesArray["videoRef"] = videoRef
      }
      
      valuesArray["mediaAspectRatio"] = mediaAspectRatio
      
      valuesArray["spotId"] = spotId
      valuesArray["addedByUser"] = addedByUser
      valuesArray["key"] = key
      
      return valuesArray
   }
}

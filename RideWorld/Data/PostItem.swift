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
   var mediaRef10 = ""
   var mediaRef270 = ""
   var mediaRef700 = ""
   var videoRef = ""
   
   let spotId: String
   
   let addedByUser: String
   
   let ref: FIRDatabaseReference?
   
   init(_ isPhoto: Bool, _ description: String, _ createdDate: String, _ spotId: String, _ addedByUser: String, _ key: String = "") {
      self.key = key
      
      self.isPhoto = isPhoto
      self.description = description
      self.createdDate = createdDate
      
      self.spotId = spotId
      
      self.addedByUser = addedByUser
      ref = nil
   }
   
   init(snapshot: FIRDataSnapshot) {
      key = snapshot.key
      
      let snapshotValue = snapshot.value as! [String: AnyObject]
      isPhoto = snapshotValue["isPhoto"] as! Bool
      description = snapshotValue["description"] as! String
      createdDate = snapshotValue["createdDate"] as! String
      
      if isPhoto {
         mediaRef10 = snapshotValue["mediaRef10"] as! String
         mediaRef700 = snapshotValue["mediaRef700"] as! String
      } else {
         mediaRef10 = snapshotValue["mediaRef10"] as! String
         mediaRef270 = snapshotValue["mediaRef270"] as! String
         videoRef = snapshotValue["videoRef"] as! String
      }
      
      spotId = snapshotValue["spotId"] as! String
      
      addedByUser = snapshotValue["addedByUser"] as! String
      ref = snapshot.ref
   }
   
   func toAnyObject() -> Any {
      return [
         "isPhoto": isPhoto,
         "description": description,
         "createdDate": createdDate,
         
         "mediaRef10": mediaRef10,
         "mediaRef270": mediaRef270,
         "mediaRef700": mediaRef700,
         "videoRef": videoRef,
         
         "spotId": spotId,
         
         "addedByUser": addedByUser,
         "key": key
      ]
   }
}

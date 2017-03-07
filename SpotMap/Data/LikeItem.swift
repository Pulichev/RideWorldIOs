//
//  LikeItem.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 07.03.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import Foundation
import FirebaseDatabase

struct LikeItem {
    
    let likeId: String
    
    let userId: String
    let postId: String
    let likePlacedTime: String
    
    let ref: FIRDatabaseReference?
    
    init(likeId: String, userId: String, postId: String, likePlacedTime: String) {
        self.likeId = likeId
        self.userId = userId
        self.postId = postId
        self.likePlacedTime = likePlacedTime
        
        self.ref = nil
    }
    
    init(snapshot: FIRDataSnapshot) {
        likeId = snapshot.key
        
        let snapshotValue = snapshot.value as! [String: AnyObject]
        userId = snapshotValue["userId"] as! String
        postId = snapshotValue["postId"] as! String
        likePlacedTime = snapshotValue["likePlacedTime"] as! String

        ref = snapshot.ref
    }
    
    func toAnyObject() -> Any {
        return [
            "likeId" : self.likeId,
            "userId" : userId,
            "postId" : postId,
            "likePlacedTime" : likePlacedTime
            ]
    }
}


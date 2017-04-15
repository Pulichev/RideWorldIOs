//
//  LikeModel.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 16.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseDatabase

struct Like {
    static func addToUserNode(_ newLike: LikeItem) {
        let userLikeRef = FIRDatabase.database().reference(withPath: "MainDataBase/users").child(newLike.userId).child("likePlaced/onposts").child(newLike.postId)
        userLikeRef.setValue(newLike.toAnyObject())
    }
    
    static func addToPostNode(_ newLike: LikeItem) {
        let postLikeRef = FIRDatabase.database().reference(withPath: "MainDataBase/spotpost").child(newLike.postId).child("likes").child(newLike.userId)
        postLikeRef.setValue(newLike.toAnyObject())
    }
    
    static func removeFromUserNode() {
        
    }
    
    static func removeFromPostNode() {
        
    }
}

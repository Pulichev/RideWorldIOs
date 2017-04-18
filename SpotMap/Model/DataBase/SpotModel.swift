//
//  SpotModel.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 16.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseDatabase

struct Spot {
    static var refToSpotNode = FIRDatabase.database().reference(withPath: "MainDataBase/spotdetails")
    
    static func deletePost(for spotId: String, _ postId: String) {
        let refToSpotDetailsNode = refToSpotNode.child(spotId).child("posts")
        refToSpotDetailsNode.observeSingleEvent(of: .value, with: { snapshot in
            if var posts = snapshot.value as? [String : Bool] {
                posts.removeValue(forKey: postId)
                
                refToSpotDetailsNode.setValue(posts)
            }
        })
    }
    
    static func create(with name: String,
                       description: String, latitude: Double, longitude: Double) -> String {
        let newSpotRef = self.refToSpotNode.childByAutoId()
        let newSpotRefKey = newSpotRef.key
        
        let newSpotDetailsItem = SpotDetailsItem(name: name, description: description,
                                                 latitude: latitude, longitude: longitude, addedByUser: User.getCurrentUserId(), key: newSpotRefKey)
        newSpotRef.setValue(newSpotDetailsItem.toAnyObject())
        
        return newSpotRefKey
    }
    
    static func addPost(_ postItem: PostItem) {
        let refToSpotNewPost = self.refToSpotNode.child(postItem.spotId).child("posts")
        
        refToSpotNewPost.observeSingleEvent(of: .value, with: { snapshot in
            if var value = snapshot.value as? [String : Bool] {
                value[postItem.key] = true
                refToSpotNewPost.setValue(value)
            } else {
                refToSpotNewPost.setValue([postItem.key : true])
            }
        })
    }
}

//
//  SpotModel.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 16.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseDatabase

struct Spot {
    static var refToSpotNode = FIRDatabase.database().reference(withPath: "MainDataBase/spotDetails")
    
    static func deletePost(for spotId: String, _ postId: String) {
        let refToSpotDetailsNode = refToSpotNode.child(spotId).child("posts")
        refToSpotDetailsNode.observeSingleEvent(of: .value, with: { snapshot in
            if var posts = snapshot.value as? [String : Bool] {
                posts.removeValue(forKey: postId)
                
                refToSpotDetailsNode.setValue(posts)
            }
        })
    }
}

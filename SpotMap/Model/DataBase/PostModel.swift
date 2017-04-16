//
//  PostModel.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 15.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseDatabase

struct Post {
    static var refToPostsNode = FIRDatabase.database().reference(withPath: "MainDataBase/spotpost")
    
    static func getItemById(for postId: String,
                            completion: @escaping (_ postItem: PostItem?) -> Void) {
        let refToPost = self.refToPostsNode.child(postId)
        
        refToPost.observeSingleEvent(of: .value, with: { snapshot in
            let postItem = PostItem(snapshot: snapshot)
            
            completion(postItem)
        })
        
        completion(nil) // if no post with this id
    }
    
    static func delete(with postId: String) {
        let refToPostNode = self.refToPostsNode.child(postId)
        refToPostNode.removeValue()
    }
}

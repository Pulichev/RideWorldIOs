//
//  CommentItem.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 01.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//
// УДАЛИТЬ ПРЯМУЮ СУЩНОСТЬ ЛАЙКА. ЗАЧЕМ ОНА ВООБЩЕ

import FirebaseDatabase

struct CommentItem {
    let userId: String
    let postId: String
    let commentary: String // text of comment
    let datetime: String
    
    let ref: FIRDatabaseReference?
    
    init(userId: String, postId: String, commentary: String, datetime: String) {
        self.userId = userId
        self.postId = postId
        self.commentary = commentary
        self.datetime = datetime
        
        self.ref = nil
    }
    
    init(snapshot: FIRDataSnapshot) {
        let snapshotValue = snapshot.value as! [String: AnyObject]
        userId = snapshotValue["userId"] as! String
        postId = snapshotValue["postId"] as! String
        commentary = snapshotValue["commentary"] as! String
        datetime = snapshotValue["datetime"] as! String
        
        ref = snapshot.ref
    }
    
    func toAnyObject() -> Any {
        return [
            "userId" : userId,
            "postId" : postId,
            "commentary" : commentary,
            "datetime" : datetime
        ]
    }
}

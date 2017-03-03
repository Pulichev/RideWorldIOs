//
//  SpotPostItem.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 03.03.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

//
//  SpotdetailsItem.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 02.03.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseDatabase

struct SpotPostItem {
    
    let key: String
    
    let isPhoto: Bool
    let description: String
    //date?
    
    let addedByUser: String
    let ref: FIRDatabaseReference?
    
    init(isPhoto: Bool, description: String, addedByUser: String, key: String = "") {
        self.key = key
        
        self.isPhoto = isPhoto
        self.description = description
        
        self.addedByUser = addedByUser
        self.ref = nil
    }
    
    init(snapshot: FIRDataSnapshot) {
        key = snapshot.key
        
        let snapshotValue = snapshot.value as! [String: AnyObject]
        isPhoto = snapshotValue["isPhoto"] as! Bool
        description = snapshotValue["description"] as! String
        
        addedByUser = snapshotValue["addedByUser"] as! String
        ref = snapshot.ref
    }
    
    func toAnyObject() -> Any {
        return [
            "isPhoto": isPhoto,
            "description": description,
            
            "addedByUser": addedByUser,
            "key": key
        ]
    }
}

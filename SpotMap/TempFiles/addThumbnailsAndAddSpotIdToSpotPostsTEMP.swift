//
//  addThumbnailsAndAddSpotIdToSpotPostsTEMP.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 09.03.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage

class addThumbnailsAndAddSpotIdToSpotPostsTEMP  {
    static func execute() {
        let ref = FIRDatabase.database().reference(withPath: "MainDataBase/spotdetails")
        
        ref.queryOrdered(byChild: "key").observe(.value, with: { snapshot in
            for item in snapshot.children {
                let spotDetailsItem = SpotDetailsItem(snapshot: item as! FIRDataSnapshot)
                let likeRef = ref.child(spotDetailsItem.key).child("posts")
                likeRef.queryOrdered(byChild: "key").observe(.value, with: { snapshot in
                    if let value = snapshot.value as? [String : Any] {
                        
                    }
                }
            }
        })
    }
}

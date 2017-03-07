//
//  SpotdetailsItem.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 02.03.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseDatabase

struct SpotDetailsItem {
    
    let key: String
    
    let name: String
    let description: String
    let latitude: Double
    let longitude: Double
    
    let addedByUser: String
    
    let ref: FIRDatabaseReference?
    
    init(name: String, description: String, latitude: Double, longitude: Double, addedByUser: String, key: String = "") {
        self.key = key
        
        self.name = name
        self.description = description
        self.latitude = latitude
        self.longitude = longitude
        
        self.addedByUser = addedByUser
        self.ref = nil
    }
    
    init(snapshot: FIRDataSnapshot) {
        key = snapshot.key
        
        let snapshotValue = snapshot.value as! [String: AnyObject]
        name = snapshotValue["name"] as! String
        description = snapshotValue["description"] as! String
        latitude = snapshotValue["latitude"] as! Double
        longitude = snapshotValue["longitude"] as! Double
        
        addedByUser = snapshotValue["addedByUser"] as! String
        ref = snapshot.ref
    }
    
    func toAnyObject() -> Any {
        return [
            "name": name,
            "description": description,
            "latitude": latitude,
            "longitude": longitude,
            "addedByUser": addedByUser,
            "key": key
        ]
    }
    
}

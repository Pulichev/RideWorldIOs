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
                        for postLink in value {
                            // taking data for spotPost
                            let spotPostDBRef = FIRDatabase.database().reference(withPath: "MainDataBase/spotpost").child(postLink.key)
                            
                            spotPostDBRef.observe(.value, with: { snapshot2 in
                                let spotPostItem = SpotPostItem(snapshot: snapshot2)
                                // adding to post spotId
                                spotPostDBRef.setValue([
                                    "addedByUser" : spotPostItem.addedByUser,
                                    "createdDate" : spotPostItem.createdDate,
                                    "description" : spotPostItem.description,
                                    "isPhoto" : spotPostItem.isPhoto,
                                    "key" : spotPostItem.key,
                                    "spotId" : spotDetailsItem.key
                                    ])
                                
                                // transfering photos to new location
                                if spotPostItem.isPhoto {
                                    let storageRef = FIRStorage.storage().reference(withPath: "gs://spotmap-e3116.appspot.com/media/spotPostMedia/" + postLink.key + ".jpeg")
                                    
                                    
                                    
                                    // create thumbnail
                                } else {
                                    let storageRef = FIRStorage.storage().reference(withPath: "gs://spotmap-e3116.appspot.com/media/spotPostMedia/" + postLink.key + ".m4v")
                                    let storageRefForThumbnail = FIRStorage.storage().reference(withPath: "gs://spotmap-e3116.appspot.com/media/spotPostMedia/" + postLink.key + "_thumbnail.jpeg")
                                    
                                    //transfer
                                    storageRef.data(withMaxSize: 10 * 1024 * 1024) { data, error in
                                        if let error = error {
                                            // Uh-oh, an error occurred!
                                            print("ERROR IN DOWNLOAD PART!!!")
                                        } else {
                                            let newStorageRef = FIRStorage.storage().reference(withPath: "gs://spotmap-e3116.appspot.com/media/spotPostMedia/" + spotDetailsItem.key + "/" + postLink.key + ".jpeg")
                                            let image = UIImage(data: data!)
                                        }
                                    }
                                    storageRefForThumbnail.data(withMaxSize: 10 * 1024 * 1024) { data, error in
                                        if let error = error {
                                            // Uh-oh, an error occurred!
                                            print("ERROR IN DOWNLOAD PART!!!")
                                        } else {
                                            let newStorageRef = FIRStorage.storage().reference(withPath: "gs://spotmap-e3116.appspot.com/media/spotPostMedia/" + spotDetailsItem.key + "/" + postLink.key + ".jpeg")
                                            let image = UIImage(data: data!)
                                        }
                                    }
                                }
                            })
                        }
                    } else {
                        print("no posts")
                    }
                })
            }
        })
    }
}

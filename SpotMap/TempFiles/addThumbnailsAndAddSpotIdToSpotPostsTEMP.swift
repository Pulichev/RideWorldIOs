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
//                                spotPostDBRef.setValue([
//                                    "addedByUser" : spotPostItem.addedByUser,
//                                    "createdDate" : spotPostItem.createdDate,
//                                    "description" : spotPostItem.description,
//                                    "isPhoto" : spotPostItem.isPhoto,
//                                    "key" : spotPostItem.key,
//                                    "spotId" : spotDetailsItem.key
//                                    ])
                                
                                // transfering photos to new location
                                if spotPostItem.isPhoto {
                                    let storageRef = FIRStorage.storage().reference(forURL: "gs://spotmap-e3116.appspot.com/media/spotPostMedia/" + postLink.key + ".jpeg")
                                    storageRef.data(withMaxSize: 10 * 1024 * 1024) { data, error in
                                        if let error = error {
                                            // Uh-oh, an error occurred!
                                            print(error.localizedDescription)
                                        } else {
                                            let newStorageRef = FIRStorage.storage().reference(forURL: "gs://spotmap-e3116.appspot.com/media/spotPostMedia/" + spotDetailsItem.key + "/" + postLink.key + ".jpeg")
                                            newStorageRef.put(data!, metadata: nil) { (metadata, error) in
                                                guard let metadata = metadata else {
                                                    // Uh-oh, an error occurred!
                                                    return
                                                }
                                                // Metadata contains file metadata such as size, content-type, and download URL.
                                                let downloadURL = metadata.downloadURL
                                            }
                                            
                                            // create thumbnail
                                            let image = UIImage(data: data!)
                                            let resizedImage = ResizeImage.resize(image: image!, targetSize: CGSize(width: 150.0, height: 150.0))
                                            let compressedImageData: Data = UIImageJPEGRepresentation(resizedImage, 0.8)!
                                            let newStorageRefForThumbnail = FIRStorage.storage().reference(forURL: "gs://spotmap-e3116.appspot.com/media/spotPostMedia/" + spotDetailsItem.key + "/" + postLink.key + "_thumbnail.jpeg")
                                            newStorageRefForThumbnail.put(compressedImageData, metadata: nil) { (metadata, error) in
                                                guard let metadata = metadata else {
                                                    // Uh-oh, an error occurred!
                                                    return
                                                }
                                                // Metadata contains file metadata such as size, content-type, and download URL.
                                                let downloadURL = metadata.downloadURL
                                            }
                                        }
                                    }
                                } else {
                                    let storageRef = FIRStorage.storage().reference(forURL: "gs://spotmap-e3116.appspot.com/media/spotPostMedia/" + postLink.key + ".m4v")
                                    let storageRefForThumbnail = FIRStorage.storage().reference(forURL: "gs://spotmap-e3116.appspot.com/media/spotPostMedia/" + postLink.key + "_thumbnail.jpeg")
                                    
                                    //transfer
                                    storageRef.data(withMaxSize: 10 * 1024 * 1024) { data, error in
                                        if let error = error {
                                            // Uh-oh, an error occurred!
                                            print(error.localizedDescription)
                                        } else {
                                            let newStorageRef = FIRStorage.storage().reference(forURL: "gs://spotmap-e3116.appspot.com/media/spotPostMedia/" + spotDetailsItem.key + "/" + postLink.key + ".m4v")
                                            newStorageRef.put(data!, metadata: nil) { (metadata, error) in
                                                guard let metadata = metadata else {
                                                    // Uh-oh, an error occurred!
                                                    return
                                                }
                                                // Metadata contains file metadata such as size, content-type, and download URL.
                                                let downloadURL = metadata.downloadURL
                                            }

                                        }
                                    }
                                    storageRefForThumbnail.data(withMaxSize: 10 * 1024 * 1024) { data, error in
                                        if let error = error {
                                            // Uh-oh, an error occurred!
                                            print(error.localizedDescription)
                                        } else {
                                            let newStorageRef = FIRStorage.storage().reference(forURL: "gs://spotmap-e3116.appspot.com/media/spotPostMedia/" + spotDetailsItem.key + "/" + postLink.key + "_thumbnail.jpeg")
                                            newStorageRef.put(data!, metadata: nil) { (metadata, error) in
                                                guard let metadata = metadata else {
                                                    // Uh-oh, an error occurred!
                                                    return
                                                }
                                                // Metadata contains file metadata such as size, content-type, and download URL.
                                                let downloadURL = metadata.downloadURL
                                            }
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

//
//  MigratingDataFromBELToFireBase.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 03.03.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage

class MigratingDataFromBELToFireBase {
    static func migrate(spotFromDB: [SpotDetails]) {
        let backendless = Backendless.sharedInstance()
        // here i will create data on firebase from this mass
        for spot in spotFromDB {
            // creating database objects
            let newSpotDetailsItemRef = FIRDatabase.database().reference(withPath: "MainDataBase/spotdetails").childByAutoId()
            let newSpotDetailsItemRefKey = newSpotDetailsItemRef.key
            
            let spotDetailsItem = SpotDetailsItem(name: spot.spotName,
                                                  description: spot.spotDescription,
                                                  latitude: spot.latitude,
                                                  longitude: spot.longitude,
                                                  addedByUser: "tPByXE5cX5QWSgmC18R3zZUvPVd2",
                                                  key: newSpotDetailsItemRefKey)
            
            newSpotDetailsItemRef.setValue(spotDetailsItem.toAnyObject())
            
            // migrating pictures from backendless to firebase
            // Get a reference to the storage service using the default Firebase App
            let storage = FIRStorage.storage()
            
            // Create a storage reference from our storage service
            let storageRef = storage.reference()
            
            // Data in memory
            let url = URL(string: "https://api.backendless.com/4B2C12D1-C6DE-7B3E-FFF0-80E7D3628C00/v1/files/media/spotMainPhotoURLs/" + (spot.objectId!).replacingOccurrences(of: "-", with: "") + ".jpeg")
            let data = try? Data(contentsOf: url!)
            
            // Create a reference to the file you want to upload
            let spotMainPhotoURLsRef = storageRef.child("media/spotMainPhotoURLs/" + newSpotDetailsItemRefKey + ".jpeg")
            
            // Upload the file to the path "media/spotMainPhotoURLs/" + newSpotDetailsItemRefKey + ".jpeg"
            let uploadTask = spotMainPhotoURLsRef.put(data!, metadata: nil) { (metadata, error) in
                guard let metadata = metadata else {
                    // Uh-oh, an error occurred!
                    return
                }
                // Metadata contains file metadata such as size, content-type, and download URL.
                let downloadURL = metadata.downloadURL
            }
            
            //*******************************************************************************************************************************************************************************************
            //SPOT POST PART OF MIGRATION TO FIREBASE
            let whereClause2 = "spot.objectId = '\(spot.objectId!)'"
            let dataQuery2 = BackendlessDataQuery()
            dataQuery2.whereClause = whereClause2
            
            var error2: Fault?
            let postList = backendless?.data.of(SpotPost.ofClass()).find(dataQuery2, fault: &error2)
            
            if error2 != nil {
                print("Server reported an error: \(error2?.detail)")
            }
            
            let postsFromDB = postList?.data as! [SpotPost]
            
            // here i will create data on firebase from this mass
            for post in postsFromDB {
                // creating database objects
                let newPostItemRef = FIRDatabase.database().reference(withPath: "MainDataBase/spotpost").childByAutoId()
                let newPostItemRefKey = newPostItemRef.key
                
                let postItem = SpotPostItem(isPhoto: post.isPhoto,
                                            description: post.postDescription!,
                                            addedByUser: "tPByXE5cX5QWSgmC18R3zZUvPVd2",
                                            key: newPostItemRefKey)
                
                newPostItemRef.setValue(postItem.toAnyObject())
                
                // migrating pictures from backendless to firebase
                // Get a reference to the storage service using the default Firebase App
                let storage2 = FIRStorage.storage()
                
                // Create a storage reference from our storage service
                let storageRef2 = storage2.reference()
                
                // Data in memory
                if post.isPhoto {
                    let url = URL(string: "https://api.backendless.com/4B2C12D1-C6DE-7B3E-FFF0-80E7D3628C00/v1/files/media/SpotPostPhotos/" + (post.objectId!).replacingOccurrences(of: "-", with: "") + ".jpeg")
                } else {
                    let url = URL(string: "https://api.backendless.com/4B2C12D1-C6DE-7B3E-FFF0-80E7D3628C00/v1/files/media/SpotPostVideos/" + (post.objectId!).replacingOccurrences(of: "-", with: "") + ".m4v")
                }
                let data = try? Data(contentsOf: url!)
                
                // Create a reference to the file you want to upload
                var newRef = "media/spotPostMedia/" + newSpotDetailsItemRefKey + "/" + newPostItemRefKey
                if post.isPhoto {
                    newRef += ".jpeg"
                } else {
                    newRef += ".m4a"
                }
                var postMediaRef = storageRef2.child(newRef)
                
                // Upload the file to the path "media/spotMainPhotoURLs/" + newSpotDetailsItemRefKey + ".jpeg"
                let uploadTask = postMediaRef.put(data!, metadata: nil) { (metadata, error) in
                    guard let metadata = metadata else {
                        // Uh-oh, an error occurred!
                        return
                    }
                    // Metadata contains file metadata such as size, content-type, and download URL.
                    let downloadURL = metadata.downloadURL
                }
                
                var postInSpotLink = "MainDataBase/spotdetails/" + newSpotDetailsItemRefKey
                let addPostsToSpotPost = FIRDatabase.database().reference(withPath: postInSpotLink).child("posts")//.child(newPostItemRefKey)
                
                addPostsToSpotPost.setValue([newPostItemRefKey: true])
            }
        }
    }
}

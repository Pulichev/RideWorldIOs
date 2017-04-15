//
//  PostMedia.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 15.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseStorage

struct PostMedia {
    static let refToSpotPostMedia = FIRStorage.storage().reference(forURL: "gs://spotmap-e3116.appspot.com/media/spotPostMedia/")
    
    static func getImageData270x270(for post: PostItem, completion: @escaping(_ imageData: Data?) -> Void) {
        let refToMedia = self.refToSpotPostMedia.child(post.spotId).child(post.key + "_resolution270x270.jpeg")
        
        refToMedia.downloadURL { (URL, error) in
            if let error = error {
                print("\(error)")
            } else {
                // async images downloading
                URLSession.shared.dataTask(with: URL!, completionHandler: { (data, response, error) in
                    if error != nil {
                        print("Error in URLSession: " + (error.debugDescription))
                        completion(nil)
                    } else {
                        completion(data)
                    }
                }).resume()
            }
        }
        
    }
}

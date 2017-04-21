//
//  SpotModel.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 17.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseStorage

struct SpotMedia {
   static let refToSpotMedia = FIRStorage.storage().reference(withPath: "media/spotMainPhotoURLs")
   
   static func upload(_ photo: UIImage, for spotId: String, with sizePx: Double) {
      let resizedPhoto = Image.resize(photo, targetSize: CGSize(width: sizePx, height: sizePx))
      let refToNewSpotPhoto = refToSpotMedia.child(spotId + ".jpeg")
      //saving original image with low compression
      let dataLowCompression: Data = UIImageJPEGRepresentation(resizedPhoto, 0.8)!
      refToNewSpotPhoto.put(dataLowCompression)
   }
   
   static func getImageURL(for spotId: String,
                           completion: @escaping (_ imageURL: URL?) -> Void) {
      
      let imageURL = refToSpotMedia.child(spotId + ".jpeg")
      
      imageURL.downloadURL { (URL, error) in
         if let error = error {
            print("\(error)")
            completion(nil)
         } else {
            completion(URL!)
         }
      }
   }
}

//
//  SpotModel.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 17.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseStorage

struct SpotMedia {
   static let refToSpotMainPhotoURLs = Storage.storage().reference(withPath: "media/spotMainPhotoURLs")
   static let refToSpotInfoPhotos = Storage.storage().reference(withPath: "media/spotInfoPhotos")
   
   static func upload(_ photo: UIImage, for spotId: String,
                      with sizePx: Double,
                      completion: @escaping (_ hasFinished: Bool, _ spot: String) -> Void) {
      let resizedPhoto = Image.resize(photo, targetSize: CGSize(width: sizePx, height: sizePx))
      let refToNewSpotPhoto = refToSpotMainPhotoURLs.child(spotId + ".jpeg")
      let dataLowCompression: Data = UIImageJPEGRepresentation(resizedPhoto, 1.0)!
      
      refToNewSpotPhoto.putData(dataLowCompression, metadata: nil) { (meta , error) in
         if error == nil {
            completion(true, (meta?.downloadURL()?.absoluteString)!)
         } else {
            completion(false, "")
         }
      }
   }
   
   static func uploadForInfo(_ photo: UIImage, for spotId: String, with sizePx: Double,
                             completion: @escaping (_ url: String?) -> Void) {
      let resizedPhoto = Image.resize(photo, targetSize: CGSize(width: sizePx, height: sizePx))
      let refToNewPhoto = refToSpotInfoPhotos.child(spotId).child(String(describing: Date()) + ".jpeg")
      let dataLowCompression: Data = UIImageJPEGRepresentation(resizedPhoto, 0.8)!
      
      refToNewPhoto.putData(dataLowCompression, metadata: nil) { (metadata , error) in
         if error == nil {
            let url = (metadata?.downloadURL()?.absoluteString)!
            Spot.addNewPhotoURL(for: spotId, url) { hasFinished in
               if hasFinished {
                  completion(url)
               }
            }
         } else {
            completion(nil)
         }
      }
   }
}

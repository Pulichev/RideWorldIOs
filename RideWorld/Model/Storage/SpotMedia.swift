//
//  SpotModel.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 17.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseStorage

struct SpotMedia {
   static let refToSpotMainPhotoURLs = FIRStorage.storage().reference(withPath: "media/spotMainPhotoURLs")
   static let refToSpotInfoPhotos = FIRStorage.storage().reference(withPath: "media/spotInfoPhotos")
   
   static func upload(_ photo: UIImage, for spotItem: SpotItem,
                      with sizePx: Double,
                      completion: @escaping (_ hasFinished: Bool, _ spot: SpotItem?) -> Void) {
      var spot = spotItem
      let resizedPhoto = Image.resize(photo, targetSize: CGSize(width: sizePx, height: sizePx))
      let refToNewSpotPhoto = refToSpotMainPhotoURLs.child(spot.key + ".jpeg")
      let dataLowCompression: Data = UIImageJPEGRepresentation(resizedPhoto, 0.8)!
      
      refToNewSpotPhoto.put(dataLowCompression, metadata: nil) { (meta , error) in
         if error == nil {
            spot.mainPhotoRef = (meta?.downloadURL()?.absoluteString)!
            completion(true, spot)
         } else {
            completion(false, nil)
         }
      }
   }
   
   static func uploadForInfo(_ photo: UIImage, for spotId: String, with sizePx: Double,
                             completion: @escaping (_ url: String?) -> Void) {
      let resizedPhoto = Image.resize(photo, targetSize: CGSize(width: sizePx, height: sizePx))
      let refToNewPhoto = refToSpotInfoPhotos.child(spotId).child(String(describing: Date()) + ".jpeg")
      let dataLowCompression: Data = UIImageJPEGRepresentation(resizedPhoto, 0.8)!
      
      refToNewPhoto.put(dataLowCompression, metadata: nil) { (metadata , error) in
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

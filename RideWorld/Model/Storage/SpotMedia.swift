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
   
   static func upload(_ photo: UIImage, for spotId: String, with sizePx: Double,
                      completion: @escaping (_ hasFinished: Bool) -> Void) {
      let resizedPhoto = Image.resize(photo, targetSize: CGSize(width: sizePx, height: sizePx))
      let refToNewSpotPhoto = refToSpotMainPhotoURLs.child(spotId + ".jpeg")
      //saving original image with low compression
      let dataLowCompression: Data = UIImageJPEGRepresentation(resizedPhoto, 0.8)!
      refToNewSpotPhoto.put(dataLowCompression, metadata: nil,
                            completion: {(_ , error) in
                              if error == nil {
                                 completion(true)
                              } else {
                                 completion(false)
                              }
      })
   }
   
   static func getImageURL(for spotId: String,
                           completion: @escaping (_ imageURL: URL?) -> Void) {
      let imageURL = refToSpotMainPhotoURLs.child(spotId + ".jpeg")
      
      imageURL.downloadURL { (URL, error) in
         if let error = error {
            print("\(error)")
            completion(nil)
         } else {
            completion(URL!)
         }
      }
   }
   
   static func uploadForInfo(_ photo: UIImage, for spotId: String, with sizePx: Double,
                             completion: @escaping (_ url: String?) -> Void) {
      let resizedPhoto = Image.resize(photo, targetSize: CGSize(width: sizePx, height: sizePx))
      let refToNewPhoto = refToSpotInfoPhotos.child(spotId).child(String(describing: Date()) + ".jpeg")
      let dataLowCompression: Data = UIImageJPEGRepresentation(resizedPhoto, 0.8)!
      refToNewPhoto.put(dataLowCompression, metadata: nil,
                            completion: { (metadata , error) in
                              if error == nil {
                                 let url = (metadata?.downloadURL()?.absoluteString)!
                                 Spot.addNewPhotoURL(for: spotId, url, completion: { hasFinished in
                                    if hasFinished {
                                       completion(url)
                                    }
                                 })
                              } else {
                                 completion(nil)
                              }
      })
   }
}

//
//  UserMedia.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 12.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseStorage

struct UserMedia {
  
  static let refToUserMainPhotoURLs = Storage.storage().reference(withPath: "media/userMainPhotoURLs")
  
  static func upload(for userId: String, with image: UIImage, withSize sizePx: Double,
                     completion: @escaping (_ hasFinished: Bool, _ url: String) -> Void) {
    let resizedPhoto = MyImage.resize(sourceImage: image, toWidth: CGFloat(sizePx)).image
    let sizePxInt    = Int(sizePx) // to generate link properly. It doesn't have ".0" in sizes
    let sizePxString = String(describing: sizePxInt)
    let userPhotoRef = refToUserMainPhotoURLs.child(userId + "_resolution" + sizePxString + "x" + sizePxString + ".jpeg")
    
    //with low compression
    let dataLowCompression: Data = UIImageJPEGRepresentation(resizedPhoto, 0.8)!
    userPhotoRef.putData(dataLowCompression, metadata: nil) { (meta , error) in
      if error == nil {
        // save url to post node
        completion(true, (meta?.downloadURL()?.absoluteString)!)
      } else {
        completion(false, "")
      }
    }
  }
}

//
//  UserMainPhotoModel.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 12.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseStorage

struct UserMainPhoto {
    // MARK: - Upload part
    static func upload(for userId: String, with image: UIImage, withSize sizePx: Double) {
        let resizedPhoto = ImageManipulations.resize(image: image, targetSize: CGSize(width: sizePx, height: sizePx))
        let sizePxInt = Int(sizePx) // to generate link properly. It doesn't have ".0" in sizes
        let sizePxString = String(describing: sizePxInt)
        let userPhotoRef = FIRStorage.storage().reference(withPath: "media/userMainPhotoURLs").child(userId + "_resolution" + sizePxString + "x" + sizePxString + ".jpeg")
        //with low compression
        let dataLowCompressionFor: Data = UIImageJPEGRepresentation(resizedPhoto, 0.8)!
        userPhotoRef.put(dataLowCompressionFor)
    }
    
    // MARK: - Download part
    static func getURL(for userId: String, withSize sizePx: Int,
                                    completion: @escaping (_ userPhotoURL: URL) -> Void) {
        let storage = FIRStorage.storage()
        let sizePxString = String(describing: sizePx)
        let url = "gs://spotmap-e3116.appspot.com/media/userMainPhotoURLs/" + userId + "_resolution" + sizePxString + "x" + sizePxString + ".jpeg"
        let riderPhotoURL = storage.reference(forURL: url)
        
        riderPhotoURL.downloadURL { (URL, error) in
            if let error = error {
                print("\(error)")
            } else {
                completion(URL!)
            }
        }
    }
}

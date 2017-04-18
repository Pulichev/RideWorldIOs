//
//  UserMainPhotoModel.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 12.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseStorage

struct UserMedia {
    static let refToUserMainPhotoURLs = FIRStorage.storage().reference(withPath: "media/userMainPhotoURLs")
    
    // MARK: - Upload part
    static func upload(for userId: String, with image: UIImage, withSize sizePx: Double) {
        let resizedPhoto = Image.resize(image, targetSize: CGSize(width: sizePx, height: sizePx))
        let sizePxInt = Int(sizePx) // to generate link properly. It doesn't have ".0" in sizes
        let sizePxString = String(describing: sizePxInt)
        let userPhotoRef = refToUserMainPhotoURLs.child(userId + "_resolution" + sizePxString + "x" + sizePxString + ".jpeg")
        //with low compression
        let dataLowCompression: Data = UIImageJPEGRepresentation(resizedPhoto, 0.8)!
        userPhotoRef.put(dataLowCompression)
    }
    
    // MARK: - Download part
    static func getURL(for userId: String, withSize sizePx: Int,
                       completion: @escaping (_ userPhotoURL: URL) -> Void) {
        let sizePxString = String(describing: sizePx)
        
        let riderPhotoURL = refToUserMainPhotoURLs.child(userId + "_resolution" + sizePxString + "x" + sizePxString + ".jpeg")
        
        riderPhotoURL.downloadURL { (URL, error) in
            if let error = error {
                print("\(error)")
            } else {
                completion(URL!)
            }
        }
    }
}

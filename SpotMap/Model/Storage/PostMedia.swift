//
//  PostMedia.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 15.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseStorage

struct PostMedia {
   static let refToPostMedia = FIRStorage.storage().reference(forURL: "gs://spotmap-e3116.appspot.com/media/spotPostMedia/")
   
   static func getImageData270x270(for post: PostItem, completion: @escaping(_ imageData: Data?) -> Void) {
      let refToMedia = refToPostMedia.child(post.spotId).child(post.key + "_resolution270x270.jpeg")
      
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
   
   static func getImageURL(for spotId: String, _ postId: String, withSize sizePx: Int,
                           completion: @escaping (_ imageURL: URL) -> Void) {
      let sizePxString = String(describing: sizePx)
      
      let imageURL = refToPostMedia.child(spotId + "/" + postId + "_resolution" + sizePxString + "x" + sizePxString + ".jpeg")
      
      imageURL.downloadURL { (URL, error) in
         if let error = error {
            print("\(error)")
         } else {
            completion(URL!)
         }
      }
   }
   
   static func getVideoURL(for spotId: String, _ postId: String,
                           completion: @escaping (_ videoURL: URL) -> Void) {
      let videoURL = self.refToPostMedia.child(spotId + "/" + postId + ".m4v")
      
      videoURL.downloadURL { (URL, error) in
         if let error = error {
            print("\(error)")
         } else {
            completion(URL!)
         }
      }
   }
   
   static func deletePhoto(for spotId: String, _ postId: String, withSize sizePx: Int) {
      let sizePxString = String(describing: sizePx)
      
      let photoURL = refToPostMedia.child(spotId).child(postId + "_resolution" + sizePxString + "x" + sizePxString + ".jpeg")
      
      photoURL.delete { (Error) in
         // do smth
      }
   }
   
   static func deleteVideo(for spotId: String, _ postId: String) {
      let videoURL = refToPostMedia.child(spotId).child(postId + ".m4v")
      
      videoURL.delete { (Error) in
         // do smth
      }
   }
   
   static func upload(_ image: UIImage, for post: PostItem, withSize sizePx: Double) {
      let resizedPhoto = Image.resize(image, targetSize: CGSize(width: sizePx, height: sizePx))
      let sizePxInt = Int(sizePx) // to generate link properly. It doesn't have ".0" in sizes
      let sizePxString = String(describing: sizePxInt)
      let postPhotoRef = refToPostMedia.child(post.spotId).child(post.key + "_resolution" + sizePxString + "x" + sizePxString + ".jpeg")
      //with low compression
      let dataLowCompression: Data = UIImageJPEGRepresentation(resizedPhoto, 0.8)!
      postPhotoRef.put(dataLowCompression)
   }
   
   static func upload(with video: URL, for post: PostItem) {
      do {
         let postVideoRef = refToPostMedia.child(post.spotId).child(post.key + ".m4v")
         
         let data = try Data(contentsOf: video, options: .mappedIfSafe)
         
         postVideoRef.put(data)
      } catch {
         print(error)
      }
   }
}

//
//  PostMedia.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 15.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseStorage
import FirebaseDatabase // TEMP

struct PostMedia {
   static let refToPostMedia = Storage.storage().reference(withPath: "media/spotPostMedia/")
   
   static func getImageData200x200(for post: PostItem,
                                   completion: @escaping(_ imageData: Data?) -> Void) {
      let refToMedia = refToPostMedia.child(post.spotId)
         .child(post.key + "_resolution200x200.jpeg")
      
      refToMedia.downloadURL { (URL, error) in
         if let error = error {
            print("\(error)")
         } else {
            // async images downloading
            URLSession.shared.dataTask(with: URL!) { (data, response, error) in
               if error != nil {
                  print("Error in URLSession: " + (error.debugDescription))
                  completion(nil)
               } else {
                  completion(data)
               }
               }.resume()
         }
      }
   }
   
   static func deletePhoto(for spotId: String, _ postId: String, withSize sizePx: Int) {
      let sizePxString = String(describing: sizePx)
      
      let photoURL = refToPostMedia.child(spotId)
         .child(postId + "_resolution" + sizePxString + "x" + sizePxString + ".jpeg")
      
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
   
   static func upload(_ image: UIImage, for post: PostItem, withSize sizePx: Double,
                      completion: @escaping (_ hasFinished: Bool, _ url: String) -> Void) {
      let resizedPhoto = Image.resize(image, targetSize: CGSize(width: sizePx, height: sizePx))
      let sizePxInt = Int(sizePx) // to generate link properly. It doesn't have ".0" in sizes
      let sizePxString = String(describing: sizePxInt)
      let postPhotoRef = refToPostMedia.child(post.spotId)
         .child(post.key + "_resolution" + sizePxString + "x" + sizePxString + ".jpeg")
      
      //with low compression
      let dataLowCompression: Data = UIImageJPEGRepresentation(resizedPhoto, 0.8)!
      postPhotoRef.putData(dataLowCompression, metadata: nil) { (meta , error) in
         if error == nil {
            // save url to post node
            completion(true, (meta?.downloadURL()?.absoluteString)!)
         } else {
            completion(false, "")
         }
      }
   }
   
   static func uploadPhotoForPost(_ image: UIImage, for postForUpdate: PostItem,
                                  completion: @escaping (_ hasFinished: Bool, _ postWithRef: PostItem?) -> Void) {
      var post = postForUpdate // we will insert refs to media to this object
      UIImageWriteToSavedPhotosAlbum(image, nil, nil , nil) //saving image to camera roll
      
      upload(image, for: post, withSize: 700.0) { (hasFinishedSuccessfully, url) in
         
         if hasFinishedSuccessfully {
            post.mediaRef700 = url
            
            upload(image, for: post, withSize: 200.0) { (hasFinishedSuccessfully, url) in
               
               if hasFinishedSuccessfully {
                  post.mediaRef200 = url
                  
                  upload(image, for: post, withSize: 70.0) { (hasFinishedSuccessfully, url) in
                     
                     if hasFinishedSuccessfully {
                        post.mediaRef70 = url
                        
                        upload(image, for: post, withSize: 10.0) { (hasFinishedSuccessfully, url) in
                           
                           if hasFinishedSuccessfully {
                              post.mediaRef10 = url
                              
                              completion(true, post)
                           } else {
                              completion(false, nil)
                           }
                        }
                     } else {
                        completion(false, nil)
                     }
                  }
               } else {
                  completion(false, nil)
               }
            }
         } else {
            completion(false, nil)
         }
      }
   }
   
   static func upload(with video: URL, for post: PostItem,
                      completion: @escaping (_ hasFinished: Bool, _ url: String) -> Void) {
      do {
         let postVideoRef = refToPostMedia.child(post.spotId).child(post.key + ".m4v")
         
         let data = try Data(contentsOf: video, options: .mappedIfSafe)
         
         postVideoRef.putData(data, metadata: nil) { (meta, error) in
            if error == nil {
               completion(true, (meta?.downloadURL()?.absoluteString)!)
            } else {
               completion(false, "")
            }
         }
      } catch {
         print(error)
         completion(false, "")
      }
   }
   
   // MARK: - Christmas tree
   // Like transaction :)
   // Bad view actually
   static func uploadVideoForPost(with videoURL: URL, for postForUpdate: PostItem,
                                  screenShot: UIImage,
                                  completion: @escaping (_ hasFinished: Bool, _ postWithRefs: PostItem?) -> Void) {
      var post = postForUpdate // we will insert refs to media to this object
      // upload screenshots
      upload(screenShot, for: post, withSize: 700.0)
      { (hasFinishedSuccessfully, url) in
         
         if hasFinishedSuccessfully {
            post.mediaRef700 = url
            
            upload(screenShot, for: post, withSize: 200.0)
            { (hasFinishedSuccessfully, url) in
               
               if hasFinishedSuccessfully {
                  post.mediaRef200 = url
                  
                  upload(screenShot, for: post, withSize: 70.0)
                  { (hasFinishedSuccessfully, url) in
                     
                     if hasFinishedSuccessfully {
                        post.mediaRef70 = url
                        
                        upload(screenShot, for: post, withSize: 10.0)
                        { (hasFinishedSuccessfully, url) in
                           
                           if hasFinishedSuccessfully {
                              post.mediaRef10 = url
                              
                              // upload video
                              upload(with: videoURL, for: post)
                              { (hasFinishedSuccessfully, url) in
                                 
                                 if hasFinishedSuccessfully {
                                    post.videoRef = url
                                    
                                    let path = videoURL.path
                                    
                                    if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path) {
                                       UISaveVideoAtPathToSavedPhotosAlbum(path, nil, nil, nil)
                                    }
                                    completion(true, post)
                                 } else {
                                    completion(false, nil)
                                 }
                              }
                           }else {
                              completion(false, nil)
                           }
                        }
                     } else {
                        completion(false, nil)
                     }
                  }
               } else {
                  completion(false, nil)
               }
            }
         } else {
            completion(false, nil)
         }
      }
   }
}

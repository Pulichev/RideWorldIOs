//
//  SpotInfoController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 30.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import Kingfisher
import Fusuma
import SVProgressHUD

class SpotInfoController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
   var spotInfo: SpotItem!
   var user: UserItem!
   
   @IBOutlet weak var photosCollection: UICollectionView!
   
   var photosURLs = [String]()
   
   @IBOutlet weak var name: UILabel!
   @IBOutlet weak var desc: UILabel!
   
   @IBOutlet weak var addedByUser: UIButton!
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      name.text = spotInfo.name
      desc.text = spotInfo.description
      
      initializePhotos()
      initUserLabel()
   }
   
   // MARK: - Photo collection part
   func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
      return photosURLs.count
   }
   
   func collectionView(_ collectionView: UICollectionView,
                       cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
      let cell = collectionView.dequeueReusableCell(
         withReuseIdentifier: "ImageCollectionViewCell", for: indexPath as IndexPath)
         as! ImageCollectionViewCell
      let photoURL = URL(string: photosURLs[indexPath.row])
      cell.postPicture.kf.setImage(with: photoURL!)
      
      return cell
   }
   
   private func initializePhotos() {
      self.photosURLs.append(self.spotInfo.mainPhotoRef)
      Spot.getAllPhotosURLs(for: spotInfo.key) { photoURLs in
         self.photosURLs.append(contentsOf: photoURLs)
         self.photosCollection.reloadData()
      }
   }
   
   // MARK: - initialize user
   private func initUserLabel() {
      UserModel.getItemById(for: spotInfo.addedByUser) { user in
         self.user = user
         self.addedByUser.setTitle(user.login, for: .normal)
      }
   }
   
   @IBAction func userButtonTapped(_ sender: Any) {
      if user.uid == UserModel.getCurrentUserId() {
         self.performSegue(withIdentifier: "goToUserProfileFromSpotInfo", sender: self)
      } else {
         self.performSegue(withIdentifier: "goToRidersProfileFromSpotInfo", sender: self)
      }
   }
   
   @IBOutlet weak var followSpotButton: UIBarButtonItem!
   
   @IBAction func followSpotButtonTapped(_ sender: Any) {
      
   }
   
   // MARK: - prepare for segue
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      switch segue.identifier! {
      case "goToRidersProfileFromSpotInfo":
         let newRidersProfileController = segue.destination as! RidersProfileController
         newRidersProfileController.ridersInfo = user
         newRidersProfileController.title = user.login
         
      case "goToUserProfileFromSpotInfo":
         let userProfileController = segue.destination as! UserProfileController
         userProfileController.cameFromSpotDetails = true
         
      default: break
      }
   }
}

//MARK: - Fusuma
extension SpotInfoController: FusumaDelegate {
   func fusumaMultipleImageSelected(_ images: [UIImage], source: FusumaMode) {
      
   }

   // MARK: - Add new photo part
   @IBAction func addPhotoButtonTapped(_ sender: Any) {
      let fusuma = FusumaViewController()
      fusuma.delegate = self
      fusuma.hasVideo = false // If you want to let the users allow to use video.
      present(fusuma, animated: true, completion: nil)
   }
   
   // MARK: FusumaDelegate Protocol
   func fusumaImageSelected(_ image: UIImage, source: FusumaMode) {
      switch source {
      case .camera:
         print("Image captured from Camera")
      case .library:
         print("Image selected from Camera Roll")
      default:
         print("Image selected")
      }
      
      SVProgressHUD.show()
      SpotMedia.uploadForInfo(image, for: spotInfo.key, with: 270.0) { url in
         if url != nil {
            self.photosURLs.append(url!)
            
            self.photosCollection.reloadData()
         }
         
         SVProgressHUD.dismiss()
      }
   }
   
   func fusumaImageSelected(_ image: UIImage) {
      //look example on https://github.com/ytakzk/Fusuma
   }
   
   func fusumaVideoCompleted(withFileURL fileURL: URL) {
      //If u want to use video in future - add code here. You can watch code in NewPostController.swift
   }
   
   func fusumaDismissedWithImage(_ image: UIImage, source: FusumaMode) {
      switch source {
      case .camera:
         print("Called just after dismissed FusumaViewController using Camera")
      case .library:
         print("Called just after dismissed FusumaViewController using Camera Roll")
      default:
         print("Called just after dismissed FusumaViewController")
      }
   }
   
   func fusumaCameraRollUnauthorized() {
      
      print("Camera roll unauthorized")
      
      let alert = UIAlertController(title: "Access Requested", message: "Saving image needs to access your photo album", preferredStyle: .alert)
      
      alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { (action) -> Void in
         
         if let url = URL(string:UIApplicationOpenSettingsURLString) {
            UIApplication.shared.openURL(url)
         }
         
      }))
      
      alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
         
      }))
      
      present(alert, animated: true, completion: nil)
   }
   
   func fusumaClosed() {
      print("Called when the FusumaViewController disappeared")
   }
   
   func fusumaWillClosed() {
      print("Called when the close button is pressed")
   }
}

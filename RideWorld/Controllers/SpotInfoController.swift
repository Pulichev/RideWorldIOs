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

class SpotInfoController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
   var spotInfo: SpotDetailsItem!
   
   @IBOutlet weak var photosCollection: UICollectionView!
   var photos = [UIImageView]()
   
   @IBOutlet weak var name: UILabel!
   @IBOutlet weak var desc: UILabel!
   
   @IBOutlet weak var addedByUser: UILabel!
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      name.text = spotInfo.name
      desc.text = spotInfo.description
   }
   
   // MARK: - Photo collection part
   func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
      return photos.count
   }
   
   func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCollectionViewCell", for: indexPath as IndexPath) as! ImageCollectionViewCell
      
      cell.postPicture.image = photos[indexPath.row].image!
      
      return cell
   }
}

//MARK: - Fusuma
extension SpotInfoController: FusumaDelegate {
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
      
      let imageView = UIImageView()
      imageView.image = image
      
      photos.append(imageView)

      photosCollection.reloadData()
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

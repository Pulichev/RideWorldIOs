//
//  CameraRollController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 21.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import YPImagePicker
import SVProgressHUD

class NewSpotController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
   var spotLatitude: Double!
   var spotLongitude: Double!
   
   @IBOutlet weak var spotTitle: UITextField!
   @IBOutlet var spotDescription: UITextView! {
      didSet {
         spotDescription.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
         spotDescription.layer.borderWidth = 1.0
         spotDescription.layer.cornerRadius = 5
      }
   }
   
   @IBOutlet weak var imageView: UIImageView!
   @IBOutlet weak var spotTypePicker: UIPickerView!
   
   override func viewDidLoad() {
      UICustomizing()
      
      spotTitle.delegate = self
      spotDescription.delegate = self
      
      //For scrolling the view if keyboard on
      NotificationCenter.default.addObserver(self, selector: #selector(NewSpotController.keyboardWillShow),
                                             name: NSNotification.Name.UIKeyboardWillShow, object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(NewSpotController.keyboardWillHide),
                                             name: NSNotification.Name.UIKeyboardWillHide, object: nil)
   }
   
   func UICustomizing() {
      //adding method on spot main photo tap
      addGestureToOpenCameraOnPhotoTap()
      imageView.image = UIImage(named: "plus-512.gif") //Setting default picture
   }
   
   func addGestureToOpenCameraOnPhotoTap() {
      let tap = UITapGestureRecognizer(target:self, action:#selector(takePhoto(_:)))
      imageView.addGestureRecognizer(tap)
      imageView.isUserInteractionEnabled = true
   }
   
   @IBAction func saveSpotDetails(_ sender: Any) {
      showSavingProgress()
      
      let currUserId = UserModel.getCurrentUserId()
      let newSpotKey = Spot.getNewSpotRefKey()
      let type = spotTypePicker.selectedRow(inComponent: 0)
      var newSpot = SpotItem(type: type, name: self.spotTitle.text!,
                             description: self.spotDescription.text!,
                             latitude: self.spotLatitude, longitude: self.spotLongitude,
                             addedByUser: currUserId, key: newSpotKey)
      
      // something like transaction. Start saving new
      // spot info only after media has beed uploaded
      SpotMedia.upload(imageView.image!, for: newSpotKey, with: 300.0)
      { (isSuccessfully, url) in
         if isSuccessfully {
            newSpot.mainPhotoRef = url
            Spot.create(newSpot) { hasAddedSpotSuccessfully in
               if hasAddedSpotSuccessfully {
                  //saving image to camera roll
                  UIImageWriteToSavedPhotosAlbum(self.imageView.image!, nil, nil , nil)
                  self.goBackToPosts()
               } else {
                  self.errorHappened()
               }
            }
         } else {
            self.errorHappened()
         }
      }
   }
   
   private func showSavingProgress() {
      SVProgressHUD.show()
      enableUserTouches = false
   }
   
   private func goBackToPosts() {
      SVProgressHUD.dismiss()
      self.enableUserTouches = true
      _ = self.navigationController?.popViewController(animated: true)
   }
   
   private func errorHappened() {
      SVProgressHUD.dismiss()
      self.enableUserTouches = true
      self.showAlertThatErrorInNewSpot()
   }
   
   private func showAlertThatErrorInNewSpot() {
      let alert = UIAlertController(title: "Creating new spot failed!", message: "Some error happened in new spot creating.", preferredStyle: .alert)
      
      alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
      
      present(alert, animated: true, completion: nil)
   }
   
   var enableUserTouches = true {
      didSet {
         if enableUserTouches {
            navigationController?.navigationBar.isUserInteractionEnabled = true
            navigationItem.hidesBackButton = false
            tabBarController?.tabBar.isUserInteractionEnabled = true
            imageView.isUserInteractionEnabled = true
         } else {
            navigationController?.navigationBar.isUserInteractionEnabled = false
            navigationItem.hidesBackButton = true
            tabBarController?.tabBar.isUserInteractionEnabled = false
            imageView.isUserInteractionEnabled = false
         }
      }
   }// for disabling user touches, while uploading
   
   var keyBoardAlreadyShowed = false //using this to not let app to scroll view. Look at extension
}

// MARK: - Picker delegate
extension NewSpotController: UIPickerViewDelegate, UIPickerViewDataSource {
   func numberOfComponents(in pickerView: UIPickerView) -> Int {
      return 1
   }
   
   func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
      return 3
   }
   
   func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
      switch row {
      case 0:
         return "Street"
      case 1:
         return "Park"
      case 2:
         return "Dirt"
      default:
         return ""
      }
   }
}

// MARK: - Camera extension
extension NewSpotController : GalleryControllerDelegate {
   
   @IBAction func takePhoto(_ sender: Any) {
      let gallery = GalleryController()
      gallery.delegate = self
      
      Config.Camera.imageLimit = 1
      Config.showsVideoTab = false
      
      present(gallery, animated: true, completion: nil)
   }
   
   func galleryController(_ controller: GalleryController, didSelectImages images: [UIImage]) {
      let img = images[0]
      
      self.imageView.image = img
      self.imageView.layer.cornerRadius = self.imageView.frame.size.height / 8
      self.imageView.layer.masksToBounds = true
      self.imageView.layer.borderWidth = 0
      
      controller.dismiss(animated: true, completion: nil)
   }
   
   func galleryController(_ controller: GalleryController, didSelectVideo video: Video) {
   }
   
   func galleryController(_ controller: GalleryController, requestLightbox images: [UIImage]) {
   }
   
   func galleryControllerDidCancel(_ controller: GalleryController) {
      controller.dismiss(animated: true, completion: nil)
   }
}

// MARK: - Scroll view on keyboard show/hide
extension NewSpotController {
   //if we tapped UITextField and then another UITextField
   func keyboardWillShow(notification: NSNotification) {
      if !keyBoardAlreadyShowed {
         view.frame.origin.y -= 200
         keyBoardAlreadyShowed = true
      }
   }
   
   func keyboardWillHide(notification: NSNotification) {
      view.frame.origin.y += 200
      keyBoardAlreadyShowed = false
   }
   
   override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
      for touch: AnyObject in touches {
         if !enableUserTouches {
            touch.view.isUserInteractionEnabled = false
         } else {
            touch.view.isUserInteractionEnabled = true
         }
      }
      
      view.endEditing(true)
   }
}


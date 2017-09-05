//
//  CameraRollController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 21.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import SVProgressHUD
import Gallery

protocol SpotInfoOnMapDelegate: class {
   func placeSpotOnMap(_ spot: SpotItem)
}

class NewSpotController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
   
   var cameForNewSpot: Bool! // true - new spot, false - modify
   var spot: SpotItem? // for modify
   @IBOutlet weak var modifyGeoPosButton: UIButtonX!
   var spotInfoOnMapDelegate: SpotInfoOnMapDelegate!
   
   var spotLatitude: Double!
   var spotLongitude: Double!
   
   @IBOutlet weak var scrollView: UIScrollView!
   @IBOutlet weak var spotTitle: UITextField!
   @IBOutlet var spotDescription: UITextView! {
      didSet {
         spotDescription.layer.cornerRadius = 5
         // creating placeholder
         spotDescription.text = NSLocalizedString("Write spot description", comment: "")
         spotDescription.textColor = UIColor.lightGray
         // see also func
      }
   }
   
   @IBOutlet weak var imageView: UIImageView!
   @IBOutlet weak var spotTypePicker: UIPickerView!
   
   var haveWeChoosedPhoto = false
   
   override func viewDidLoad() {
      UICustomizing()
      
      spotTitle.delegate = self
      spotDescription.delegate = self
      
      //For scrolling the view if keyboard on
      NotificationCenter.default.addObserver(self, selector: #selector(NewSpotController.keyboardWillShow),
                                             name: NSNotification.Name.UIKeyboardWillShow, object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(NewSpotController.keyboardWillHide),
                                             name: NSNotification.Name.UIKeyboardWillHide, object: nil)
      
      enableUserTouches = true
      
      addDismissingKeyboardOnScrollTap()
      
      if !cameForNewSpot { // for modify
         initFieldsForModify()
      }
   }
   
   private func initFieldsForModify() {
      spotTitle.text = spot!.name
      // init texts
      if spot!.description.isEmpty {
         spotDescription.text = NSLocalizedString("Write spot description", comment: "")
         spotDescription.textColor = UIColor.lightGray
      } else {
         spotDescription.text = spot!.description
         spotDescription.textColor = UIColor.black
      }
      
      spotLatitude = spot!.latitude
      spotLongitude = spot!.longitude
      
      spotTypePicker.selectRow(spot!.type, inComponent: 0, animated: true)
      
      imageView.kf.setImage(with: URL(string: spot!.mainPhotoRef))
      haveWeChoosedPhoto = true // it has been added already
      modifyGeoPosButton.isHidden = false
   }
   
   private func addDismissingKeyboardOnScrollTap() {
      let singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(singleTap))
      singleTapGestureRecognizer.numberOfTapsRequired = 1
      singleTapGestureRecognizer.isEnabled = true
      singleTapGestureRecognizer.cancelsTouchesInView = false
      scrollView.addGestureRecognizer(singleTapGestureRecognizer)
   }
   
   func singleTap() {
      view.endEditing(true)
   }
   
   func UICustomizing() {
      //adding method on spot main photo tap
      addGestureToOpenCameraOnPhotoTap()
      imageView.image = UIImage(named: "no photo") //Setting default picture
      imageView.tintColor = UIColor.myDarkBlue()
   }
   
   func addGestureToOpenCameraOnPhotoTap() {
      let tap = UITapGestureRecognizer(target: self, action:#selector(takePhoto(_:)))
      imageView.addGestureRecognizer(tap)
      imageView.isUserInteractionEnabled = true
   }
   
   @IBAction func saveSpotDetails(_ sender: Any) {
      if haveWeChoosedPhoto {
         if spotTitle.text! != "" { // dont let save without title
            showSavingProgress()
            
            if spotDescription.text == NSLocalizedString("Write spot description", comment: "")
            {
               // removing "placeholder" fake
               spotDescription.text = ""
            }
            
            var currUserId = ""
            var spotKey = ""
            if cameForNewSpot { // generating new
               currUserId = UserModel.getCurrentUserId()
               spotKey = Spot.getNewSpotRefKey()
            } else { // modify
               // take old
               currUserId = spot!.addedByUser
               spotKey = spot!.key
            }
            
            let type = spotTypePicker.selectedRow(inComponent: 0)
            var newSpot = SpotItem(type: type, name: spotTitle.text!,
                                   description: spotDescription.text!,
                                   latitude: spotLatitude, longitude: spotLongitude,
                                   addedByUser: currUserId, key: spotKey)
            
            // something like transaction. Start saving new
            // spot info only after media has beed uploaded
            SpotMedia.upload(imageView.image!, for: spotKey, with: 450.0)
            { (isSuccessfully, url) in
               if isSuccessfully {
                  newSpot.mainPhotoRef = url
                  Spot.create(newSpot) { hasAddedSpotSuccessfully in
                     if hasAddedSpotSuccessfully {
                        //saving image to camera roll
                        UIImageWriteToSavedPhotosAlbum(self.imageView.image!, nil, nil , nil)

                        self.spotInfoOnMapDelegate.placeSpotOnMap(newSpot)

                        self.goBack()
                     } else {
                        self.errorHappened()
                     }
                  }
               } else {
                  self.errorHappened()
               }
            }
         } else {
            showAlertWithError(text: NSLocalizedString("Enter title atleast", comment: ""))
         }
      } else {
         showAlertWithError(text: NSLocalizedString("Please, select spot photo", comment: ""))
      }
   }
   
   private func showAlertWithError(text: String) {
      let alert = UIAlertController(title: NSLocalizedString("Oops!", comment: ""),
                                    message: text,
                                    preferredStyle: .alert)
      
      alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
      
      present(alert, animated: true, completion: nil)
   }
   
   private func showSavingProgress() {
      SVProgressHUD.show()
      enableUserTouches = false
   }
   
   private func goBack() {
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
      let alert = UIAlertController(title: NSLocalizedString("Creating new spot failed!", comment: ""),
                                    message: NSLocalizedString("Some error happened in new spot creating.", comment: ""),
                                    preferredStyle: .alert)
      
      alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
      
      present(alert, animated: true, completion: nil)
   }
   
   var enableUserTouches: Bool! {
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
   } // for disabling user touches, while uploading
   
   var keyBoardAlreadyShowed = false //using this to not let app to scroll view. Look at extension
   
   // functions for textView placeholder
   func textViewDidBeginEditing(_ textView: UITextView) {
      if textView.textColor == UIColor.lightGray {
         textView.text = nil
         textView.textColor = UIColor.black
      }
   }
   
   func textViewDidEndEditing(_ textView: UITextView) {
      if textView.text.isEmpty {
         textView.text = NSLocalizedString("Write spot description", comment: "")
         textView.textColor = UIColor.lightGray
      }
   }
   
   @IBAction func modifyGeoPosButtonTapped(_ sender: Any) {
      performSegue(withIdentifier: "goToModifyGeoPos", sender: self)
   }
   
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      if segue.identifier! == "goToModifyGeoPos" {
         let newModifyGeoPosController = segue.destination as! ModifyGeoPosController
         newModifyGeoPosController.longitude = spot!.longitude
         newModifyGeoPosController.latitude = spot!.latitude
         newModifyGeoPosController.delegateNewGeoPos = self
      }
   }
}

extension NewSpotController: GeoPosDelegate {
   func sendGeoPos(_ latitude: Double, _ longitude: Double) {
      self.spotLatitude = latitude
      self.spotLongitude = longitude
   }
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
         return NSLocalizedString("Street", comment: "")
      case 1:
         return NSLocalizedString("Park", comment: "")
      case 2:
         return NSLocalizedString("Dirt", comment: "")
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
      
      haveWeChoosedPhoto = true
      
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
   // if we tapped UITextField and then another UITextField
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


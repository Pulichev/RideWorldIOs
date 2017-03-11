//
//  CameraRollController.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 21.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import Foundation
import UIKit
import Fusuma
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class NewSpotController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    var spotLatitude: Double!
    var spotLongitude: Double!
    
    @IBOutlet weak var spotTitle: UITextField!
    @IBOutlet var spotDescription: UITextView!
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        UICustomizing()
        
        self.spotTitle.delegate = self
        self.spotDescription.delegate = self
        
        //For scrolling the view if keyboard on
        NotificationCenter.default.addObserver(self, selector: #selector(NewSpotController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NewSpotController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func UICustomizing() {
        //adding method on spot main photo tap
        addGestureToOpenCameraOnPhotoTap()
        
        imageView.image = UIImage(named: "plus-512.gif") //Setting default picture
        
        placeBorderOnTextView()
    }
    
    func placeBorderOnTextView() {
        spotDescription.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
        spotDescription.layer.borderWidth = 1.0
        spotDescription.layer.cornerRadius = 5
    }
    
    func addGestureToOpenCameraOnPhotoTap() {
        let tap = UITapGestureRecognizer(target:self, action:#selector(takePhoto(_:)))
        imageView.addGestureRecognizer(tap)
        imageView.isUserInteractionEnabled = true
    }
    
    @IBAction func saveSpotDetails(_ sender: Any) {
        let userId = FIRAuth.auth()?.currentUser?.uid
        let newSpotRef = FIRDatabase.database().reference(withPath: "MainDataBase/spotdetails").childByAutoId()
        let newSpotRefKey = newSpotRef.key
        
        let newSpotDetailsItem = SpotDetailsItem(name: self.spotTitle.text!, description: self.spotDescription.text!,
                                              latitude: self.spotLatitude, longitude: self.spotLongitude, addedByUser: userId!, key: newSpotRefKey)
        newSpotRef.setValue(newSpotDetailsItem.toAnyObject())
        
        uploadPhoto(spotId: newSpotDetailsItem.key)
        UIImageWriteToSavedPhotosAlbum(self.imageView.image!, nil, nil , nil) //saving image to camera roll
        
        _ = navigationController?.popViewController(animated: true)
    }
    
    //Uploading files with the SYNC API
    func uploadPhoto(spotId: String) {
        let lowResolutionPhoto = ImageManipulations.resize(image: self.imageView.image!, targetSize: CGSize(width: 270.0, height: 270.0))
        let newPostRef = FIRStorage.storage().reference(withPath: "media/spotMainPhotoURLs").child(spotId + ".jpeg")
        //saving original image with low compression
        let dataLowCompression: Data = UIImageJPEGRepresentation(lowResolutionPhoto, 0.8)!
        newPostRef.put(dataLowCompression)
    }
    
    var keyBoardAlreadyShowed = false //using this to not let app to scroll view. Look at extension
}

//Fusuma
extension NewSpotController: FusumaDelegate {
    @IBAction func takePhoto(_ sender: Any) {
        let fusuma = FusumaViewController()
        fusuma.delegate = self
        fusuma.hasVideo = false // If you want to let the users allow to use video.
        self.present(fusuma, animated: true, completion: nil)
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
        
        imageView.image = image
        imageView.layer.cornerRadius = imageView.frame.size.height / 8
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 0
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
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func fusumaClosed() {
        print("Called when the FusumaViewController disappeared")
    }
    
    func fusumaWillClosed() {
        print("Called when the close button is pressed")
    }
}

//Keyboard manipulations
extension NewSpotController {
    //if we tapped UITextField and then another UITextField
    func keyboardWillShow(notification: NSNotification) {
        if !keyBoardAlreadyShowed {
            self.view.frame.origin.y -= 200
            keyBoardAlreadyShowed = true
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        self.view.frame.origin.y += 200
        keyBoardAlreadyShowed = false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}


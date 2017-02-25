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

class NewSpotController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    
    var backendless: Backendless!
    
    var spotLatitude: Double!
    var spotLongitude: Double!
    
    @IBOutlet weak var spotTitle: UITextField!
    @IBOutlet var spotDescription: UITextView!
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        backendless = Backendless.sharedInstance()
        
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
        let spotDetails = SpotDetails()
        spotDetails.latitude = self.spotLatitude
        spotDetails.longitude = self.spotLongitude
        spotDetails.spotName = self.spotTitle.text!
        spotDetails.spotDescription = self.spotDescription.text!
        
        let savedSpotID = backendless.persistenceService.of(spotDetails.ofClass()).save(spotDetails) as! SpotDetails
        uploadPhoto(spotID: savedSpotID.objectId!)
        UIImageWriteToSavedPhotosAlbum(self.imageView.image!, nil, nil , nil) //saving image to camera roll
        
        _ = navigationController?.popViewController(animated: true)
    }
    
    //Uploading files with the SYNC API
    func uploadPhoto(spotID: String) {
        let data: Data = UIImageJPEGRepresentation(self.imageView.image!, 0.1)!
        let spotPhotoUrl = "media/spotMainPhotoURLs/" + spotID.replacingOccurrences(of: "-", with: "") + ".jpeg"
        DispatchQueue.global(qos: .userInitiated).async {
            let uploadedFile = self.backendless.fileService.saveFile(spotPhotoUrl, content: data, overwriteIfExist: true)
            print("File has been uploaded. File URL is - \(uploadedFile?.fileURL)")
        }
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


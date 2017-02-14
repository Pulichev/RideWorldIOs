//
//  CameraRollController.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 21.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices

class NewSpotController: UIViewController, UIImagePickerControllerDelegate,
UINavigationControllerDelegate, UITextFieldDelegate {

    var backendless: Backendless!

    var spotLatitude: Double!
    var spotLongitude: Double!

    @IBOutlet weak var spotTitle: UITextField!
    @IBOutlet weak var spotDescription: UITextField!

    @IBOutlet weak var imageView: UIImageView!
    var newMedia: Bool?

    override func viewDidLoad() {
        backendless = Backendless.sharedInstance()

        imageView.image = UIImage(named: "plus-512.gif") //Setting default picture

        //adding method on spot main photo tap
        let tap = UITapGestureRecognizer(target:self, action:#selector(takePhoto(_:)))
        imageView.addGestureRecognizer(tap)
        imageView.isUserInteractionEnabled = true

        self.spotTitle.delegate = self
        self.spotDescription.delegate = self

        //For scrolling the view if keyboard on
        NotificationCenter.default.addObserver(self, selector: #selector(NewSpotController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NewSpotController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    @IBAction func takePhoto(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            let imagePicker = UIImagePickerController()

            imagePicker.delegate = self
            imagePicker.sourceType =
                UIImagePickerControllerSourceType.camera
            imagePicker.mediaTypes = [kUTTypeImage as String]
            imagePicker.allowsEditing = false

            self.present(imagePicker, animated: true, completion: nil)
            newMedia = true
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {

        let mediaType = info[UIImagePickerControllerMediaType] as! NSString

        self.dismiss(animated: true, completion: nil)

        if mediaType.isEqual(to: kUTTypeImage as String) {
            let image = info[UIImagePickerControllerOriginalImage]
                as! UIImage

            imageView.image = image
            imageView.layer.cornerRadius = imageView.frame.size.height / 8
            imageView.layer.masksToBounds = true
            imageView.layer.borderWidth = 0

            if (newMedia == true) {
                UIImageWriteToSavedPhotosAlbum(image, self,
                                               #selector(NewSpotController.image(image:didFinishSavingWithError:contextInfo:)), nil)
            } else if mediaType.isEqual(to: kUTTypeMovie as String) {
                // Code to support video here
            }
        }
    }

    func image(image: UIImage, didFinishSavingWithError error: NSErrorPointer, contextInfo: UnsafeRawPointer) {
        if error != nil {
            let alert = UIAlertController(title: "Save Failed",
                                          message: "Failed to save image",
                                          preferredStyle: UIAlertControllerStyle.alert)

            let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)

            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        }
    }

    @IBAction func saveSpotDetails(_ sender: Any) {
        let spotDetails = SpotDetails()
        spotDetails.latitude = self.spotLatitude
        spotDetails.longitude = self.spotLongitude
        spotDetails.spotName = self.spotTitle.text!
        spotDetails.spotDescription = self.spotDescription.text!

        let savedSpotID = backendless.persistenceService.of(spotDetails.ofClass()).save(spotDetails) as! SpotDetails
        uploadPhoto(spotID: savedSpotID.objectId!)

        self.performSegue(withIdentifier: "completeAdding", sender: self) //back to map
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

    var keyBoardAlreadyShowed = false //using this to not let app to scroll view
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

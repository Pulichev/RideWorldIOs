//
//  NewPostController.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 24.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import MobileCoreServices
import AVKit
import AVFoundation

class NewPostController: UIViewController, UIImagePickerControllerDelegate,
UINavigationControllerDelegate, UITextViewDelegate {
    
    var backendless: Backendless!
    
    var spotDetails: SpotDetails!
    
    @IBOutlet weak var postDescription: UITextView!
    @IBOutlet weak var photoOrVideoView: UIView!

    var newVideoUrl: Any!
    var newPhoto: UIImage!
    var newMedia: Bool?
    var isNewMediaIsPhoto: Bool? //if true - photo, false - video
    
    override func viewDidLoad() {
        backendless = Backendless.sharedInstance()
        
        UICustomizing()
        
        self.postDescription.delegate = self
        
        //For scrolling the view if keyboard on
        NotificationCenter.default.addObserver(self, selector: #selector(NewPostController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NewPostController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func UICustomizing() {
        //adding method on spot main photo tap
        addGestureToOpenCameraOnPhotoTap()
        let imageView = UIImageView()
        imageView.image = UIImage(named: "plus-512.gif") //Setting default picture
        imageView.layer.frame = self.photoOrVideoView.bounds
        photoOrVideoView.layer.addSublayer(imageView.layer)
        
        placeBorderOnTextField()
    }
    
    func placeBorderOnTextField() {
        postDescription.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
        postDescription.layer.borderWidth = 1.0
        postDescription.layer.cornerRadius = 5
    }
    
    func addGestureToOpenCameraOnPhotoTap() {
        let tap = UITapGestureRecognizer(target:self, action:#selector(takeMedia(_:)))
        photoOrVideoView.addGestureRecognizer(tap)
        photoOrVideoView.isUserInteractionEnabled = true
    }
    
    //TextView max count of symbols = 150
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.characters.count
        return numberOfChars < 150
    }
    
    @IBAction func takeMedia(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            let imagePicker = UIImagePickerController()
            
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.camera
            imagePicker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as NSString as String]
            imagePicker.allowsEditing = false
            
            self.present(imagePicker, animated: true, completion: nil)
            newMedia = true
        }
    }
    
    //TODO: MAKE NOT AN IMAGE IN CELLS, SPOTADD and etc -> UIVIEW
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        self.photoOrVideoView.layer.sublayers?.forEach { $0.removeFromSuperlayer() } //deleting old data from view (photo or video)
        
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        
        self.dismiss(animated: true, completion: nil)
        
        if mediaType.isEqual(to: kUTTypeImage as String) { //photo
            self.isNewMediaIsPhoto = true
            
            let imageView = UIImageView()
            let image = info[UIImagePickerControllerOriginalImage]
                as! UIImage
            
            self.newPhoto = image
            imageView.image = image
            imageView.layer.frame = self.photoOrVideoView.bounds
            
            self.photoOrVideoView.layer.addSublayer(imageView.layer)
            
            UIImageWriteToSavedPhotosAlbum(image, self,
                                           #selector(NewPostController.image(image:didFinishSavingWithError:contextInfo:)), nil)
        } else { //video
            self.isNewMediaIsPhoto = false
            
            // Handle a movie capture
            if mediaType == kUTTypeMovie {
                //TODO: Add returning video on new post details like photo
                
                let player = AVPlayer(url: (info[UIImagePickerControllerMediaURL] as! NSURL) as URL!)
                let playerLayer = AVPlayerLayer(player: player)
                playerLayer.frame = self.photoOrVideoView.bounds
                
                self.photoOrVideoView.layer.addSublayer(playerLayer)
                
                player.play()
                
                self.newVideoUrl = info[UIImagePickerControllerMediaURL]
                
                guard let path = (self.newVideoUrl as! NSURL).path else { return }
                if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path) {
                    UISaveVideoAtPathToSavedPhotosAlbum(path, self,
                                                        #selector(NewPostController.video(videoPath:didFinishSavingWithError:contextInfo:)), nil)
                }
            }
        }
    }
    
    func image(image: UIImage, didFinishSavingWithError error: NSErrorPointer, contextInfo:UnsafeRawPointer) {
        if error != nil {
            let alert = UIAlertController(title: "Save Failed",
                                          message: "Failed to save image",
                                          preferredStyle: UIAlertControllerStyle.alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func video(videoPath: NSString, didFinishSavingWithError error: NSError?, contextInfo info: AnyObject) {
        if error != nil {
            let alert = UIAlertController(title: "Save Failed",
                                          message: "Failed to save video",
                                          preferredStyle: UIAlertControllerStyle.alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func saveSpotDetails(_ sender: Any) {
        let defaults = UserDefaults.standard
        let userId = defaults.string(forKey: "userLoggedInObjectId")
        
        let spotPost = SpotPost()
        spotPost.userId = userId
        spotPost.spotId = spotDetails.objectId
        spotPost.postDescription = self.postDescription.text
        
        let savedSpotPostID = backendless.persistenceService.of(spotPost.ofClass()).save(spotPost) as! SpotPost
        if (self.isNewMediaIsPhoto)! {
            uploadPhoto(postId: savedSpotPostID.objectId!)
        } else {
            uploadVideo(postId: savedSpotPostID.objectId!)
        }
        
        self.performSegue(withIdentifier: "backToPosts", sender: self) //back to spot posts
    }
    
    //Uploading files with the SYNC API
    func uploadPhoto(postId: String) {
        let data: Data = UIImageJPEGRepresentation(self.newPhoto!, 0.3)!
        let postPhotoUrl = "media/SpotPostPhotos/" + postId.replacingOccurrences(of: "-", with: "") + ".jpeg"
        DispatchQueue.global(qos: .userInitiated).async {
            let uploadedFile = self.backendless.fileService.saveFile(postPhotoUrl, content: data, overwriteIfExist: true)
            print("File has been uploaded. File URL is - \(uploadedFile?.fileURL!)")
        }
    }
    
    func uploadVideo(postId: String) {
        do {
            let data = try Data(contentsOf: self.newVideoUrl as! URL, options: .mappedIfSafe)
            
            let postVideoUrl = "media/SpotPostVideos/" + postId.replacingOccurrences(of: "-", with: "") + ".m4v"
            DispatchQueue.global(qos: .userInitiated).async {
                let uploadedFile = self.backendless.fileService.saveFile(postVideoUrl, content: data, overwriteIfExist: true)
                print("File has been uploaded. File URL is - \(uploadedFile?.fileURL!)")
            }
        } catch {
            print(error)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "backToPosts") {
            let spotDetailsController = (segue.destination as! SpotDetailsController)
            spotDetailsController.spotDetails = self.spotDetails
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
    }}

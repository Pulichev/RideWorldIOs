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
    var player: AVQueuePlayer!
    var playerLooper: NSObject? //for looping video. It should be class variable
    
    var photoView = UIImageView()
    
    var newMedia: Bool?
    var isNewMediaIsPhoto = true //if true - photo, false - video. Default - true
    
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
        photoView.image = UIImage(named: "plus-512.gif") //Setting default picture
        photoView.layer.frame = self.photoOrVideoView.bounds
        photoOrVideoView.layer.addSublayer(photoView.layer)
        
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
        return numberOfChars < 100
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
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        self.photoOrVideoView.layer.sublayers?.forEach { $0.removeFromSuperlayer() } //deleting old data from view (photo or video)
        
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        
        self.dismiss(animated: true, completion: nil)
        
        if mediaType.isEqual(to: kUTTypeImage as String) { //photo
            newPhotoAdded(info: info)
        } else {
            if mediaType == kUTTypeMovie { //video
                // Handle a movie capture
                newVideoAdded(info: info)
            }
        }
    }
    
    func image(image: UIImage, didFinishSavingWithError error: NSErrorPointer, contextInfo: UnsafeRawPointer) {
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
    
    func newPhotoAdded(info: [String: Any]) {
        self.isNewMediaIsPhoto = true
        
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        self.photoView.image = image
        self.photoView.contentMode = .scaleAspectFill
        
        self.photoOrVideoView.layer.addSublayer(photoView.layer)
        
        UIImageWriteToSavedPhotosAlbum(image, self,
                                       #selector(NewPostController.image(image:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    func newVideoAdded(info: [String: Any]) {
        self.isNewMediaIsPhoto = false
        self.photoView.image = nil
        
        player = AVQueuePlayer()
        
        let playerLayer = AVPlayerLayer(player: player)
        let playerItem = AVPlayerItem(url: (info[UIImagePickerControllerMediaURL] as! NSURL) as URL!)
        playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
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
    
    @IBAction func saveSpotDetails(_ sender: Any) {
        let defaults = UserDefaults.standard
        let userId = defaults.string(forKey: "userLoggedInObjectId")
        
        let spotPost = SpotPost()
        spotPost.userId = userId
        spotPost.spotId = spotDetails.objectId
        spotPost.postDescription = self.postDescription.text
        if self.isNewMediaIsPhoto {
            spotPost.isPhoto = true
        } else {
            spotPost.isPhoto = false
        }
        
        let savedSpotPostID = backendless.persistenceService.of(spotPost.ofClass()).save(spotPost) as! SpotPost
        if self.isNewMediaIsPhoto {
            uploadPhoto(postId: savedSpotPostID.objectId!)
        } else {
            uploadVideo(postId: savedSpotPostID.objectId!)
            player.pause()
            player = nil
        }
        
        self.performSegue(withIdentifier: "backToPosts", sender: self) //back to spot posts
    }
    
    //Uploading files with the SYNC API
    func uploadPhoto(postId: String) {
        //saving original image with low compression
        let dataLowCompression: Data = UIImageJPEGRepresentation(self.photoView.image!, 0.3)!
        let postPhotoUrlLowCompression = "media/SpotPostPhotos/" + postId.replacingOccurrences(of: "-", with: "") + ".jpeg"
        
        //saving thumbnail image with high compression
        let thumbnail = resizeImage(image: self.photoView.image!, targetSize: CGSize.init(width: 300, height: 300))
        let dataHighCompression: Data = UIImageJPEGRepresentation(thumbnail, 0.5)!
        let postPhotoUrlHighCompression = "media/spotPostMediaThumbnails/" + postId.replacingOccurrences(of: "-", with: "") + ".jpeg"
        DispatchQueue.global(qos: .userInitiated).async {
            //saving original image with low compression
            let uploadedFileLowCompression = self.backendless.fileService.saveFile(postPhotoUrlLowCompression, content: dataLowCompression, overwriteIfExist: true)
            print("File has been uploaded. File URL is - \(uploadedFileLowCompression?.fileURL!)")
            
            //saving thumbnail image with high compression
            let uploadedFileHighCompression = self.backendless.fileService.saveFile(postPhotoUrlHighCompression, content: dataHighCompression, overwriteIfExist: true)
            print("File has been uploaded. File URL is - \(uploadedFileHighCompression?.fileURL!)")
        }
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    func uploadVideo(postId: String) {
        do {
            //saving video
            let data = try Data(contentsOf: self.newVideoUrl as! URL, options: .mappedIfSafe)
            
            let postVideoUrl = "media/SpotPostVideos/" + postId.replacingOccurrences(of: "-", with: "") + ".m4v"
            DispatchQueue.global(qos: .userInitiated).async {
                let uploadedFile = self.backendless.fileService.saveFile(postVideoUrl, content: data, overwriteIfExist: true)
                print("File has been uploaded. File URL is - \(uploadedFile?.fileURL!)")
            }
            
            //saving thumbnail for video
            let asset = AVURLAsset(url: self.newVideoUrl as! URL , options: nil)
            
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            
            let dataThumbnailForVideo: Data = UIImageJPEGRepresentation(thumbnail, 0.1)!
            let postThumbnailForVideo = "media/spotPostMediaThumbnails/" + postId.replacingOccurrences(of: "-", with: "") + ".jpeg"
            DispatchQueue.global(qos: .userInitiated).async {
                let uploadedFile = self.backendless.fileService.saveFile(postThumbnailForVideo, content: dataThumbnailForVideo, overwriteIfExist: true)
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
    }
}

//
//  NewPostController.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 24.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import AVFoundation
import Fusuma

class NewPostController: UIViewController, UITextViewDelegate {
    var spotDetailsItem: SpotDetailsItem!
    
    @IBOutlet weak var postDescription: UITextView!
    @IBOutlet weak var photoOrVideoView: UIView!
    
    var newVideoUrl: URL!
    var player: AVQueuePlayer!
    var playerLooper: NSObject? //for looping video. It should be class variable
    
    var photoView = UIImageView()
    
    var isNewMediaIsPhoto = true //if true - photo, false - video. Default - true
    
    override func viewDidLoad() {
        UICustomizing()
        
        self.postDescription.delegate = self
        
        //For scrolling the view if keyboard on
        NotificationCenter.default.addObserver(self, selector: #selector(NewPostController.keyboardWillShow),
                                               name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NewPostController.keyboardWillHide),
                                               name: NSNotification.Name.UIKeyboardWillHide, object: nil)
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
    
    // NEED CODE REVIEW HERE
    @IBAction func savePost(_ sender: Any) {
        let currentUser = User.getCurrentUser()
        let createdDate = String(describing: Date())
        let postItem = PostItem(self.isNewMediaIsPhoto, self.postDescription.text, createdDate, self.spotDetailsItem.key, currentUser.uid)
        
        let newPost = Post.add(postItem)
        User.addPost(to: currentUser.uid, newPost.key)
        Spot.addPost(to: self.spotDetailsItem.key, newPost.key)
        
        if self.isNewMediaIsPhoto {
            UIImageWriteToSavedPhotosAlbum(self.photoView.image!, nil, nil , nil) //saving image to camera roll
            PostMedia.upload(self.photoView.image!, for: newPost, withSize: 700.0)
            PostMedia.upload(self.photoView.image!, for: newPost, withSize: 270.0) // for profile collection
            PostMedia.upload(self.photoView.image!, for: newPost, withSize: 10.0) // thumbnail
        } else {
            PostMedia.upload(with: self.newVideoUrl, for: newPost)
            PostMedia.upload(generateVideoScreenShot(), for: newPost, withSize: 270.0)
            PostMedia.upload(generateVideoScreenShot(), for: newPost, withSize: 10.0)
            
            let path = (self.newVideoUrl).path
            
            if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path) {
                UISaveVideoAtPathToSavedPhotosAlbum(path, nil, nil, nil)
            }
            
            player.pause()
            player = nil
        }
        
        _ = navigationController?.popViewController(animated: true)
    }
    
    func generateVideoScreenShot() -> UIImage {
        do {
            let asset = AVURLAsset(url: self.newVideoUrl, options: nil)
            
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
            let videoScreenShot = UIImage(cgImage: cgImage)
            
            return videoScreenShot
        } catch {
            print(error)
            
            let failImage = UIImage(named: "plus-512.gif")
            
            return failImage!
        }
    }
}

//Fusuma
extension NewPostController: FusumaDelegate {
    @IBAction func takeMedia(_ sender: Any) {
        let fusuma = FusumaViewController()
        fusuma.delegate = self
        fusuma.hasVideo = true // If you want to let the users allow to use video.
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
        
        self.isNewMediaIsPhoto = true
        
        self.photoView.image = image
        self.photoView.contentMode = .scaleAspectFill
        
        self.photoOrVideoView.layer.addSublayer(photoView.layer)
    }
    
    func fusumaImageSelected(_ image: UIImage) {
        //look example on https://github.com/ytakzk/Fusuma
    }
    
    func fusumaVideoCompleted(withFileURL fileURL: URL) {
        self.isNewMediaIsPhoto = false
        self.photoView.image = nil
        
        player = AVQueuePlayer()
        
        let playerLayer = AVPlayerLayer(player: player)
        let playerItem = AVPlayerItem(url: fileURL)
        playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        playerLayer.frame = self.photoOrVideoView.bounds
        
        self.photoOrVideoView.layer.addSublayer(playerLayer)
        
        player.play()
        
        self.newVideoUrl = fileURL
        
        let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + NSUUID().uuidString + ".m4v")
        
        compressVideo(inputURL: fileURL as URL, outputURL: compressedURL) { (exportSession) in
            guard let session = exportSession else {
                return
            }
            
            switch session.status {
            case .unknown:
                break
            case .waiting:
                break
            case .exporting:
                break
            case .completed:
                guard let compressedData = NSData(contentsOf: compressedURL) else {
                    return
                }
                
                print("File size after compression: \(Double(compressedData.length / 1048576)) mb")
            case .failed:
                break
            case .cancelled:
                break
            }
        }
        
        self.newVideoUrl = compressedURL //update newVideoUrl to already compressed video
        
        print("video completed and output to file: \(fileURL)")
    }
    
    func compressVideo(inputURL: URL, outputURL: URL, handler:@escaping (_ exportSession: AVAssetExportSession?)-> Void) {
        let urlAsset = AVURLAsset(url: inputURL, options: nil)
        guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPreset640x480) else {
            handler(nil)
            
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileTypeQuickTimeMovie
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously { () -> Void in
            handler(exportSession)
        }
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
extension NewPostController {
    //if we tapped UITextField and then another UITextField
    func keyboardWillShow(notification: NSNotification) {
        self.view.frame.origin.y -= 200
    }
    
    func keyboardWillHide(notification: NSNotification) {
        self.view.frame.origin.y += 200
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

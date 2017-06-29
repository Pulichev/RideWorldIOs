//
//  NewPostController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 24.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import AVFoundation
import Fusuma
import SVProgressHUD

class NewPostController: UIViewController, UITextViewDelegate {
   var spotDetailsItem: SpotItem!
   
   @IBOutlet weak var postDescription: UITextView! {
      didSet {
         postDescription.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
         postDescription.layer.borderWidth = 1.0
         postDescription.layer.cornerRadius = 5
      }
   }
   @IBOutlet weak var photoOrVideoView: MediaContainerView!
   
   // MARK: - Media vars part
   var newVideoUrl: URL!
   var player: AVQueuePlayer!
   var playerLooper: NSObject? //for looping video. It should be class variable
   
   var photoView = UIImageView()
   
   @IBOutlet weak var mediaContainerHeight: NSLayoutConstraint!
   var mediaAspectRatio: Double!
   
   var isNewMediaIsPhoto = true //if true - photo, false - video. Default - true
   
   override func viewDidLoad() {
      UICustomizing()
      
      postDescription.delegate = self
      
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
      photoView.layer.contentsGravity = kCAGravityResize
      photoView.contentMode = .scaleAspectFill
      photoView.layer.frame = photoOrVideoView.bounds
      photoOrVideoView.layer.addSublayer(photoView.layer)
      photoOrVideoView.playerLayer = photoView.layer
   }
   
   func addGestureToOpenCameraOnPhotoTap() {
      let tap = UITapGestureRecognizer(target:self, action:#selector(takeMedia(_:)))
      photoOrVideoView.addGestureRecognizer(tap)
      photoOrVideoView.isUserInteractionEnabled = true
   }
   
   //TextView max count of symbols = 150
   func textView(_ textView: UITextView,
                 shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
      let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
      let numberOfChars = newText.characters.count
      return numberOfChars < 100
   }
   
   @IBAction func savePost(_ sender: Any) {
      showSavingProgress()
      
      let postItem = createNewPostItem()
      
      // first - upload media. On completion - save post info data
      if isNewMediaIsPhoto {
         uploadPhoto(for: postItem)
      } else {
         uploadVideo(for: postItem)
      }
   }
   
   private func createNewPostItem() -> PostItem {
      let currentUser = UserModel.getCurrentUser()
      let createdDate = String(describing: Date())
      let newPostId = Post.getNewPostId()
      let postItem = PostItem(isNewMediaIsPhoto, postDescription.text,
                              createdDate, spotDetailsItem.key,
                              currentUser.uid, newPostId)
      return postItem
   }
   
   private func uploadPhoto(for postItem: PostItem) {
      PostMedia.uploadPhotoForPost(
         photoView.image!,
         for: postItem) { (hasFinishedUploading, post) in
            if hasFinishedUploading {
               Post.add(post!) { hasFinishedSuccessfully in
                  if hasFinishedSuccessfully {
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
   
   private func uploadVideo(for postItem: PostItem) {
      let screenshot = generateVideoScreenShot()
      
      PostMedia.uploadVideoForPost(
         with: newVideoUrl, for: postItem,
         screenShot: screenshot,
         aspectRatio: mediaAspectRatio) { (hasFinishedUploading, post) in
            if hasFinishedUploading {
               Post.add(post!) { hasFinishedSuccessfully in
                  if hasFinishedSuccessfully {
                     self.player.pause()
                     self.player = nil
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
      self.showAlertThatErrorInNewPost()
   }
   
   func generateVideoScreenShot() -> UIImage {
      do {
         let asset = AVURLAsset(url: newVideoUrl, options: nil)
         
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
   
   private func showAlertThatErrorInNewPost() {
      let alert = UIAlertController(title: "Creating new post failed!", message: "Some error happened in new post creating.", preferredStyle: .alert)
      
      alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
      
      present(alert, animated: true, completion: nil)
   }
   
   var enableUserTouches = true {
      didSet {
         if enableUserTouches {
            navigationController?.navigationBar.isUserInteractionEnabled = true
            navigationItem.hidesBackButton = false
            tabBarController?.tabBar.isUserInteractionEnabled = true
            photoOrVideoView.isUserInteractionEnabled = true
         } else {
            navigationController?.navigationBar.isUserInteractionEnabled = false
            navigationItem.hidesBackButton = true
            tabBarController?.tabBar.isUserInteractionEnabled = false
            photoOrVideoView.isUserInteractionEnabled = false
         }
      }
   } // for disabling user touches, while uploading
}

//Fusuma
extension NewPostController: FusumaDelegate {
   func fusumaMultipleImageSelected(_ images: [UIImage], source: FusumaMode) {
      
   }
   
   @IBAction func takeMedia(_ sender: Any) {
      let fusuma = FusumaViewController()
      fusuma.delegate = self
      fusuma.hasVideo = true // If you want to let the users allow to use video.
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
      
      isNewMediaIsPhoto = true
      mediaAspectRatio = image.aspectRatio
      
      setPhoto(image)
   }
   
   func fusumaImageSelected(_ image: UIImage) {
      //look example on https://github.com/ytakzk/Fusuma
      mediaAspectRatio = image.aspectRatio
      
      setPhoto(image)
   }
   
   func setPhoto(_ image: UIImage) {
      changeMediaContainerHeight()

      photoView.image = image
      photoView.layer.contentsGravity = kCAGravityResize
      photoView.contentMode = .scaleAspectFill
      photoView.frame = photoOrVideoView.bounds
      
      photoOrVideoView.layer.addSublayer(photoView.layer)
      photoOrVideoView.playerLayer = photoView.layer
   }
   
   func changeMediaContainerHeight() {
      let width = view.frame.size.width
      let height = CGFloat(Double(width) * mediaAspectRatio)
      mediaContainerHeight.constant = height
      
      photoOrVideoView.layoutIfNeeded()
   }
   
   func fusumaVideoCompleted(withFileURL fileURL: URL) {
      initAspectRatioOfVideo(with: fileURL)
      
      changeMediaContainerHeight()
      
      isNewMediaIsPhoto = false
      
      player = AVQueuePlayer()
      
      let playerLayer = AVPlayerLayer(player: player)
      let playerItem = AVPlayerItem(url: fileURL)
      playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
      playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
      playerLayer.frame = photoOrVideoView.bounds
      photoOrVideoView.layer.addSublayer(playerLayer)
      photoOrVideoView.playerLayer = playerLayer
      
      player.play()
      
      newVideoUrl = fileURL
      
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
      
      newVideoUrl = compressedURL //update newVideoUrl to already compressed video
      
      print("video completed and output to file: \(fileURL)")
   }
   
   private func initAspectRatioOfVideo(with fileURL: URL) {
      let resolution = resolutionForLocalVideo(url: fileURL)
      
      let width = resolution?.width
      let height = resolution?.height
      
      mediaAspectRatio = Double(height! / width!)
   }
   
   func resolutionForLocalVideo(url: URL) -> CGSize? {
      guard let track = AVURLAsset(url: url).tracks(withMediaType: AVMediaTypeVideo).first else { return nil }
      let size = track.naturalSize.applying(track.preferredTransform)
      return CGSize(width: fabs(size.width), height: fabs(size.height))
   }
   
   func compressVideo(inputURL: URL, outputURL: URL, handler:@escaping (_ exportSession: AVAssetExportSession?)-> Void) {
      let urlAsset = AVURLAsset(url: inputURL, options: nil)
      guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetMediumQuality) else {
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
      
      mediaAspectRatio = image.aspectRatio
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

//Keyboard manipulations
extension NewPostController {
   //if we tapped UITextField and then another UITextField
   func keyboardWillShow(notification: NSNotification) {
      view.frame.origin.y -= 200
   }
   
   func keyboardWillHide(notification: NSNotification) {
      view.frame.origin.y += 200
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

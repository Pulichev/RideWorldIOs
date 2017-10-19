//
//  NewPostController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 24.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import AVFoundation
import SVProgressHUD
import Gallery
import AVKit
import Photos

class NewPostController: UIViewController, UITextViewDelegate {
  
  var spotDetailsItem: SpotItem!
  
  @IBOutlet weak var scrollView: UIScrollView!
  
  @IBOutlet weak var postDescription: UITextView! {
    didSet {
      postDescription.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
      postDescription.layer.borderWidth = 1.0
      postDescription.layer.cornerRadius = 5
      postDescription.layer.cornerRadius = 5
      // creating placeholder
      postDescription.text = NSLocalizedString("Write post description", comment: "")
      postDescription.textColor = UIColor.lightGray
      // see also func
    }
  }
  @IBOutlet weak var photoOrVideoView: AVPlayerView!
  
  // MARK: - Media vars part
  var newVideoUrl: URL!
  var player: AVPlayer! // for iOS 9 - 9.3.5
  
  var photoView = UIImageView()
  
  @IBOutlet weak var mediaContainerHeight: NSLayoutConstraint!
  var mediaAspectRatio: Double!
  
  var haveWeChoosedMedia = false
  var isNewMediaIsPhoto = true // if true - photo, false - video. Default - true
  
  override func viewDidLoad() {
    UICustomizing()
    editor = AdvancedVideoEditor()
    postDescription.delegate = self
    
    //For scrolling the view if keyboard on
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(NewPostController.keyboardWillShow),
                                           name: NSNotification.Name.UIKeyboardWillShow,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(NewPostController.keyboardWillHide),
                                           name: NSNotification.Name.UIKeyboardWillHide,
                                           object: nil)
    enableUserTouches = true
    addDismissingKeyboardOnScrollTap()
  }
  
  private func addDismissingKeyboardOnScrollTap() {
    let singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(singleTap))
    singleTapGestureRecognizer.numberOfTapsRequired = 1
    singleTapGestureRecognizer.isEnabled = true
    singleTapGestureRecognizer.cancelsTouchesInView = false
    scrollView.addGestureRecognizer(singleTapGestureRecognizer)
  }
  
  @objc func singleTap() {
    view.endEditing(true)
  }
  
  func UICustomizing() {
    //adding method on spot main photo tap
    addGestureToOpenCameraOnPhotoTap()
    photoView.image = UIImage(named: "no photo") //Setting default picture
    photoView.tintColor = UIColor.myBlack()
    let postMediaLayer = self.photoOrVideoView.layer
    postMediaLayer.contents = photoView.image!.cgImage
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
    if haveWeChoosedMedia {
      showSavingProgress()
      
      if postDescription.text == NSLocalizedString("Write post description", comment: "")
      {
        // removing "placeholder" fake
        postDescription.text = ""
      }
      
      createNewPostItem() { postItem in
        // first - upload media. On completion - save post info data
        if self.isNewMediaIsPhoto {
          self.uploadPhoto(for: postItem)
        } else {
          self.uploadVideo(for: postItem)
        }
      }
    } else {
      showAlertWithError(text: NSLocalizedString("Please, select media", comment: ""))
    }
  }
  
  private func createNewPostItem(completion: @escaping (_ postItem: PostItem) -> Void) {
    let createdDate = String(describing: Date())
    let newPostId = Post.getNewPostId()
    let currentUserId = UserModel.getCurrentUserId()
    
    UserModel.getItemById(for: currentUserId) { userItem in
      let postItem = PostItem(self.isNewMediaIsPhoto, self.postDescription.text,
                              createdDate, self.spotDetailsItem.key,
                              userItem, newPostId)
      completion(postItem)
    }
  }
  
  private func uploadPhoto(for postItem: PostItem) {
    PostMedia.uploadForPost(
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
      
      let failImage = UIImage(named: "no photo")
      
      return failImage!
    }
  }
  
  private func showAlertThatErrorInNewPost() {
    let alert = UIAlertController(title: NSLocalizedString("Creating new post failed!", comment: ""),
                                  message: NSLocalizedString("Some error happened in new post creating.", comment: ""), preferredStyle: .alert)
    
    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
    
    present(alert, animated: true, completion: nil)
  }
  
  private func showAlertWithError(text: String) {
    let alert = UIAlertController(title: NSLocalizedString("Oops!", comment: ""),
                                  message: text,
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
        photoOrVideoView.isUserInteractionEnabled = true
      } else {
        navigationController?.navigationBar.isUserInteractionEnabled = false
        navigationItem.hidesBackButton = true
        tabBarController?.tabBar.isUserInteractionEnabled = false
        photoOrVideoView.isUserInteractionEnabled = false
      }
    }
  } // for disabling user touches, while uploading
  
  // functions for textView placeholder
  func textViewDidBeginEditing(_ textView: UITextView) {
    if textView.textColor == UIColor.lightGray {
      textView.text = nil
      textView.textColor = UIColor.black
    }
  }
  
  func textViewDidEndEditing(_ textView: UITextView) {
    if textView.text.isEmpty {
      textView.text = NSLocalizedString("Write post description", comment: "")
      textView.textColor = UIColor.lightGray
    }
  }
  var editor: AdvancedVideoEditor!
}

// MARK: - Camera extension
extension NewPostController : GalleryControllerDelegate {
  
  @IBAction func takeMedia(_ sender: Any) {
    let gallery = GalleryController()
    gallery.delegate = self
    
    Config.Camera.imageLimit = 1
    Config.VideoEditor.maximumDuration = 15
    Config.showsVideoTab = true
    
    present(gallery, animated: true, completion: nil)
  }
  
  func galleryController(_ controller: GalleryController, didSelectImages images: [Image]) {
    let img = images[0]
    
    haveWeChoosedMedia = true
    isNewMediaIsPhoto = true
    mediaAspectRatio = img.uiImage(ofSize: PHImageManagerMaximumSize)?.aspectRatio
    
    self.setPhoto(img.uiImage(ofSize: PHImageManagerMaximumSize)!)
    
    controller.dismiss(animated: true, completion: nil)
  }
  
  func setPhoto(_ image: UIImage) {
    changeMediaContainerHeight()
    
    photoView.image = image
    let spotPostMediaLayer = self.photoOrVideoView.layer
    spotPostMediaLayer.contents = photoView.image?.cgImage
  }
  
  func galleryController(_ controller: GalleryController, didSelectVideo video: Video) {
    haveWeChoosedMedia = true
    
    video.fetchAVAsset() { asset in
      
      guard let avasset = asset! as? AVURLAsset
        else {
          DispatchQueue.main.async {
            controller.dismiss(animated: true, completion: nil)
            self.showAlertThatSlowmoNotSup()
          }
          return
      }
      
      let fileURL = avasset.url
      
      self.initAspectRatioOfVideo(with: fileURL)
      self.changeMediaContainerHeight()
      self.isNewMediaIsPhoto = false
      
      self.player = AVPlayer(url: fileURL)
      
      let castedLayer = self.photoOrVideoView.layer as! AVPlayerLayer
      castedLayer.player = self.player
      
      self.player.play()
      
      NotificationCenter.default.addObserver(self, selector: #selector(NewPostController.playerItemDidReachEnd), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
      
      self.newVideoUrl = fileURL
      
      let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + NSUUID().uuidString + ".m4v")
      
      self.compressVideo(inputURL: fileURL as URL, outputURL: compressedURL) { (exportSession) in
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
      
      DispatchQueue.main.async {
        controller.dismiss(animated: true, completion: nil)
      }
    }
  }
  
  @objc func playerItemDidReachEnd(notification: Notification) {
    if notification.object as? AVPlayerItem == player?.currentItem {
      player.pause()
      player.seek(to: kCMTimeZero)
      player.play()
    }
  }
  
  private func showAlertThatSlowmoNotSup() {
    DispatchQueue.main.async {
      let alert = UIAlertController(title: NSLocalizedString("Error!", comment: ""),
                                    message: NSLocalizedString("Slow motion videos are not supported!", comment: ""),
                                    preferredStyle: .alert)
      
      alert.addAction(UIAlertAction(title: "Ok",
                                    style: .default,
                                    handler: nil))
      self.present(alert, animated: true, completion: nil)
    }
  }
  
  func galleryController(_ controller: GalleryController, requestLightbox images: [Image]) {
  }
  
  func galleryControllerDidCancel(_ controller: GalleryController) {
    controller.dismiss(animated: true, completion: nil)
  }
  
  func changeMediaContainerHeight() {
    DispatchQueue.main.async {
      let width = self.view.frame.size.width
      let height = CGFloat(Double(width) * self.mediaAspectRatio)
      self.mediaContainerHeight.constant = height
      
      self.photoOrVideoView.layoutIfNeeded()
    }
  }
  
  private func initAspectRatioOfVideo(with fileURL: URL) {
    let resolution = resolutionForLocalVideo(url: fileURL)
    
    let width = resolution?.width
    let height = resolution?.height
    
    mediaAspectRatio = Double(height! / width!)
  }
  
  func resolutionForLocalVideo(url: URL) -> CGSize? {
    guard let track = AVURLAsset(url: url).tracks(withMediaType: AVMediaType.video).first else { return nil }
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
    exportSession.outputFileType = AVFileType.mov
    exportSession.shouldOptimizeForNetworkUse = true
    exportSession.exportAsynchronously { () -> Void in
      handler(exportSession)
    }
  }
}

//Keyboard manipulations
extension NewPostController {
  //if we tapped UITextField and then another UITextField
  @objc func keyboardWillShow(notification: NSNotification) {
    view.frame.origin.y -= 200
  }
  
  @objc func keyboardWillHide(notification: NSNotification) {
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

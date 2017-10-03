//
//  SpotInfoController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 30.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import Kingfisher
import SVProgressHUD
import Gallery
import Photos
import FSPagerView
import Cosmos

class SpotInfoController: UIViewController, FSPagerViewDataSource, FSPagerViewDelegate {
   
   weak var delegateFollowTaps: FollowTappedFromSpotInfo?
   weak var spotInfoOnMapDelegate: SpotInfoOnMapDelegate?
   
   var spotInfo: SpotItem!
   var user: UserItem!
   @IBOutlet weak var modifyButton: UIButtonX!
   
   @IBOutlet weak var pagerView: FSPagerView! {
      didSet {
         pagerView.register(FSPagerViewCell.self, forCellWithReuseIdentifier: "SpotFSPagerViewCell")
         pagerView.transformer = FSPagerViewTransformer(type: .overlap)
         pagerView.isInfinite = true
         pagerView.automaticSlidingInterval = 2.5
         pagerView.interitemSpacing = 10
         pagerView.itemSize = CGSize(width: 315, height: 320)
      }
   }
   
   @IBOutlet weak var photosCollection: UICollectionView!
   
   var photosURLs = [String]()
   
   @IBOutlet weak var name: UILabel!
   @IBOutlet weak var desc: UILabel!
   
   @IBOutlet weak var addedByUser: UIButton!
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      name.text = spotInfo.name
      desc.text = spotInfo.description
      
      initializePhotos()
      initUserLabel()
      initFollowButton()
      initRatingView()
   }
   
   // MARK: - FSPager part
   public func numberOfItems(in pagerView: FSPagerView) -> Int {
      return photosURLs.count
   }
   
   public func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
      let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "SpotFSPagerViewCell", at: index)
      
      let photoURL = URL(string: photosURLs[index])
      cell.imageView?.kf.setImage(with: photoURL!)
      cell.imageView?.frame.size.height = 320
      cell.imageView?.frame.size.width = 315
      cell.imageView?.contentMode = .scaleAspectFit
      
      return cell
   }
   
   private func initializePhotos() {
      self.photosURLs.append(self.spotInfo.mainPhotoRef)
      Spot.getAllPhotosURLs(for: spotInfo.key) { photoURLs in
         self.photosURLs.append(contentsOf: photoURLs)
         self.pagerView.reloadData()
      }
   }
   
   // MARK: - initialize user
   private func initUserLabel() {
      UserModel.getItemById(for: spotInfo.addedByUser) { user in
         self.user = user
         self.addedByUser.setTitle(user.login, for: .normal)
      }
   }
   
   @IBAction func userButtonTapped(_ sender: Any) {
      if user.uid == UserModel.getCurrentUserId() {
         self.performSegue(withIdentifier: "goToUserProfileFromSpotInfo", sender: self)
      } else {
         self.performSegue(withIdentifier: "goToRidersProfileFromSpotInfo", sender: self)
      }
   }
   
   //MARK: - follow part
   @IBOutlet weak var followSpotButton: UIButton!
   
   private func initFollowButton() {
      Spot.isCurrentUserFollowingSpot(with: spotInfo.key) { isFollowing in
         if isFollowing {
            self.followSpotButton.setTitle(NSLocalizedString("Following", comment: ""), for: .normal)
         } else {
            self.followSpotButton.setTitle(NSLocalizedString("Follow", comment: ""), for: .normal)
         }
         
         self.followSpotButton.isEnabled = true
      }
   }
   
   @IBAction func followSpotButtonTapped(_ sender: Any) {
      if followSpotButton.currentTitle == NSLocalizedString("Follow", comment: "") { // add or remove like
         Spot.addFollowingToSpot(with: spotInfo.key)
      } else {
         Spot.removeFollowingToSpot(with: spotInfo.key)
      }
      
      swapFollowButtonTittle()
      
      if let del = delegateFollowTaps {
         del.followTapped(on: spotInfo.key)
      }
   }
   
   private func swapFollowButtonTittle() {
      if followSpotButton.currentTitle == NSLocalizedString("Follow", comment: "") {
         followSpotButton.setTitle(NSLocalizedString("Following", comment: ""), for: .normal)
      } else {
         followSpotButton.setTitle(NSLocalizedString("Follow", comment: ""), for: .normal)
      }
   }
   
   @IBAction func goToPostsButtonTapped(_ sender: UIButton) {
      performSegue(withIdentifier: "fromSpotInfoToSpotPosts", sender: self)
   }
   
   @IBAction func modifyButtonTapped(_ sender: Any) {
      performSegue(withIdentifier: "modifySpot", sender: self)
   }
   
   // MARK: - Vote part
   @IBOutlet weak var ratingView: CosmosView!
   
   private func initRatingView() {
      ratingView.settings.fillMode = .half
      
      Spot.getAverageRatingOfSpot(with: spotInfo.key) { rating in
         self.ratingView.rating = rating
      }
   }
   
   @IBAction func addVote(_ sender: Any) {
      //Alert for the rating
      let alert = UIAlertController(title: "\n\n", message: "", preferredStyle: .actionSheet)

      //The x/y coordinate of the rating view
      let xCoord = alert.view.frame.width / 2 - 95 // (5 starts multiplied by 30 each, plus a 5 margin each / 2)
      let yCoord = CGFloat(25.0)

      let newVote = configureNewVoteForAlert(x: xCoord, y: yCoord)

      let saveAction = UIAlertAction(title: NSLocalizedString("Save", comment: ""), style: .destructive, handler: { alert in
         let currentUserId = UserModel.getCurrentUserId()
         // new vote can be only 1,2,3,4,5. Average - double
         let newVoteInt = Int(newVote.rating)
         Spot.addNewVote(to: self.spotInfo.key, from: currentUserId, newVoteInt)
      })

      alert.addAction(saveAction)
      alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))

      alert.view.addSubview(newVote)

      self.present(alert, animated: true)
   }
   
   private func configureNewVoteForAlert(x: CGFloat, y: CGFloat) -> CosmosView {
      let newVote = CosmosView()
      newVote.rating = 1.0
      newVote.settings.starSize = 30
      newVote.settings.filledImage = UIImage(named: "filledStar")
      newVote.settings.emptyImage  = UIImage(named: "emptyStar")
      newVote.settings.updateOnTouch = true
      //Make a custom frame
      newVote.frame = CGRect(x: 0, y: 0, width: 200.0, height: 60.0)
      newVote.frame.origin.x = x
      newVote.frame.origin.y = y
      
      return newVote
   }
   
   // MARK: - prepare for segue
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      switch segue.identifier! {
      case "goToRidersProfileFromSpotInfo":
         let newRidersProfileController = segue.destination as! RidersProfileController
         newRidersProfileController.ridersInfo = user
         newRidersProfileController.title = user.login
         
      case "goToUserProfileFromSpotInfo":
         let userProfileController = segue.destination as! UserProfileController
         userProfileController.cameFromSpotDetails = true
         
      case "fromSpotInfoToSpotPosts":
         let postsStripController = segue.destination as! PostsStripController
         postsStripController.spotDetailsItem = spotInfo
         postsStripController.cameFromSpotOrMyStrip = true // came from spot
         
      case "modifySpot":
         let newSpotController = segue.destination as! NewSpotController
         newSpotController.spot = spotInfo
         newSpotController.cameForNewSpot = false
         newSpotController.spotInfoOnMapDelegate = self
         
      default: break
      }
   }
}

extension SpotInfoController: SpotInfoOnMapDelegate {
   func placeSpotOnMap(_ spot: SpotItem) {
      // send updated spot info on map
      spotInfoOnMapDelegate?.placeSpotOnMap(spot)
      // also update info in spotInfo
      spotInfo = spot
      name.text = spotInfo.name
      desc.text = spotInfo.description
      // update main photo (first in array)
      photosURLs[0] = spot.mainPhotoRef
      self.pagerView.reloadData()
   }
}

// MARK: - Camera extension
extension SpotInfoController : GalleryControllerDelegate {
   
   @IBAction func addPhotoButtonTapped(_ sender: Any) {
      let gallery = GalleryController()
      gallery.delegate = self
      
      Config.Camera.imageLimit = 1
      Config.showsVideoTab = false
      
      present(gallery, animated: true, completion: nil)
   }
   
   func galleryController(_ controller: GalleryController, didSelectImages images: [Gallery.Image]) {
      let img = images[0]
      
      SVProgressHUD.show()
      SpotMedia.uploadForInfo(img.uiImage(ofSize: PHImageManagerMaximumSize)!, for: self.spotInfo.key, with: 270.0) { url in
         if url != nil {
            self.photosURLs.append(url!)
            
            self.pagerView.reloadData()
         }
         
         SVProgressHUD.dismiss()
      }
      
      controller.dismiss(animated: true, completion: nil)
   }
   
   func galleryController(_ controller: GalleryController, didSelectVideo video: Video) {
   }
   
   func galleryController(_ controller: GalleryController, requestLightbox images: [Gallery.Image]) {
   }
   
   func galleryControllerDidCancel(_ controller: GalleryController) {
      controller.dismiss(animated: true, completion: nil)
   }
}

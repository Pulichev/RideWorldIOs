//
//  PostsStripController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 19.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import AVFoundation
import Kingfisher
import ActiveLabel
import KYCircularProgress
import ESPullToRefresh
import UserNotifications
import FirebaseInstanceID
import FirebaseMessaging

class PostsStripController: UIViewController, UITableViewDataSource, UITableViewDelegate {
   
   @IBOutlet weak var tableView: UITableView! {
      didSet {
         tableView.delegate = self
         tableView.dataSource = self
         tableView.estimatedRowHeight = 300
         tableView.rowHeight = UITableViewAutomaticDimension
         tableView.emptyDataSetSource = self
         tableView.emptyDataSetDelegate = self
         tableView.tableFooterView = UIView() // deleting empty rows
         
//         self.tableView.es_addPullToRefresh { [weak self] in
//            self?.refresh() {
//               self?.tableView.es_stopPullToRefresh(ignoreDate: true)
//            }
//         }
//
//         self.tableView.es_addInfiniteScrolling { [weak self] in
//            self?.loadMore() { newItemsExisting in
//               if newItemsExisting {
//                  self?.tableView.es_stopLoadingMore()
//               } else {
//                  self?.tableView.es_noticeNoMoreData()
//               }
//            }
//         }
      }
   }
   
   var cameFromSpotOrMyStrip = false // true - from spot, default false - from mystrip
   
   var spotDetailsItem: SpotItem! // using it if come from spot
   
   private var posts = [PostItem]()
   fileprivate var postItemCellsCache = [PostItemCellCache]()
   
   private var mediaCache = NSMutableDictionary()
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      tabBarController?.delegate = self
      view.layoutIfNeeded() // force to get proper size of tableView
      
      initLoadingView()
      setLoadingScreen()
      loadPosts(completion: { newItems in
         self.appendLoadedPosts(newItems) { _ in } // no need completion here
      })
   }
   
   // MARK: - Post load region
   func appendLoadedPosts(_ newItems: [PostItem]?,
                          completion: @escaping (_ hasFinished: Bool) -> Void) {
      
      if newItems == nil { // no more posts
         self.removeLoadingScreen()
         self.tableView.reloadData() // for dzempty
         completion(true)
      } else {
         loadPostsCache(newItems) { postsCache in
            self.posts.append(contentsOf: newItems!)
            self.postItemCellsCache.append(contentsOf: postsCache)
            self.removeLoadingScreen()
            let countOfCachedCells = postsCache.count
            self.reloadNewCells(
               startingFrom: self.posts.count - countOfCachedCells,
               count: countOfCachedCells)
            completion(true)
         }
      }
   }
   
   private func loadPosts(completion: @escaping (_ newItems: [PostItem]?) -> Void) {
      if cameFromSpotOrMyStrip {
         Spot.getPosts(for: spotDetailsItem.key, countOfNewItemsToAdd: postsLoadStep)
         { newItems, error in
            if error == "" {
               completion(newItems)
            } else {
               if error == "Permission Denied" {
                  if UserModel.signOut() { // if no errors
                     // then go to login
                     self.performSegue(withIdentifier: "fromStripToLogin", sender: self)
                  }
               }
            }
         }
      } else {
         UserModel.getStripPosts(countOfNewItemsToAdd: postsLoadStep)
         { newItems, error in
            if error == "" {
               completion(newItems)
            } else {
               if error == "Permission Denied" {
                  if UserModel.signOut() { // if no errors
                     // then go to login
                     self.performSegue(withIdentifier: "fromStripToLogin", sender: self)
                  }
               }
            }
         }
      }
   }
   
   func loadPostsCache(_ newItems: [PostItem]?,
                       completion: @escaping (_ cachedItems: [PostItemCellCache]) -> Void) {
      var newItemsCache = [PostItemCellCache]()
      
      var countOfCachedCells = 0
      
      for newItem in newItems! {
         // need to cache all cells before adding
         _ = PostItemCellCache(newItem) { cellCache in
            countOfCachedCells += 1
            newItemsCache.append(cellCache)
            
            if countOfCachedCells == newItems?.count {
               completion(newItemsCache)
            }
         }
      }
   }
   
   private func reloadNewCells(startingFrom index: Int, count: Int) {
      var indexPaths = [IndexPath]()
      
      for i in index...(index + count - 1) {
         indexPaths.append(IndexPath(row: i, section: 0))
      }
      
      tableView.beginUpdates()
      tableView.insertRows(at: indexPaths, with: .none)
      tableView.endUpdates()
   }
   
   // MARK: - Infinite scrolling and refresh
   private let postsLoadStep = 5
   
   func loadMore(completion: @escaping (_ newItemsExisting: Bool) -> Void) {
      self.loadPosts() { newItems in
         if newItems == nil || newItems?.count == 0 {
            completion(false)
         } else {
            self.appendLoadedPosts(newItems) { hasFinished in
               completion(true)
            }
         }
      }
   }
   
   @IBAction func reloadButtonTapped(_ sender: Any) {
      refresh() {  }
   }
   
   // function for pull to refresh
   func refresh(completion: @escaping () -> Void) {
      UserModel.dropLastKey()
      Spot.dropLastKey()
      mediaCache.removeAllObjects()
//      tableView.es_resetNoMoreData()
      
      loadPosts() { newItems in
         if newItems == nil { return }
         
         // clear table. Set stored only first load
         if self.posts.count > self.postsLoadStep {
            self.clearAllTableButFirstStepCount()
         }
         
         self.reloadTableDataWithRefreshedItems(newItems!) {
            completion()
         }
      }
   }
   
   // function for refresh
   private func clearAllTableButFirstStepCount() {
      self.tableView.beginUpdates()
      // clear all but firsts #postsLoadStep
      // from tableView
      var indexPaths = [IndexPath]()
      
      if self.postsLoadStep < self.posts.count - 1 {
         for i in self.postsLoadStep...(self.posts.count - 1) {
            indexPaths.append(IndexPath(row: i, section: 0))
         }
         
         self.tableView.deleteRows(at: indexPaths, with: .none)
         
         // from arrays
         self.posts = Array(self.posts[0..<self.postsLoadStep])
         self.postItemCellsCache = Array(self.postItemCellsCache[0..<self.postsLoadStep])
         self.tableView.endUpdates()
      }
   }
   
   private func reloadTableDataWithRefreshedItems(_ newItems: [PostItem],
                                                  completion: @escaping () -> Void) {
      self.posts = newItems
      
      self.loadPostsCache(newItems) { postsCache in
         self.postItemCellsCache.removeAll()
         self.postItemCellsCache = postsCache
         self.tableView.reloadData()
         completion()
      }
   }
   
   // MARK: - Main table filling region
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return posts.count
   }
   
   // not best code, but idk atm how to review it.
   //                   ﾉ (￣▽￣)ノ
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let row = indexPath.row
      
      let cellFromCache = postItemCellsCache[row]
      let post = posts[row]
      
      if post.isPhoto {
         let cell = tableView.dequeueReusableCell(withIdentifier: "PostsCellWithPhoto", for: indexPath) as! PostsCellWithPhoto
         
         // force update of width
         cell.frame.size.width = view.frame.width
         cell.layoutIfNeeded()
         
         cell.initialize(with: cellFromCache, post)
         
         cell.delegateUserTaps     = self
         cell.delegateSpotInfoTaps = self
         cell.delegateLikeEvent    = self
         
         cell.openComments.tag = row // for segue to send postId to comments
         cell.openComments.addTarget(self, action: #selector(goToComments), for: .touchUpInside)
         
         let width = view.frame.size.width
         let height = width * CGFloat(cell.post.mediaAspectRatio)
         cell.spotPostPhotoHeight.constant = height
         cell.spotPostPhoto.frame.size.height = height
         
         setPhoto(on: cell)
         
         return cell
      } else {
         let cell = tableView.dequeueReusableCell(withIdentifier: "PostsCellWithVideo", for: indexPath) as! PostsCellWithVideo
         
         // force update of width
         cell.frame.size.width = view.frame.width
         cell.layoutIfNeeded()
         
         cell.initialize(with: cellFromCache, post)
         
         cell.delegateUserTaps     = self
         cell.delegateSpotInfoTaps = self
         cell.delegateLikeEvent    = self
         
         cell.openComments.tag = row // for segue to send postId to comments
         cell.openComments.addTarget(self, action: #selector(goToComments), for: .touchUpInside)
         
         let width = view.frame.size.width
         let height = width * CGFloat(cell.post.mediaAspectRatio)
         cell.spotPostMediaHeight.constant = height
         
         setVideo(on: cell, cacheKey: row)
         
         return cell
      }
   }
   
   func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
      guard let customCell = cell as? PostsCellWithVideo else { return }
      if (!customCell.post.isPhoto && customCell.player != nil) {
         if (customCell.player.rate != 0 && (customCell.player.error == nil)) {
            // player is playing
            customCell.player.pause()
            customCell.player = nil
         }
      }
   }
   
   private func updateCellLikesCache(objectId: String) {
      for postCellCache in postItemCellsCache {
         if postCellCache.post.key == objectId {
            postCellCache.changeLikeToDislikeAndViceVersa()
         }
      }
   }
   
   // MARK: - Set media part
   private func setPhoto(on cell: PostsCellWithPhoto) {
      // set gray thumbnail
      cell.spotPostPhoto.image = UIImage(named: "grayRec.png")
      
      // blur for 10px thumbnail
      let blurProc01 = BlurImageProcessor(blurRadius: 0.1)
      let circularProgress = CircularProgress(on: cell.spotPostPhoto.bounds)
      cell.spotPostPhoto.addSubview(circularProgress.view)
      
      // download 10px thumbnail
      cell.spotPostPhoto.kf.setImage(
         with: URL(string: cell.post.mediaRef10),
         options: [.processor(blurProc01)],
         completionHandler: { (image, error, cacheType, imageUrl) in
            // download original
            cell.spotPostPhoto.kf.setImage(
               with: URL(string: cell.post.mediaRef700),
               placeholder: image, // 10px
               progressBlock: { receivedSize, totalSize in
                  let percentage = (Double(receivedSize) / Double(totalSize))
                  circularProgress.view.progress = percentage
            }, completionHandler: { (_, _, _, _) in
               circularProgress.view.isHidden = true
            })
      })
   }
   
   func setVideo(on cell: PostsCellWithVideo, cacheKey: Int) {
      addPlaceHolder(cell: cell)
      
      //Check cache. Exists -> get it, no - plce thumbnail and download
      if (mediaCache.object(forKey: cacheKey) != nil) { // checking video existance in cache
         let cachedAsset = mediaCache.object(forKey: cacheKey) as? AVAsset
         cell.player = AVPlayer(playerItem: AVPlayerItem(asset: cachedAsset!))
         let playerLayer = AVPlayerLayer(player: (cell.player))
         playerLayer.videoGravity = AVLayerVideoGravity(rawValue: kCAGravityResizeAspectFill)
         playerLayer.frame = cell.spotPostMedia.bounds
         cell.spotPostMedia.layer.addSublayer(playerLayer)
         cell.spotPostMedia.playerLayer = playerLayer
         
         cell.player.play()
      } else {
         downloadBigThumbnail(postKey: posts[cacheKey].key, cacheKey: cacheKey, cell: cell)
      }
   }
   
   func addPlaceHolder(cell: PostsCellWithVideo) {
      let placeholder = UIImageView()
      let placeholderImage = UIImage(named: "grayRec.png")
      placeholder.image = placeholderImage
      placeholder.layer.contentsGravity = kCAGravityResize
      placeholder.contentMode = .scaleAspectFill
      placeholder.frame = cell.spotPostMedia.bounds
      cell.spotPostMedia.layer.addSublayer(placeholder.layer)
      cell.spotPostMedia.playerLayer = placeholder.layer
   }
   
   private func downloadBigThumbnail(postKey: String, cacheKey: Int, cell: PostsCellWithVideo) {
      // thumbnail!
      let imageViewForView = UIImageView()
      imageViewForView.kf.setImage(with: URL(string: cell.post.mediaRef700)) { (_, _, _, _) in
         imageViewForView.layer.contentsGravity = kCAGravityResize
         imageViewForView.contentMode = .scaleAspectFill
         imageViewForView.frame = cell.spotPostMedia.bounds
         
         cell.spotPostMedia.layer.addSublayer(imageViewForView.layer)
         cell.spotPostMedia.playerLayer = imageViewForView.layer
         
         self.downloadVideo(postKey: postKey, cacheKey: cacheKey, cell: cell)
      }
   }
   
   private func downloadVideo(postKey: String, cacheKey: Int, cell: PostsCellWithVideo) {
      let assetForCache = AVAsset(url: URL(string: cell.post.videoRef)!)
      
      self.mediaCache.setObject(assetForCache, forKey: cacheKey as NSCopying)
      cell.player = AVPlayer(playerItem: AVPlayerItem(asset: assetForCache))
      let playerLayer = AVPlayerLayer(player: cell.player)
      playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
      playerLayer.frame = cell.spotPostMedia.bounds
      
      cell.spotPostMedia.layer.addSublayer(playerLayer)
      cell.spotPostMedia.playerLayer = playerLayer
      
      cell.player.play()
   }
   
   @IBAction func addNewPost(_ sender: Any) {
      performSegue(withIdentifier: "addNewPost", sender: self)
   }
   
   // go to comments
   @objc func goToComments(sender: UIButton!) {
      postForSending         = posts[sender.tag]
      postDescForSending     = posts[sender.tag].description
      postDateTimeForSending = posts[sender.tag].createdDate
      postUserIdForSending   = posts[sender.tag].addedByUser
      
      performSegue(withIdentifier: "goToCommentsFromPostStrip", sender: self)
   }
   
   var ridersInfoForSending: UserItem!
   var postForSending: PostItem!
   var postDescForSending: String!
   var postDateTimeForSending: String!
   var postUserIdForSending: String!
   var spotInfoForSending: SpotItem!
   
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      switch segue.identifier! {
      case "addNewPost":
         let newPostController = segue.destination as! NewPostController
         newPostController.spotDetailsItem = spotDetailsItem
         
      case "openRidersProfileFromSpotDetails":
         let newRidersProfileController = segue.destination as! RidersProfileController
         newRidersProfileController.ridersInfo = ridersInfoForSending
         newRidersProfileController.title      = ridersInfoForSending.login
         
      case "ifChoosedCurrentUser":
         let userProfileController = segue.destination as! UserProfileController
         userProfileController.cameFromSpotDetails = true
         
      case "goToCommentsFromPostStrip":
         let commentariesController = segue.destination as! CommentariesController
         commentariesController.post            = postForSending
         commentariesController.postDescription = postDescForSending
         commentariesController.postDate        = postDateTimeForSending
         commentariesController.userId          = postUserIdForSending
         
      case "fromPostToSpotInfo":
         let spotInfoController = segue.destination as! SpotInfoController
         spotInfoController.spotInfo = spotInfoForSending
         
      default: break
      }
   }
   
   // MARK: - when data loading
   var loadingView: LoadingProcessView!
   
   func initLoadingView() {
      loadingView = LoadingProcessView(center: tableView.center)
      
      tableView.addSubview(loadingView)
   }
   
   var haveWeFinishedLoading = false // bool value have we loaded posts or not. Mainly for DZNEmptyDataSet
   
   // Set the activity indicator into the main view
   private func setLoadingScreen() {
      loadingView.show()
   }
   
   // Remove the activity indicator from the main view
   private func removeLoadingScreen() {
      loadingView.dismiss()
      haveWeFinishedLoading = true
   }
   
   fileprivate var isFirstClickOnTabBar = true // will user in in UITabBarControllerDelegate
}

// MARK: - Updating like info
extension PostsStripController: PostsCellLikeEventDelegate {
   func postLikeEventFinished(for postId: String) {
      postItemCellsCache.forEach {
         if $0.post.key == postId {
            $0.changeLikeToDislikeAndViceVersa()
         }
      }
   }
}

// MARK: - For scrolling table view to start on home tab bar item tap
extension PostsStripController: UITabBarControllerDelegate {
   func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
      let tabBarIndex = tabBarController.selectedIndex
      
      if isFirstClickOnTabBar {
         isFirstClickOnTabBar = false
         return
      }
      
      if tabBarIndex == 0 {
         self.tableView.setContentOffset(CGPoint.zero, animated: true)
      }
   }
}

// to send userItem from cell to perform segue
extension PostsStripController: TappedUserDelegate {
   func userInfoTapped(_ user: UserItem?) {
      if user != nil {
         if user!.uid == UserModel.getCurrentUserId() {
            self.performSegue(withIdentifier: "ifChoosedCurrentUser", sender: self)
         } else {
            self.ridersInfoForSending = user!
            self.performSegue(withIdentifier: "openRidersProfileFromSpotDetails", sender: self)
         }
      } else {
         showAlertThatUserLoginNotFounded()
      }
   }
   
   private func showAlertThatUserLoginNotFounded() {
      let alert = UIAlertController(title: NSLocalizedString("Error!", comment: ""),
                                    message: NSLocalizedString("No user has been founded!", comment: ""),
                                    preferredStyle: .alert)
      
      alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
      
      present(alert, animated: true, completion: nil)
   }
}

extension PostsStripController: TappedSpotInfoDelegate {
   func spotInfoTapped(with id: String) {
      Spot.getItemById(for: id) { spot in
         self.spotInfoForSending = spot
         self.performSegue(withIdentifier: "fromPostToSpotInfo", sender: self)
      }
   }
}

// MARK: - show/hide navigation bar
extension PostsStripController {
   //part for hide and view navbar from this navigation controller
   override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      
      isFirstClickOnTabBar = true
      
      if !cameFromSpotOrMyStrip {
         navigationItem.title = "RideWorld"
         
         // hide add post button
         if navigationItem.rightBarButtonItems?.count == 2 {
            navigationItem.rightBarButtonItems?.remove(at: 0)
         }
      }
   }
   
   override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
      
      isFirstClickOnTabBar = true
      
      if !cameFromSpotOrMyStrip {
         // Show the navigation bar on other view controllers
         navigationController?.setNavigationBarHidden(false, animated: animated)
      } else { // from spot
         // need to clear last key
         Spot.dropLastKey()
      }
   }
}

// MARK: - DZNEmptyDataSet for empty data tables
extension PostsStripController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
   func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
      if haveWeFinishedLoading {
         let str = NSLocalizedString("Welcome", comment: "")
         let attrs = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
         return NSAttributedString(string: str, attributes: attrs)
      } else {
         let str = ""
         let attrs = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
         return NSAttributedString(string: str, attributes: attrs)
      }
   }
   
   func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
      if haveWeFinishedLoading {
         let str = NSLocalizedString("Nothing to show.", comment: "")
         let attrs = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
         return NSAttributedString(string: str, attributes: attrs)
      } else {
         let str = ""
         let attrs = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
         return NSAttributedString(string: str, attributes: attrs)
      }
   }
   
   func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
      if haveWeFinishedLoading {
         return MyImage.resize(sourceImage: UIImage(named: "no_photo.png")!, toWidth: 300).image
      } else {
         return nil // Image.resize(sourceImage: UIImage(named: "PleaseWaitTxt.gif")!, toWidth: 200).image
      }
   }
}

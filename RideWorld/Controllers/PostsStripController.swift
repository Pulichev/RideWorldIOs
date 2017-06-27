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
         
         self.tableView.es_addPullToRefresh { [weak self] in
            self?.refresh() {
               self?.tableView.es_stopPullToRefresh(ignoreDate: true)
            }
         }
         
         self.tableView.es_addInfiniteScrolling { [weak self] in
            self?.loadMore() { newItemsExisting in
               if newItemsExisting {
                  self?.tableView.es_stopLoadingMore()
               } else {
                  self?.tableView.es_noticeNoMoreData()
               }
            }
         }
      }
   }
   
   @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
   
   var cameFromSpotOrMyStrip = false // true - from spot, default false - from mystrip
   
   var spotDetailsItem: SpotItem! // using it if come from spot
   
   private var posts = [PostItem]()
   private var postItemCellsCache = [PostItemCellCache]()
   
   private var mediaCache = NSMutableDictionary()
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      initLoadingView()
      setLoadingScreen()
      
      self.loadPosts(completion: { newItems in
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
   
   private func loadPosts(completion: @escaping (_ newItems: [PostItem]?) -> Void) {
      if cameFromSpotOrMyStrip {
         Spot.getPosts(for: spotDetailsItem.key, countOfNewItemsToAdd: postsLoadStep)
         { newItems in
            completion(newItems)
         }
      } else {
         UserModel.getStripPosts(countOfNewItemsToAdd: postsLoadStep)
         { newItems in
            completion(newItems)
         }
      }
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
   
   // function for pull to refresh
   func refresh(completion: @escaping () -> Void) {
      // clear our structs
      Spot.clearCurrentData()
      UserModel.clearCurrentData()
      
      loadPosts() { newItems in
         if newItems == nil { return }
         
         if self.posts.count > self.postsLoadStep {
            self.clearAllTableButFirstStepCount()
         }
         
         let newItemsFirstItemsKeys = (Array(newItems!).map { $0.key })
         let currentItemsFirstItemsKeys = (Array(self.posts[0..<self.postsLoadStep]).map { $0.key })
         
         if newItemsFirstItemsKeys != currentItemsFirstItemsKeys { // if new posts.
            self.reloadTableDataWithRefreshedItems(newItems!) {
               completion()
            }
         } else {
            completion()
         }
      }
   }
   
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
      self.tableView.beginUpdates()
      
      self.posts = newItems
      
      self.loadPostsCache(newItems) { postsCache in
         self.postItemCellsCache = postsCache
         self.tableView.reloadData()
         self.tableView.endUpdates()
         completion()
      }
   }
   
   // MARK: - Main table filling region
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return posts.count
   }
   
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let row = indexPath.row
      
      if postItemCellsCache[row].isPhoto {
         let cell = tableView.dequeueReusableCell(withIdentifier: "PostsCellWithPhoto", for: indexPath) as! PostsCellWithPhoto
         
         if cell.userLikedOrDeletedLike { // when cell appears checking if like was tapped
            cell.userLikedOrDeletedLike = false
            updateCellLikesCache(objectId: cell.post.key) // if yes updating cache
         }
         
         let cellFromCache = postItemCellsCache[row]
         cell.post                 = cellFromCache.post
         cell.userInfo             = cellFromCache.userInfo
         cell.userNickName.setTitle(cellFromCache.userNickName, for: .normal)
         cell.userNickName.tag     = row // for segue to send userId to ridersProfile
         cell.userNickName.addTarget(self, action: #selector(nickNameTapped), for: .touchUpInside)
         cell.openComments.tag     = row // for segue to send postId to comments
         cell.openComments.addTarget(self, action: #selector(goToComments), for: .touchUpInside)
         cell.postDate.text        = cellFromCache.postDate
         cell.postDescription.text = cellFromCache.postDescription
         cell.postDescription.handleMentionTap { mention in // mention is @userLogin
            self.goToUserProfile(tappedUserLogin: mention)
         }
         cell.likesCount.text      = String(cellFromCache.likesCount)
         cell.postIsLiked          = cellFromCache.postIsLiked
         
         cell.isLikedPhoto.image   = cellFromCache.isLikedPhoto.image
         let width = view.frame.size.width
         let height = CGFloat(Double(width) * cell.post.mediaAspectRatio)
         cell.spotPostPhotoHeight.constant = height
         setPhoto(on: cell) // cell.spotPostPhoto setting async
         cell.addDoubleTapGestureOnPostPhotos()
         
         return cell
      } else {
         let cell = tableView.dequeueReusableCell(withIdentifier: "PostsCellWithVideo", for: indexPath) as! PostsCellWithVideo
         
         if cell.userLikedOrDeletedLike { // when cell appears checking if like was tapped
            cell.userLikedOrDeletedLike = false
            updateCellLikesCache(objectId: cell.post.key) // if yes updating cache
         }
         
         let cellFromCache = postItemCellsCache[row]
         cell.post                 = cellFromCache.post
         cell.userInfo             = cellFromCache.userInfo
         cell.userNickName.setTitle(cellFromCache.userNickName, for: .normal)
         cell.userNickName.tag     = row // for segue to send userId to ridersProfile
         cell.userNickName.addTarget(self, action: #selector(nickNameTapped), for: .touchUpInside)
         cell.openComments.tag     = row // for segue to send postId to comments
         cell.openComments.addTarget(self, action: #selector(goToComments), for: .touchUpInside)
         cell.postDate.text        = cellFromCache.postDate
         cell.postDescription.text = cellFromCache.postDescription
         cell.postDescription.handleMentionTap { mention in // mention is @userLogin
            self.goToUserProfile(tappedUserLogin: mention)
         }
         cell.likesCount.text      = String(cellFromCache.likesCount)
         cell.postIsLiked          = cellFromCache.postIsLiked
         
         cell.isLikedPhoto.image   = cellFromCache.isLikedPhoto.image
         let width = view.frame.size.width
         let height = CGFloat(Double(width) * cell.post.mediaAspectRatio)
         cell.spotPostMediaHeight.constant = height
         cell.spotPostMedia.layoutIfNeeded()
         setVideo(on: cell, cacheKey: row)
         cell.addDoubleTapGestureOnPostPhotos()
         
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
            DispatchQueue.main.async {
               postCellCache.changeLikeToDislikeAndViceVersa()
            }
         }
      }
   }
   
   // MARK: - Set media part
   private func setPhoto(on cell: PostsCellWithPhoto) {
      // set gray thumbnail
      cell.spotPostPhoto.image = UIImage(named: "grayRec.png")
      
      // blur for 10px thumbnail
      let blurProc01 = BlurImageProcessor(blurRadius: 0.1)
      
      let circularProgress = CircularProgress(on: cell.spotPostPhoto.frame)
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
            }, completionHandler: { _ in
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
         playerLayer.videoGravity = kCAGravityResizeAspectFill
         playerLayer.frame = cell.spotPostMedia.bounds
         cell.spotPostMedia.layer.addSublayer(playerLayer)
         cell.spotPostMedia.playerLayer = playerLayer
         
         cell.player.play()
      } else {
         downloadBigThumbnail(postKey: self.posts[cacheKey].key, cacheKey: cacheKey, cell: cell)
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
      imageViewForView.kf.setImage(with: URL(string: cell.post.mediaRef700)) { _ in
         imageViewForView.layer.contentsGravity = kCAGravityResize
         imageViewForView.contentMode = .scaleAspectFill
         imageViewForView.frame = cell.spotPostMedia.bounds
         
         cell.spotPostMedia.layer.addSublayer(imageViewForView.layer)
         cell.spotPostMedia.playerLayer = imageViewForView.layer
         
         self.downloadVideo(postKey: postKey, cacheKey: cacheKey, cell: cell)
      }//Using kf for caching images.
   }
   
   private func downloadVideo(postKey: String, cacheKey: Int, cell: PostsCellWithVideo) {
      let assetForCache = AVAsset(url: URL(string: cell.post.videoRef)!)
      
      self.mediaCache.setObject(assetForCache, forKey: cacheKey as NSCopying)
      cell.player = AVPlayer(playerItem: AVPlayerItem(asset: assetForCache))
      let playerLayer = AVPlayerLayer(player: cell.player)
      playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
      playerLayer.frame = cell.spotPostMedia.bounds
      print("\(playerLayer.frame.width)")
      print("\(playerLayer.frame.height)")
      
      cell.spotPostMedia.layer.addSublayer(playerLayer)
      cell.spotPostMedia.playerLayer = playerLayer
      
      cell.player.play()
   }
   
   @IBAction func addNewPost(_ sender: Any) {
      performSegue(withIdentifier: "addNewPost", sender: self)
   }
   
   private func goToUserProfile(tappedUserLogin: String) {
      UserModel.getItemByLogin(for: tappedUserLogin) { fetchedUserItem in
         if let userItem = fetchedUserItem { // have we founded?
            if userItem.uid == UserModel.getCurrentUserId() {
               self.performSegue(withIdentifier: "ifChoosedCurrentUser", sender: self)
            } else {
               self.ridersInfoForSending = userItem
               self.performSegue(withIdentifier: "openRidersProfileFromSpotDetails", sender: self)
            }
         } else { // if no user founded for tapped nickname
            self.showAlertThatUserLoginNotFounded(tappedUserLogin: tappedUserLogin)
         }
      }
   }
   
   private func showAlertThatUserLoginNotFounded(tappedUserLogin: String) {
      let alert = UIAlertController(title: "Error!",
                                    message: "No user founded with nickname \(tappedUserLogin)",
         preferredStyle: .alert)
      
      alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
      
      present(alert, animated: true, completion: nil)
   }
   
   // go to riders profile
   func nickNameTapped(sender: UIButton!) {
      // check if going to current user
      if postItemCellsCache[sender.tag].userInfo.uid == UserModel.getCurrentUserId() {
         performSegue(withIdentifier: "ifChoosedCurrentUser", sender: self)
      } else {
         ridersInfoForSending = postItemCellsCache[sender.tag].userInfo
         performSegue(withIdentifier: "openRidersProfileFromSpotDetails", sender: self)
      }
   }
   
   // go to comments
   func goToComments(sender: UIButton!) {
      postForSending = posts[sender.tag]
      postDescForSending = posts[sender.tag].description
      postDateTimeForSending = posts[sender.tag].createdDate
      postUserIdForSending = posts[sender.tag].addedByUser
      performSegue(withIdentifier: "goToCommentsFromPostStrip", sender: self)
   }
   
   var ridersInfoForSending: UserItem!
   var postForSending: PostItem!
   var postDescForSending: String!
   var postDateTimeForSending: String!
   var postUserIdForSending: String!
   
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      switch segue.identifier! {
      case "addNewPost":
         let newPostController = segue.destination as! NewPostController
         newPostController.spotDetailsItem = spotDetailsItem
         
      case "openRidersProfileFromSpotDetails":
         let newRidersProfileController = segue.destination as! RidersProfileController
         newRidersProfileController.ridersInfo = ridersInfoForSending
         newRidersProfileController.title = ridersInfoForSending.login
         
      case "ifChoosedCurrentUser":
         let userProfileController = segue.destination as! UserProfileController
         userProfileController.cameFromSpotDetails = true
         
      case "goToCommentsFromPostStrip":
         let commentariesController = segue.destination as! CommentariesController
         commentariesController.post = postForSending
         commentariesController.postDescription = postDescForSending
         commentariesController.postDate = postDateTimeForSending
         commentariesController.userId = postUserIdForSending
         
      default: break
      }
   }
   
   // MARK: - when data loading
   var loadingView: LoadingProcessView!
   
   func initLoadingView() {
      let width: CGFloat = 120
      let height: CGFloat = 30
      let x = (tableView.frame.width / 2) - (width / 2)
      let y = (tableView.frame.height / 2) - (height / 2) - (navigationController?.navigationBar.frame.height)!
      
      loadingView = LoadingProcessView(frame: CGRect(x: x, y: y, width: width, height: height))
      
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
}

// MARK: - show/hide navigation bar
extension PostsStripController {
   //part for hide and view navbar from this navigation controller
   override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      
      if !cameFromSpotOrMyStrip {
         let titleView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 30))
         titleView.contentMode = .scaleAspectFit
         titleView.image = UIImage(named: "rideWorldLogo.png")
         
         self.navigationItem.titleView = titleView
         
         self.navigationItem.rightBarButtonItem = nil // hide delete button
      }
   }
   
   override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
      
      // clear our structs
      Spot.alreadyLoadedCountOfPosts = 0
      Spot.spotPostsIds.removeAll()
      
      UserModel.alreadyLoadedCountOfPosts = 0
      UserModel.postsIds.removeAll()
      
      if !cameFromSpotOrMyStrip {
         // Show the navigation bar on other view controllers
         navigationController?.setNavigationBarHidden(false, animated: animated)
      }
   }
}

// MARK: - DZNEmptyDataSet for empty data tables
extension PostsStripController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
   func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
      if haveWeFinishedLoading {
         let str = "Welcome"
         let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
         return NSAttributedString(string: str, attributes: attrs)
      } else {
         let str = ""
         let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
         return NSAttributedString(string: str, attributes: attrs)
      }
   }
   
   func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
      if haveWeFinishedLoading {
         let str = "Nothing to show."
         let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
         return NSAttributedString(string: str, attributes: attrs)
      } else {
         let str = ""
         let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
         return NSAttributedString(string: str, attributes: attrs)
      }
   }
   
   func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
      if haveWeFinishedLoading {
         return Image.resize(UIImage(named: "no_photo.png")!, targetSize: CGSize(width: 300.0, height: 300.0))
      } else {
         return Image.resize(UIImage(named: "PleaseWaitTxt.gif")!, targetSize: CGSize(width: 300.0, height: 300.0))
      }
   }
}

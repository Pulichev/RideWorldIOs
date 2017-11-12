//
//  PostsStripController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 19.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import AVFoundation
import ESPullToRefresh
import Instructions

class PostsStripController: UIViewController, UITableViewDataSource, UITableViewDelegate, DelegateVideoCache {
  
  var cameFromSpotOrMyStrip = false // true - from spot, default false - from mystrip
  var spotDetailsItem: SpotItem! // using it if come from spot
  
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
  
  private var posts                  = [PostItem]()
  fileprivate var postItemCellsCache = [PostItemCellCache]()
  private var mediaCache             = NSMutableDictionary()
  
  let coachMarksController = CoachMarksController() // onboard tips controller
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.coachMarksController.dataSource = self
    
    tabBarController?.delegate = self
    
    initLoadingView()
    setLoadingScreen()
    loadPosts(completion: { newItems in
      self.appendLoadedPosts(newItems) { _ in } // no need completion here
    })
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    startCoachingIfNeeded()
  }
  
  private func startCoachingIfNeeded() {
    let defaults = UserDefaults.standard
    if (defaults.object(forKey: "firstLaunchOfPostStrip") as? Bool) == nil {
      // if it is first launch, this key will not be set upped
      self.coachMarksController.start(on: self)
    }
  }
  
  // MARK: - Posts load / reload region
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
          if error == "Permission Denied" { // means, that user was banned
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
          if error == "Permission Denied" { // means, that user was banned
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
    refresh() { }
  }
  
  // function for pull to refresh
  func refresh(completion: @escaping () -> Void) {
    UserModel.dropLastKey()
    Spot.dropLastKey()
    mediaCache.removeAllObjects()
    tableView.es_resetNoMoreData()
    
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
    tableView.beginUpdates()
    // clear all but firsts #postsLoadStep
    // from tableView
    var indexPaths = [IndexPath]()
    
    if self.postsLoadStep < self.posts.count - 1 {
      for i in self.postsLoadStep...(self.posts.count - 1) {
        indexPaths.append(IndexPath(row: i, section: 0))
      }
      
      tableView.deleteRows(at: indexPaths, with: .none)
      
      // from arrays
      posts = Array(self.posts[0..<self.postsLoadStep])
      postItemCellsCache = Array(self.postItemCellsCache[0..<self.postsLoadStep])
      tableView.endUpdates()
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
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let row = indexPath.row
    
    let cellFromCache = postItemCellsCache[row]
    let post = posts[row]
    
    let width = view.frame.width
    
    if post.isPhoto {
      let cell = tableView.dequeueReusableCell(withIdentifier: "PostsCellWithPhoto", for: indexPath) as! PostsCellWithPhoto
      
      cell.initialize(with: cellFromCache, post, cellWidth: width)
      
      cell.delegateUserTaps     = self
      cell.delegateSpotInfoTaps = self
      cell.delegateLikeEvent    = self
      
      cell.openComments.tag = row // for segue to send postId to comments
      cell.openComments.addTarget(self, action: #selector(goToComments), for: .touchUpInside)
      
      return cell
    } else {
      let cell = tableView.dequeueReusableCell(withIdentifier: "PostsCellWithVideo", for: indexPath) as! PostsCellWithVideo
      
      let cachedAsset = mediaCache.object(forKey: row) as? AVAsset
      cell.initialize(with: cellFromCache, post, cachedAsset, row: row, cellWidth: width)
      
      cell.delegateUserTaps     = self
      cell.delegateSpotInfoTaps = self
      cell.delegateLikeEvent    = self
      cell.delegateVideoCache   = self
      
      cell.openComments.tag = row // for segue to send postId to comments
      cell.openComments.addTarget(self, action: #selector(goToComments), for: .touchUpInside)
      
      return cell
    }
  }
  
  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    let width = view.frame.width
    
    if let cellWithPhoto = cell as? PostsCellWithPhoto {
      cellWithPhoto.initializeForWillDisplay(cellWidth: width)
    }
    
    if let cellWithVideo = cell as? PostsCellWithVideo {
      cellWithVideo.delegateVideoCache   = self
      let row = indexPath.row
      let cachedAsset = mediaCache.object(forKey: row) as? AVAsset
      cellWithVideo.initializeForWillDisplay(cellWidth: width, cachedAsset, row: row)
    }
  }
  
  func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    guard let customCell = cell as? PostsCellWithVideo else { return }
    if customCell.player != nil {
      if customCell.player.rate != 0 && customCell.player.error == nil {
        // player is playing
        customCell.player.pause()
        customCell.player = nil
      }
    }
  }
  
  // Delegate from cell with video
  func addToCacheArray(new asset: AVAsset, on row: Int) {
    mediaCache.setObject(asset, forKey: row as NSCopying)
  }
  
  // MARK: - Segues part
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
  
  // MARK: - When data loading
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
  
  fileprivate var isFirstClickOnHomeTabBarItem = true // will user in in UITabBarControllerDelegate
}

// MARK: - For scrolling table view to start on home tab bar item tap
extension PostsStripController: UITabBarControllerDelegate {
  func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
    let tabBarIndex = tabBarController.selectedIndex
    
    if isFirstClickOnHomeTabBarItem {
      isFirstClickOnHomeTabBarItem = false
      return
    }
    
    if tabBarIndex == 0 {
      self.tableView.setContentOffset(CGPoint.zero, animated: true)
    }
  }
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

// MARK: - Show/hide navigation bar
extension PostsStripController {
  //part for hide and view navbar from this navigation controller
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    isFirstClickOnHomeTabBarItem = true
    
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
    
    self.coachMarksController.stop(immediately: true)
    let defaults = UserDefaults.standard
    defaults.set(false, forKey: "firstLaunchOfPostStrip")
    
    isFirstClickOnHomeTabBarItem = true
    
    if !cameFromSpotOrMyStrip {
      // Show the navigation bar on other view controllers
      navigationController?.setNavigationBarHidden(false, animated: animated)
    } else { // from spot
      // need to clear last key
      Spot.dropLastKey()
    }
  }
}

// MARK: - Onboard instructions
extension PostsStripController: CoachMarksControllerDataSource, CoachMarksControllerDelegate {
  func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
    return 2
  }
  
  func coachMarksController(_ coachMarksController: CoachMarksController,
                            coachMarkAt index: Int) -> CoachMark {
    if index == 0 {
      let searchBarItemView = self.tabBarController?.tabBar.items?[1].value(forKey: "view") as? UIView
      
      return coachMarksController.helper.makeCoachMark(for: searchBarItemView) {
        (frame: CGRect) -> UIBezierPath in
        // This will create an arc on search button.
        return UIBezierPath(arcCenter: CGPoint(x: frame.midX, y: frame.maxY - 22.0),
                            radius: 21.0, startAngle: 0, endAngle: CGFloat(2 * Double.pi), clockwise: true)
      }
    } else {
      let mapBarItemView = self.tabBarController?.tabBar.items?[2].value(forKey: "view") as? UIView
      
      return coachMarksController.helper.makeCoachMark(for: mapBarItemView) {
        (frame: CGRect) -> UIBezierPath in
        // This will create an arc on map button.
        return UIBezierPath(arcCenter: CGPoint(x: frame.midX, y: frame.maxY - 31.0),
                            radius: 30.0, startAngle: 0, endAngle: CGFloat(2 * Double.pi), clockwise: true)
      }
    }
  }
  
  func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkViewsAt index: Int, madeFrom coachMark: CoachMark) -> (bodyView: CoachMarkBodyView, arrowView: CoachMarkArrowView?) {
    let coachViews = coachMarksController.helper.makeDefaultCoachViews(withArrow: true, arrowOrientation: coachMark.arrowOrientation)
    
    if index == 0 {
      coachViews.bodyView.hintLabel.text = NSLocalizedString("Hello! You can find your friends here!", comment: "")
      coachViews.bodyView.nextLabel.text = NSLocalizedString("Ok!", comment: "")
      
      return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
    } else {
      coachViews.bodyView.hintLabel.text = NSLocalizedString("Or find them on spots!", comment: "")
      coachViews.bodyView.nextLabel.text = NSLocalizedString("Ok!", comment: "")
      
      return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
    }
  }
}

// MARK: - DZNEmptyDataSet for empty data tables
extension PostsStripController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
  func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
    if haveWeFinishedLoading {
      let str = NSLocalizedString("Welcome", comment: "")
      let attrs = [NSAttributedStringKey.font: UIFont(name: "PTSans-Bold", size: 22)]
      return NSAttributedString(string: str, attributes: attrs)
    } else {
      let str = ""
      let attrs = [NSAttributedStringKey.font: UIFont(name: "PTSans-Bold", size: 22)]
      return NSAttributedString(string: str, attributes: attrs)
    }
  }
  
  func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
    if haveWeFinishedLoading {
      let str = NSLocalizedString("Nothing to show.", comment: "")
      let attrs = [NSAttributedStringKey.font: UIFont(name: "PT Sans", size: 19.0)]
      return NSAttributedString(string: str, attributes: attrs)
    } else {
      let str = ""
      let attrs = [NSAttributedStringKey.font: UIFont(name: "PT Sans", size: 19.0)]
      return NSAttributedString(string: str, attributes: attrs)
    }
  }
  
  func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
    if haveWeFinishedLoading {
      return MyImage.resize(sourceImage: UIImage(named: "no_photo.png")!, toWidth: 300).image
    } else {
      return nil
    }
  }
}

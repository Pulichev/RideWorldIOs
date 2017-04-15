//
//  UserProfileController.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 25.02.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//
import Foundation
import UIKit
import AVFoundation
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

class UserProfileController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    var userInfo: UserItem! {
        didSet {
            DispatchQueue.global(qos: .userInitiated).async {
                self.initializeUserTextInfo()
                self.initializeUserPhoto()
            }
            
            DispatchQueue.global(qos: .background).async {
                self.initializePostsPhotos()
            }
        }
    }
    
    @IBOutlet var userNameAndSename: UILabel!
    @IBOutlet var userBio: UITextView!
    @IBOutlet var userProfilePhoto: UIImageView!
    
    @IBOutlet var followersButton: UIButton!
    @IBOutlet var followingButton: UIButton!
    
    @IBOutlet var userProfileCollection: UICollectionView!
    
    var posts = [String: PostItem]()
    var postsImages = [String: UIImageView]()
    var postsIds = [String]() // need it to order by date
    
    var cameFromSpotDetails = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setLoadingScreen()
        
        let currentUserId = User.getCurrentUserId()
        User.getItemById(for: currentUserId,
                         completion: { fetchedUserItem in
                            self.userInfo = fetchedUserItem
        })
        
        self.userProfileCollection.emptyDataSetSource = self
        self.userProfileCollection.emptyDataSetDelegate = self
    }
    
    // part for hide and view navbar from this navigation controller
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !cameFromSpotDetails {
            // Hide the navigation bar on the this view controller
            self.navigationController?.setNavigationBarHidden(true, animated: animated)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if !cameFromSpotDetails {
            // Show the navigation bar on other view controllers
            self.navigationController?.setNavigationBarHidden(false, animated: animated)
        }
    }
    
    func initializeUserTextInfo() {
        DispatchQueue.main.async {
            self.userBio.text = self.userInfo.bioDescription
            self.userNameAndSename.text = self.userInfo.nameAndSename
        }
        
        initialiseFollowing()
    }
    
    private func initialiseFollowing() {
        User.getFollowersCountString(
            userId: self.userInfo.uid,
            completion: { countOfFollowersString in
                self.followersButton.setTitle(countOfFollowersString, for: .normal)
        })
        
        User.getFollowingsCountString(
            userId: self.userInfo.uid,
            completion: { countOfFollowingsString in
                self.followingButton.setTitle(countOfFollowingsString, for: .normal)
        })
    }
    
    func initializeUserPhoto() {
        if self.userProfilePhoto != nil { // if we came not from user edit controller
            UserMedia.getURL(for: self.userInfo.uid, withSize: 150,
                             completion: { url in
                                DispatchQueue.main.async {
                                    self.userProfilePhoto.kf.setImage(with: url) //Using kf for caching images.
                                    self.userProfilePhoto.layer.cornerRadius = self.userProfilePhoto.frame.size.height / 2
                                }
            })
        }
    }
    
    func initializePostsPhotos() {
        User.getPostsIds(for: self.userInfo,
                         completion: { postsIds in
                            if postsIds != nil {
                                self.postsIds = postsIds!
                                
                                for postId in postsIds! {
                                    Post.getItemById(for: postId,
                                                     completion: { postItem in
                                                        if postItem != nil {
                                                            self.posts[postId] = postItem
                                                            self.downloadPhotosAsync(post: postItem!)
                                                            
                                                            //if all posts loaded
                                                            if self.posts.count == postsIds?.count {
                                                                self.userProfileCollection.reloadData()
                                                                self.removeLoadingScreen()
                                                            }
                                                        }
                                    })
                                }
                            }
        })
    }
    
    private func downloadPhotosAsync(post: PostItem) {
        self.postsImages[post.key] = UIImageView(image: UIImage(named: "grayRec.jpg"))
        
        PostMedia.getImageData270x270(for: post,
                                      completion: { data in
                                        guard let imageData = UIImage(data: data!) else { return }
                                        let photoView = UIImageView(image: imageData)
                                        
                                        self.postsImages[post.key] = photoView
                                        
                                        DispatchQueue.main.async {
                                            self.userProfileCollection.reloadData()
                                        }
        })
    }
    
    // MARK: - CollectionView part
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.postsImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RidersProfileCollectionViewCell", for: indexPath as IndexPath) as! RidersProfileCollectionViewCell
        
        cell.postPicture.image = self.postsImages[self.postsIds[indexPath.row]]?.image!
        
        return cell
    }
    
    fileprivate let itemsPerRow: CGFloat = 3
    fileprivate let sectionInsets = UIEdgeInsets(top: 1.0, left: 1.0, bottom: 1.0, right: 1.0)
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // handle tap events
        self.selectedCellId = indexPath.item
        self.performSegue(withIdentifier: "goToPostInfoFromUserProfile", sender: self)
    }
    
    var selectedCellId: Int!
    
    //MARK: - Buttons taps methods
    @IBAction func editProfileButtonTapped(_ sender: Any) {
        self.performSegue(withIdentifier: "editUserProfile", sender: self)
    }
    
    private var fromFollowersOrFollowing: Bool! // true - followers else following
    
    @IBAction func followersButtonTapped(_ sender: Any) {
        self.fromFollowersOrFollowing = true
        self.performSegue(withIdentifier: "goToFollowersFromUserNode", sender: self)
    }
    
    @IBAction func followingButtonTapped(_ sender: Any) {
        self.fromFollowersOrFollowing = false
        self.performSegue(withIdentifier: "goToFollowersFromUserNode", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToPostInfoFromUserProfile" {
            let newPostInfoController = segue.destination as! PostInfoViewController
            newPostInfoController.postInfo = self.posts[self.postsIds[selectedCellId]]
            newPostInfoController.user = userInfo
            newPostInfoController.isCurrentUserProfile = true
            newPostInfoController.delegateDeleting = self
        }
        //send current profile data to editing
        if segue.identifier == "editUserProfile" {
            let newEditProfileController = segue.destination as! EditProfileController
            newEditProfileController.userInfo = self.userInfo
            newEditProfileController.userPhoto = UIImageView()
            if let image = self.userProfilePhoto.image {
                newEditProfileController.userPhotoTemp = image
            }
            newEditProfileController.delegate = self
        }
        
        if segue.identifier == "goToFollowersFromUserNode" {
            let newFollowersController = segue.destination as! FollowersController
            newFollowersController.userId = userInfo.uid
            newFollowersController.followersOrFollowingList = self.fromFollowersOrFollowing
        }
    }
    
    // MARK: - when data loading
    let loadingView = UIView() // View which contains the loading text and the spinner
    let spinner = UIActivityIndicatorView()
    let loadingLabel = UILabel()
    
    var haveWeFinishedLoading = false // bool value have we loaded posts or not. Mainly for DZNEmptyDataSet
    
    // Set the activity indicator into the main view
    private func setLoadingScreen() {
        let width: CGFloat = 120
        let height: CGFloat = 30
        let x = (self.userProfileCollection.frame.width / 2) - (width / 2)
        let y = (self.userProfileCollection.frame.height / 2) - (height / 2) - (self.navigationController?.navigationBar.frame.height)!
        loadingView.frame = CGRect(x: x, y: y, width: width, height: height)
        
        self.loadingLabel.textColor = UIColor.gray
        self.loadingLabel.textAlignment = NSTextAlignment.center
        self.loadingLabel.text = "Loading..."
        self.loadingLabel.frame = CGRect(x: 0, y: 0, width: 140, height: 30)
        
        self.spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        self.spinner.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        self.spinner.startAnimating()
        
        loadingView.addSubview(self.spinner)
        loadingView.addSubview(self.loadingLabel)
        
        self.userProfileCollection.addSubview(loadingView)
    }
    
    // Remove the activity indicator from the main view
    private func removeLoadingScreen() {
        // Hides and stops the text and the spinner
        self.spinner.stopAnimating()
        self.loadingLabel.isHidden = true
        self.haveWeFinishedLoading = true
    }
}

extension UserProfileController: EditedUserInfoDelegate {
    func dataChanged(userInfo: UserItem, profilePhoto: UIImage) {
        self.userNameAndSename.text = userInfo.nameAndSename
        self.userBio.text = userInfo.bioDescription
        
        self.userProfilePhoto.image = profilePhoto
    }
}

extension UserProfileController: ForUpdatingUserProfilePosts {
    func postsDeleted(postId: String) {
        self.posts.removeValue(forKey: postId)
        self.postsImages.removeValue(forKey: postId)
        if let index = postsIds.index(of: postId) {
            postsIds.remove(at: index)
        }
        self.userProfileCollection.reloadData()
    }
}

extension UserProfileController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
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
            let str = "You have no publications"
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

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
    var userInfo: UserItem!
    
    @IBOutlet var userNameAndSename: UILabel!
    @IBOutlet var userBio: UITextView!
    @IBOutlet var userProfilePhoto: UIImageView!
    
    @IBOutlet var followersButton: UIButton!
    @IBOutlet var followingButton: UIButton!
    
    @IBOutlet var userProfileCollection: UICollectionView!
    var spotPosts = [PostItem]()
    var spotsPostsImages = [UIImageView]()
    var cameFromSpotDetails = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let currentUserId = FIRAuth.auth()?.currentUser?.uid
        let currentUserRef = FIRDatabase.database().reference(withPath: "MainDataBase/users").child(currentUserId!)
        
        currentUserRef.observe(.value, with: { snapshot in
            self.userInfo = UserItem(snapshot: snapshot)
            self.initializeUserTextInfo()
            self.initializeUserPhoto()
            self.initializeUserPostsPhotos()
        })
        
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
        self.userBio.text = userInfo.bioDescription
        self.userNameAndSename.text = userInfo.nameAndSename
        
        initialiseFollowing()
    }
    
    private func initialiseFollowing() {
        let refToUserNode = FIRDatabase.database().reference(withPath: "MainDataBase/users").child(self.userInfo.uid)
        
        let refFollowers = refToUserNode.child("followers")
        refFollowers.observe(.value, with: { snapshot in
            if let value = snapshot.value as? [String: Any] {
                self.followersButton.setTitle(String(describing: value.count), for: .normal)
            } else {
                self.followersButton.setTitle("0", for: .normal)
            }
        })
        
        let refFollowing = refToUserNode.child("following")
        refFollowing.observe(.value, with: { snapshot in
            if let value = snapshot.value as? [String: Any] {
                self.followingButton.setTitle(String(describing: value.count), for: .normal)
            } else {
                self.followingButton.setTitle("0", for: .normal)
            }
        })
    }
    
    func initializeUserPhoto() {
        let storage = FIRStorage.storage()
        let url = "gs://spotmap-e3116.appspot.com/media/userMainPhotoURLs/" + self.userInfo.uid + "_resolution150x150.jpeg"
        let riderPhotoURL = storage.reference(forURL: url)
        
        riderPhotoURL.downloadURL { (URL, error) in
            if let error = error {
                print("\(error)")
            } else {
                self.userProfilePhoto.kf.setImage(with: URL) //Using kf for caching images.
                self.userProfilePhoto.layer.cornerRadius = self.userProfilePhoto.frame.size.height / 2
            }
        }
    }
    
    func initializeUserPostsPhotos() {
        let ref = FIRDatabase.database().reference(withPath: "MainDataBase/users").child(self.userInfo.uid).child("posts")
        
        ref.observe(.value, with: { snapshot in
            if let value = snapshot.value as? [String: Any] {
                for (postId, _) in value {
                    let postInfoRef = FIRDatabase.database().reference(withPath: "MainDataBase/spotpost").child(postId)
                    postInfoRef.observeSingleEvent(of: .value, with: { snapshot in
                        let spotPostItem = PostItem(snapshot: snapshot)
                        
                        let photoRef = FIRStorage.storage().reference(forURL: "gs://spotmap-e3116.appspot.com/media/spotPostMedia/").child(spotPostItem.spotId).child(spotPostItem.key + "_resolution270x270.jpeg")
                        
                        photoRef.downloadURL { (URL, error) in
                            if let error = error {
                                print("\(error)")
                            } else {
                                let photoData = NSData(contentsOf: URL!)
                                let photo = UIImage(data: photoData as! Data)!
                                let photoView = UIImageView(image: photo)
                                
                                self.spotsPostsImages.append(photoView)
                                self.spotPosts.append(spotPostItem)
                                
                                DispatchQueue.main.async {
                                    self.userProfileCollection.reloadData()
                                }
                            }
                        }
                    })
                }
            }
        })
    }
    
    // MARK: COLLECTIONVIEW PART
    // tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.spotsPostsImages.count
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RidersProfileCollectionViewCell", for: indexPath as IndexPath) as! RidersProfileCollectionViewCell
        
        // Use the outlet in our custom class to get a reference to the UILabel in the cell
        cell.postPicture.image = self.spotsPostsImages[indexPath.row].image!
        
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
            //let key = Array(self.spotPosts.keys)[selectedCellId]
            newPostInfoController.postInfo = spotPosts[selectedCellId]
            newPostInfoController.user = userInfo
        }
        //send current profile data to editing
        if segue.identifier == "editUserProfile" {
            let newEditProfileController = segue.destination as! EditProfileController
            newEditProfileController.userInfo = self.userInfo
            newEditProfileController.userPhoto = UIImageView()
            if let image = self.userProfilePhoto.image {
                newEditProfileController.userPhotoTemp = image
            }
        }
        
        if segue.identifier == "goToFollowersFromUserNode" {
            let newFollowersController = segue.destination as! FollowersController
            newFollowersController.userId = userInfo.uid
            newFollowersController.followersOrFollowingList = self.fromFollowersOrFollowing
        }
    }
}

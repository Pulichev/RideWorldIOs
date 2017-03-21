//
//  RidersProfileController.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 15.02.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth

class RidersProfileController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    var ridersInfo: UserItem!
    
    @IBOutlet var userNameAndSename: UILabel!
    @IBOutlet var ridersBio: UITextView!
    @IBOutlet var ridersProfilePhoto: UIImageView!
    
    @IBOutlet var followButton: UIButton!
    
    @IBOutlet var followersButton: UIButton!
    @IBOutlet var followingButton: UIButton!
    
    @IBOutlet var riderProfileCollection: UICollectionView!
    var posts = [PostItem]()
    var postsImages = [UIImageView]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.riderProfileCollection.emptyDataSetSource = self
        self.riderProfileCollection.emptyDataSetDelegate = self
        
        DispatchQueue.main.async {
            self.initializeUserTextInfo() //async loading user
            self.initializeUserPhoto()
            self.initializeUserPostsPhotos()
        }
    }
    
    private func initializeUserTextInfo() {
        self.ridersBio.text = ridersInfo.bioDescription
        self.userNameAndSename.text = ridersInfo.nameAndSename
        
        checkIfCurrentUserFollowing() // this function also places title on button
        initialiseFollowing()
    }
    
    private func checkIfCurrentUserFollowing() {
        let currentUserId = FIRAuth.auth()?.currentUser?.uid
        let refToCurrentUser = FIRDatabase.database().reference(withPath: "MainDataBase/users").child(currentUserId!).child("following")
        
        refToCurrentUser.observeSingleEvent(of: .value, with: { snapshot in
            if var value = snapshot.value as? [String : Bool] {
                if value[self.ridersInfo.uid] != nil {
                    self.followButton.setTitle("Following", for: .normal)
                } else {
                    self.followButton.setTitle("Follow", for: .normal)
                }
            } else {
                self.followButton.setTitle("Follow", for: .normal)
            }
            
            self.followButton.isEnabled = true
        })
    }
    
    private func initialiseFollowing() {
        let refToUserNode = FIRDatabase.database().reference(withPath: "MainDataBase/users").child(self.ridersInfo.uid)
        
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
        let url = "gs://spotmap-e3116.appspot.com/media/userMainPhotoURLs/" + self.ridersInfo.uid + "_resolution150x150.jpeg"
        let riderPhotoURL = storage.reference(forURL: url)
        
        riderPhotoURL.downloadURL { (URL, error) in
            if let error = error {
                print("\(error)")
            } else {
                self.ridersProfilePhoto.kf.setImage(with: URL) //Using kf for caching images.
                self.ridersProfilePhoto.layer.cornerRadius = self.ridersProfilePhoto.frame.size.height / 2
            }
        }
    }
    
    func initializeUserPostsPhotos() {
        let ref = FIRDatabase.database().reference(withPath: "MainDataBase/users").child(self.ridersInfo.uid).child("posts") // ref for riders posts ids list
        
        ref.observeSingleEvent(of: .value, with: { snapshot in
            if let value = snapshot.value as? [String: Any] {
                for (postId, _) in value { // for each user post geting full post item
                    let postInfoRef = FIRDatabase.database().reference(withPath: "MainDataBase/spotpost").child(postId)
                    postInfoRef.observeSingleEvent(of: .value, with: { snapshot in
                        let spotPostItem = PostItem(snapshot: snapshot)
                        
                        let photoRef = FIRStorage.storage().reference(forURL: "gs://spotmap-e3116.appspot.com/media/spotPostMedia/").child(spotPostItem.spotId).child(spotPostItem.key + "_resolution270x270.jpeg")
                        
                        photoRef.downloadURL { (URL, error) in
                            if let error = error {
                                print("\(error)")
                            } else {
                                // async images downloading
                                URLSession.shared.dataTask(with: URL!, completionHandler: { (data, response, error) in
                                    if error != nil {
                                        print(error.debugDescription)
                                        return
                                    } else {
                                        guard let imageData = UIImage(data: data!) else { return }
                                        let photoView = UIImageView(image: imageData)
                                        
                                        self.postsImages.append(photoView)
                                        self.posts.append(spotPostItem) // adding it here cz with threading our posts and images can be bad ordering
                                        
                                        DispatchQueue.main.async {
                                            self.riderProfileCollection.reloadData()
                                        }
                                    }
                                }).resume()
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
        return self.postsImages.count
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RidersProfileCollectionViewCell", for: indexPath as IndexPath) as! RidersProfileCollectionViewCell
        
        // Use the outlet in our custom class to get a reference to the UILabel in the cell
        cell.postPicture.image = self.postsImages[indexPath.row].image!
        
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
        self.performSegue(withIdentifier: "goToPostInfo", sender: self)
    }
    
    var selectedCellId: Int!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToPostInfo" {
            let newPostInfoController = (segue.destination as! PostInfoViewController)
            newPostInfoController.postInfo = posts[selectedCellId]
            newPostInfoController.user = ridersInfo
        }
        
        if segue.identifier == "goToFollowersFromRidersNode" {
            let newFollowersController = segue.destination as! FollowersController
            newFollowersController.userId = self.ridersInfo.uid
            newFollowersController.followersOrFollowingList = self.fromFollowersOrFollowing
        }
    }
    
    // MARK: Following logic
    @IBAction func followButtonTapped(_ sender: Any) {
        let refToUsers = FIRDatabase.database().reference(withPath: "MainDataBase/users")
        let currentUserId = FIRAuth.auth()?.currentUser?.uid
        
        addOrRemoveFollow(mainPartOfReference: refToUsers, currentUserId: currentUserId!)
    }
    
    private var fromFollowersOrFollowing: Bool! // true - followers else following
    
    @IBAction func followersButtonTapped(_ sender: Any) {
        self.fromFollowersOrFollowing = true
        self.performSegue(withIdentifier: "goToFollowersFromRidersNode", sender: self)
    }
    
    @IBAction func followingButtonTapped(_ sender: Any) {
        self.fromFollowersOrFollowing = false
        self.performSegue(withIdentifier: "goToFollowersFromRidersNode", sender: self)
    }
    
    private func addOrRemoveFollow(mainPartOfReference: FIRDatabaseReference, currentUserId: String) {
        // to current user node
        let refToCurrentUser = mainPartOfReference.child(currentUserId).child("following")
        refToCurrentUser.observeSingleEvent(of: .value, with: { snapshot in
            if var value = snapshot.value as? [String : Bool] {
                if self.followButton.currentTitle == "Follow" { // add or remove like
                    value[self.ridersInfo.uid] = true
                } else {
                    value.removeValue(forKey: self.ridersInfo.uid)
                }
                refToCurrentUser.setValue(value)
            } else {
                refToCurrentUser.setValue([self.ridersInfo.uid : true])
            }
            
            // to aim user node
            self.addOrRemoveFollowToAimUserNode(mainPartOfReference: mainPartOfReference, currentUserId: currentUserId)
        })
    }
    
    private func addOrRemoveFollowToAimUserNode(mainPartOfReference: FIRDatabaseReference, currentUserId: String) {
        let refToAimUser = mainPartOfReference.child(ridersInfo.uid).child("followers")
        refToAimUser.observeSingleEvent(of: .value, with: { snapshot in
            if var value = snapshot.value as? [String : Bool] {
                if self.followButton.currentTitle == "Follow" { // add or remove like
                    value[currentUserId] = true
                } else {
                    value.removeValue(forKey: currentUserId)
                }
                refToAimUser.setValue(value)
            } else {
                refToAimUser.setValue([currentUserId : true])
            }
            
            self.swapFollowButtonTittle()
        })
    }
    
    private func swapFollowButtonTittle() {
        if self.followButton.currentTitle == "Follow" {
            self.followButton.setTitle("Following", for: .normal)
        } else {
            self.followButton.setTitle("Follow", for: .normal)
        }
    }

    // MARK: DZNEmptyDataSet for empty data tables
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let str = "Welcome"
        let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let str = "Riders have no publications"
        let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return ImageManipulations.resize(image: UIImage(named: "no_photo.png")!, targetSize: CGSize(width: 300.0, height: 300.0))
    }
    // ENDMARK: DZNEmptyDataSet
}

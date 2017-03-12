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

class RidersProfileController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    var ridersInfo: UserItem!
    
    @IBOutlet var userNameAndSename: UILabel!
    @IBOutlet var ridersBio: UITextView!
    @IBOutlet var ridersProfilePhoto: UIImageView!
    
    @IBOutlet var riderProfileCollection: UICollectionView!
    var spotPosts = [SpotPostItem]()
    var spotsPostsImages = [UIImageView]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.main.async {
            self.initializeUserTextInfo() //async loading user
            self.initializeUserPhoto()
            self.initializeUserPostsPhotos()
        }
    }
    
    func initializeUserTextInfo() {
        self.ridersBio.text = ridersInfo.bioDescription
        self.userNameAndSename.text = ridersInfo.nameAndSename
        
//        placeBorderOnTextView()
    }
    
    func placeBorderOnTextView() {
        ridersBio.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
        ridersBio.layer.borderWidth = 1.0
        ridersBio.layer.cornerRadius = 5
    }
    
    func initializeUserPhoto() {
        let storage = FIRStorage.storage()
        let url = "gs://spotmap-e3116.appspot.com/media/userMainPhotoURLs/" + self.ridersInfo.uid + ".jpeg"
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
        let ref = FIRDatabase.database().reference(withPath: "MainDataBase/users").child(self.ridersInfo.uid).child("posts")
        
        ref.observeSingleEvent(of: .value, with: { snapshot in
            if let value = snapshot.value as? NSDictionary {
                for post in value {
                    let postInfoRef = FIRDatabase.database().reference(withPath: "MainDataBase/spotpost").child(post.key as! String)
                    postInfoRef.observeSingleEvent(of: .value, with: { snapshot in
                        let spotPostItem = SpotPostItem(snapshot: snapshot)
                        let photoRef = FIRStorage.storage().reference(forURL: "gs://spotmap-e3116.appspot.com/media/spotPostMedia/").child(spotPostItem.spotId).child(spotPostItem.key + "_resolution270x270.jpeg")
                        
                        photoRef.downloadURL { (URL, error) in
                            if let error = error {
                                print("\(error)")
                            } else {
                                DispatchQueue.global(qos: .userInteractive).async {
                                    let photoData = NSData(contentsOf: URL!)
                                    let photo = UIImage(data: photoData as! Data)!
                                    let photoView = UIImageView(image: photo)
                                    
                                    self.spotsPostsImages.append(photoView)
                                    DispatchQueue.main.async {
                                        self.riderProfileCollection.reloadData()
                                    }
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
        cell.postPicture.image = self.spotsPostsImages[indexPath.row].image
        
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
            newPostInfoController.postInfo = spotPosts[selectedCellId]
            newPostInfoController.user = ridersInfo
        }
    }
    
    // MARK: Following logic
    @IBAction func followButtonTapped(_ sender: Any) {
        let refToUsers = FIRDatabase.database().reference(withPath: "MainDataBase/users")
        
        // adding follow to current user node
        
        // adding follow to aim user node
    }
}

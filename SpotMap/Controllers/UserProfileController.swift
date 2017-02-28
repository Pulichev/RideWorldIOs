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

class UserProfileController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    var userInfo = Users()
    
    var backendless: Backendless!
    
    @IBOutlet var userNameAndSename: UILabel!
    @IBOutlet var recpectedTimes: UILabel!
    @IBOutlet var userBio: UITextView!
    @IBOutlet var userProfilePhoto: UIImageView!
    
    @IBOutlet var userProfileCollection: UICollectionView!
    var spotPosts = [SpotPost]()
    var spotsPostsImages = [UIImageView]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.main.async {
            self.backendless = Backendless.sharedInstance()
            
            self.getCurrentUser()
            self.initializeUserTextInfo() //async loading user
            self.initializeUserPhoto()
            self.initializeUserPostsPhotos()
        }
    }
    
    func getCurrentUser() {
        self.userInfo = TypeUsersFromBackendlessUser.returnUser(backendlessUser: (backendless?.userService.currentUser)!)
    }
    
    //part for hide and view navbar from this navigation controller
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide the navigation bar on the this view controller
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show the navigation bar on other view controllers
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    func initializeUserTextInfo() {
        self.userBio.text = userInfo.userBioDescription
        self.userNameAndSename.text = userInfo.userNameAndSename
        
        placeBorderOnTextView()
    
        DispatchQueue.global().async {
            let whereClause1 = "post.ownerId = '\(self.userInfo.objectId!)'"
            let dataQuery1 = BackendlessDataQuery()
            dataQuery1.whereClause = whereClause1
            
            let usersLikes = self.backendless.data.of(PostLike.ofClass()).find(dataQuery1)
            
            DispatchQueue.main.async {
                self.recpectedTimes.text = String(describing: (usersLikes?.data.count)!)
            }
        }
    }
    
    func placeBorderOnTextView() {
        userBio.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
        userBio.layer.borderWidth = 1.0
        userBio.layer.cornerRadius = 5
    }
    
    func initializeUserPhoto() {
        DispatchQueue.global(qos: .userInteractive).async {
            let userPhotoURL = "https://api.backendless.com/4B2C12D1-C6DE-7B3E-FFF0-80E7D3628C00/v1/files/media/userProfilePhotos/" + (self.userInfo.objectId!).replacingOccurrences(of: "-", with: "") + ".jpeg"
            let userPhotoData = NSData(contentsOf: URL(string: userPhotoURL)!)
            let userPhoto = UIImage(data: userPhotoData as! Data)!
            
            DispatchQueue.main.async {
                self.userProfilePhoto.image = userPhoto
                self.userProfilePhoto.layer.cornerRadius = self.userProfilePhoto.frame.size.height / 2
            }
        }
    }
    
    func initializeUserPostsPhotos() {
        DispatchQueue.global(qos: .userInteractive).async {
            let whereClause = "user.objectId = '\(self.userInfo.objectId!)'"
            let dataQuery = BackendlessDataQuery()
            dataQuery.whereClause = whereClause
            
            var error: Fault?
            
            let spotPostsList = self.backendless.data.of(SpotPost.ofClass()).find(dataQuery, fault: &error)
            self.spotPosts = spotPostsList?.data as! [SpotPost]
            
            for spotPost in self.spotPosts {
                var photo = UIImage()
                var mediaURL = "https://api.backendless.com/4B2C12D1-C6DE-7B3E-FFF0-80E7D3628C00/v1/files/media/"
                
                mediaURL += "spotPostMediaThumbnails/" + (spotPost.objectId!).replacingOccurrences(of: "-", with: "") + ".jpeg"
                let photoData = NSData(contentsOf: URL(string: mediaURL)!)
                photo = UIImage(data: photoData as! Data)!
                let photoView = UIImageView(image: photo)
                
                DispatchQueue.main.async {
                    self.spotsPostsImages.append(photoView)
                    self.userProfileCollection.reloadData()
                }
            }
        }
    }
    
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
    
    // MARK: - UICollectionViewDelegate protocol
    
    
    @IBAction func editProfileButtonTapped(_ sender: Any) {
        self.performSegue(withIdentifier: "editUserProfile", sender: self)
    }
    
    var selectedCellId: Int!
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // handle tap events
        self.selectedCellId = indexPath.item
        self.performSegue(withIdentifier: "goToPostInfoFromUserProfile", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToPostInfoFromUserProfile" {
            let newPostInfoController = segue.destination as! PostInfoViewController
            newPostInfoController.postInfo = spotPosts[selectedCellId]
            newPostInfoController.user = userInfo
        }
        //send current profile data to editing
        if segue.identifier == "editUserProfile" {
            let newEditProfileController = segue.destination as! EditProfileController
            newEditProfileController.userInfo = self.userInfo
            newEditProfileController.userPhoto = UIImageView()
            newEditProfileController.userPhotoTemp = self.userProfilePhoto.image!
        }
    }
}

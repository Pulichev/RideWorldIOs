//
//  FollowersTableCell.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 14.03.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import Foundation
import UIKit
import FirebaseStorage
import FirebaseAuth
import FirebaseDatabase
import Kingfisher

class FollowersCell: UITableViewCell {
    var currentUserId: String!
    
    @IBOutlet weak var nickName: UILabel!
    @IBOutlet weak var userImage: RoundedImageView!
    @IBOutlet weak var button: UIButton!
    
    var follower: UserItem! {
        didSet {
            self.nickName.text = follower.login
            self.initialiseUserPhoto()
            self.initialiseFollowButton()
        }
    }
    
    func initialiseUserPhoto() {
        let storage = FIRStorage.storage()
        let url = "gs://spotmap-e3116.appspot.com/media/userMainPhotoURLs/" + self.follower.uid + "_resolution90x90.jpeg"
        let riderPhotoURL = storage.reference(forURL: url)
        
        riderPhotoURL.downloadURL { (URL, error) in
            if let error = error {
                print("\(error)")
            } else {
                self.userImage.kf.setImage(with: URL) //Using kf for caching images.
            }
        }
    }
    
    func initialiseFollowButton() {
        self.currentUserId = FIRAuth.auth()?.currentUser?.uid
        
        let refToCurrentUserFollowings = FIRDatabase.database().reference(withPath: "MainDataBase/users/").child(currentUserId!).child("following")
        
        refToCurrentUserFollowings.observeSingleEvent(of: .value, with: { snapshot in
            
            if self.follower.uid != self.currentUserId! { // if this follower - current user then hide button
                self.button.setTitle("Follow", for: .normal) // default user is not following
                if let listOfFollowers = snapshot.value as? [String: Bool] {
                    if listOfFollowers.keys.contains(self.follower.uid) {
                        self.button.setTitle("Following", for: .normal)
                    }
                }
            } else {
                self.button.isHidden = true
            }
        })
    }
    
    @IBAction func followButtonTapped(_ sender: Any) {
        let refToUsers = FIRDatabase.database().reference(withPath: "MainDataBase/users")
        
        addOrRemoveFollow(mainPartOfReference: refToUsers)
    }
    
    private func addOrRemoveFollow(mainPartOfReference: FIRDatabaseReference) {
        // to current user node
        let refToCurrentUser = mainPartOfReference.child(self.currentUserId!).child("following")
        refToCurrentUser.observeSingleEvent(of: .value, with: { snapshot in
            if var value = snapshot.value as? [String : Bool] {
                if self.button.currentTitle == "Follow" { // add or remove like
                    value[self.follower.uid] = true
                } else {
                    value.removeValue(forKey: self.follower.uid)
                }
                refToCurrentUser.setValue(value)
            } else {
                refToCurrentUser.setValue([self.follower.uid : true])
            }
            
            // to aim user node
            self.addOrRemoveFollowToAimUserNode(mainPartOfReference: mainPartOfReference)
        })
    }
    
    private func addOrRemoveFollowToAimUserNode(mainPartOfReference: FIRDatabaseReference) {
        let refToAimUser = mainPartOfReference.child(self.follower.uid).child("followers")
        refToAimUser.observeSingleEvent(of: .value, with: { snapshot in
            if var value = snapshot.value as? [String : Bool] {
                if self.button.currentTitle == "Follow" { // add or remove like
                    value[self.currentUserId] = true
                } else {
                    value.removeValue(forKey: self.currentUserId)
                }
                refToAimUser.setValue(value)
            } else {
                refToAimUser.setValue([self.currentUserId : true])
            }
            
            self.swapFollowButtonTittle()
        })
    }
    
    private func swapFollowButtonTittle() {
        if self.button.currentTitle == "Follow" {
            self.button.setTitle("Following", for: .normal)
        } else {
            self.button.setTitle("Follow", for: .normal)
        }
    }
}

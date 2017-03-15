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

class FollowersTableCell: UITableViewCell {
    @IBOutlet weak var nickName: UILabel!
    @IBOutlet weak var userImage: UIImageView!
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
        let url = "gs://spotmap-e3116.appspot.com/media/userMainPhotoURLs/" + self.follower.uid + ".jpeg"
        let riderPhotoURL = storage.reference(forURL: url)
        
        riderPhotoURL.downloadURL { (URL, error) in
            if let error = error {
                print("\(error)")
            } else {
                self.userImage.kf.setImage(with: URL) //Using kf for caching images.
                self.userImage.layer.cornerRadius = self.userImage.frame.size.height / 2
            }
        }
    }
    
    func initialiseFollowButton() {
        let currentUserId = FIRAuth.auth()?.currentUser?.uid
        
        let refToCurrentUserFollowings = FIRDatabase.database().reference(withPath: "MainDataBase/users/").child(currentUserId!).child("following")
        
        refToCurrentUserFollowings.observeSingleEvent(of: .value, with: { snapshot in
            let value = snapshot.value as? NSDictionary
            if value?[self.follower.uid] != nil {
                self.button.setTitle("Following", for: .normal)
            } else {
                self.button.setTitle("Follow", for: .normal)
            }
        })
    }
}

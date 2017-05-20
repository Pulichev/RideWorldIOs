//
//  CommentFeedBackCell.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 11.05.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import ActiveLabel

class CommentAndLikeFBCell: UITableViewCell { // FB = feedback
   weak var delegateUserTaps: TappedUserDelegate? // for sending user info
   weak var delegatePostTaps: TappedPostDelegate? // for sending post info
   
   var userId: String! { // maybe userItem
      didSet {
         User.getItemById(for: userId) { user in
            self.userItem = user
            
            self.userPhoto.image = UIImage(named: "grayRec.jpg") // default picture
            if let url = user.photo90ref {
               self.userPhoto?.kf.setImage(with: URL(
                  string: url))
            }
            self.userLoginButton.setTitle(user.login,
                                          for: .normal)
         }
      }
   }
   
   var userItem: UserItem!
   
   var postId: String! { // maybe postItem
      didSet {
         Post.getItemById(for: postId) { post in
            if post != nil {
               self.postItem = post
               self.postPhoto?.kf.setImage(with: URL(
                  string: post!.mediaRef700)) // TODO: after release/db drop set .mediaRef270
            }
         }
      }
   }
   
   var postItem: PostItem!
   
   // MARK: - @IBOutlets
   // media
   @IBOutlet weak var userPhoto: RoundedImageView! {
      didSet {
         let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(userInfoTapped))
         userPhoto.isUserInteractionEnabled = true
         userPhoto.addGestureRecognizer(tapGestureRecognizer)
      }
   }
   
   @IBOutlet weak var postPhoto: UIImageView! {
      didSet {
         let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(postInfoTapped))
         postPhoto.isUserInteractionEnabled = true
         postPhoto.addGestureRecognizer(tapGestureRecognizer)
      }
   }
   
   // text info
   @IBOutlet weak var userLoginButton: UIButton!
   @IBOutlet weak var desc: ActiveLabel!
   @IBOutlet weak var dateTime: UILabel!
   
   override func awakeFromNib() {
      super.awakeFromNib()
      // Initialization code
   }
   
   override func setSelected(_ selected: Bool, animated: Bool) {
      super.setSelected(selected, animated: animated)
      
      // Configure the view for the selected state
   }
   
   @IBAction func loginButtonTapped(_ sender: UIButton) {
      userInfoTapped()
   }
   
   func userInfoTapped() {
      delegateUserTaps?.userInfoTapped(userItem)
   }
   
   func postInfoTapped() {
      delegatePostTaps?.postInfoTapped(postItem)
   }
}

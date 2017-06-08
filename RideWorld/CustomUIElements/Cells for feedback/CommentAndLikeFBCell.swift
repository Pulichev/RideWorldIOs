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
            
            self.userPhoto.image = UIImage(named: "grayRec.png") // default picture
            if let url = user.photo90ref {
               self.userPhoto?.kf.setImage(with: URL(
                  string: url))
            }
         }
      }
   }
   
   var userItem: UserItem! {
      didSet {
         desc.text = userItem.login + desc.text!
         
         desc.customize { description in
            let loginTappedType = ActiveType.custom(pattern: "\\s\(userItem.login)\\b") //Looks for userItem.login
            description.enabledTypes.append(loginTappedType)
            description.handleCustomTap(for: loginTappedType) { login in self.userInfoTapped() }
            description.customColor[loginTappedType] = UIColor.purple
         }
      }
   }
   
   var postAddedByUser: String!
   
   var postId: String!
   
   var postItem: PostItem! {
      didSet {
         postPhoto?.kf.setImage(with: URL(
            string: postItem.mediaRef70))
      }
   }
   
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
   @IBOutlet weak var desc: ActiveLabel! {
      didSet {
         desc.handleMentionTap { mention in // mention is @userLogin
            self.goToUserProfile(tappedUserLogin: mention)
         }
      }
   }
   
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
   
   // from @username
   private func goToUserProfile(tappedUserLogin: String) {
      User.getItemByLogin(
      for: tappedUserLogin) { fetchedUserItem in
         self.delegateUserTaps?.userInfoTapped(fetchedUserItem)
      }
   }
}

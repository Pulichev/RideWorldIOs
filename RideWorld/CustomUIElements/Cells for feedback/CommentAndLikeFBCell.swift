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
   
   var userItem: UserItem! {
      didSet {
         self.userPhoto.image = UIImage(named: "grayRec.png") // default picture
         if let url = userItem.photo90ref {
            self.userPhoto?.kf.setImage(with: URL(
               string: url))
         } else {
            self.userPhoto?.setImage(string: userItem.login, color: nil, circular: true,
                                     textAttributes: [NSFontAttributeName: UIFont(name: "Roboto-Light", size: 20)])
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
   var descText: String! {
      didSet {
         desc.text = descText
         
         customizeDescUserLogin()
      }
   }
   
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
   
   func userInfoTapped() {
      delegateUserTaps?.userInfoTapped(userItem)
   }
   
   func postInfoTapped() {
      delegatePostTaps?.postInfoTapped(postItem)
   }
   
   // from @username
   private func goToUserProfile(tappedUserLogin: String) {
      UserModel.getItemByLogin(
      for: tappedUserLogin) { fetchedUserItem, _ in
         self.delegateUserTaps?.userInfoTapped(fetchedUserItem)
      }
   }
   
   private func customizeDescUserLogin() {
      desc.customize { description in
         //Looks for userItem.login
         let loginTappedType = ActiveType.custom(pattern: "^\(userItem.login)\\b")
         description.enabledTypes.append(loginTappedType)
         description.handleCustomTap(for: loginTappedType) { login in
            self.userInfoTapped()
         }
         description.customColor[loginTappedType] = UIColor.black
         
         desc.configureLinkAttribute = { (type, attributes, isSelected) in
            var atts = attributes
            switch type {
            case .custom(pattern: "^\(self.userItem.login)\\b"):
               atts[NSFontAttributeName] = UIFont(name: "Roboto-Medium", size: 15)
            default: ()
            }
            
            return atts
         }
         
         description.handleMentionTap { mention in // mention is @userLogin
            self.goToUserProfile(tappedUserLogin: mention)
         }
      }
   }
}

//
//  CommentCell.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 02.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import ActiveLabel
import MGSwipeTableCell

class CommentCell: MGSwipeTableCell {
   weak var delegateUserTaps: TappedUserDelegate? // for sending user info
   
   @IBOutlet weak var userPhoto: RoundedImageView!
   @IBOutlet weak var userNickName: UIButton!
   
   var comment: CommentItem! {
      didSet {
         // Formatting date to yyyy-mm-dd
         date.text = DateTimeParser.getDateTime(from: comment.datetime)
      }
   }
   
   var userItem: UserItem! {
      didSet {
         initialiseUserPhoto()
      }
   }
   
   var commentTextInfo: String! {
      didSet {
         commentText.text = commentTextInfo
         customizeWithActiveLabel()
      }
   }
   @IBOutlet weak var commentText: ActiveLabel!
   @IBOutlet weak var date: UILabel!
   
   func initialiseUserPhoto() {
      userPhoto.image = UIImage(named: "grayRec.png")
      
      if userItem.photo90ref != nil {
         userPhoto.kf.setImage(with: URL(string: userItem.photo90ref!)) // Using kf for caching images.
      } else {
         userPhoto.setImage(string: userItem.login, color: UIColor.myLightGray(), circular: true,
                             textAttributes: [NSFontAttributeName: UIFont(name: "Roboto-Light", size: 20)])
      }
   }
   
   func initialiseUserButton() {
      UserModel.getItemById(for: comment.userId) { userItem in
         self.userNickName.setTitle(userItem.login, for: .normal)
      }
   }
   
   func userInfoTapped() {
      delegateUserTaps?.userInfoTapped(userItem)
   }
   
   // from @username
   private func goToUserProfile(tappedUserLogin: String) {
      UserModel.getItemByLogin(
      for: tappedUserLogin) { fetchedUserItem, _ in
         self.delegateUserTaps?.userInfoTapped(fetchedUserItem)
      }
   }
   
   private func customizeWithActiveLabel() {
      commentText.customize { description in
         //Looks for userItem.login
         let loginTappedType = ActiveType.custom(pattern: "^\(userItem.login)\\b")
         description.enabledTypes.append(loginTappedType)
         description.handleCustomTap(for: loginTappedType) { login in self.userInfoTapped() }
         description.customColor[loginTappedType] = UIColor.black
         description.numberOfLines = 0
         
         description.configureLinkAttribute = { (type, attributes, isSelected) in
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

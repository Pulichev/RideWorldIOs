//
//  StyledButton.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 06.08.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

class FollowButton: UIButtonX {
   
   override init(frame: CGRect) {
      super.init(frame: frame)
      
      cornerRadius = 10
      borderWidth = 1
      borderColor = UIColor.myBlack()
      backgroundColor = UIColor.myLightGray()
      setTitle("...", for: .normal)
   }
   
   required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
      
      cornerRadius = 10
      borderWidth = 1
      borderColor = UIColor.myBlack()
      backgroundColor = UIColor.myLightGray()
      setTitle("...", for: .normal)
   }
   
   override func setTitle(_ title: String?, for state: UIControlState) {
      super.setTitle(title, for: state)
      
      if title! == NSLocalizedString("Follow", comment: "") {
         backgroundColor = UIColor.myBlack()
         tintColor = UIColor.myLightBrown()
         borderColor = UIColor.myLightBrown()
         setTitleColor(UIColor.myLightBrown(), for: .normal)
      } else {
         backgroundColor = UIColor.myLightBrown()
         tintColor = UIColor.myBlack()
         borderColor = UIColor.myBlack()
         setTitleColor(UIColor.myBlack(), for: .normal)
      }
   }
}

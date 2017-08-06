//
//  StyledButton.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 06.08.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

class StyledButton: UIButtonX {
   
   override init(frame: CGRect) {
      super.init(frame: frame)
      
      cornerRadius = 5
   }
   
   required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
      
      cornerRadius = 5
   }
   
   override func setTitle(_ title: String?, for state: UIControlState) {
      super.setTitle(title, for: state)
      
      if title! == "Follow" {
         backgroundColor = UIColor.myDarkBlue()
         tintColor = UIColor.myLightBrown()
      } else {
         backgroundColor = UIColor.myLightBrown()
         tintColor = UIColor.myDarkBlue()
      }
   }
}

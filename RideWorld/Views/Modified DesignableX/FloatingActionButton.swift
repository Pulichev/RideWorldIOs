//
//  FloatingActionButton.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 25.07.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit

class FloatingActionButton: UIButtonX {
   
   override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
      
      UIView.animate(withDuration: 0.3, animations: {
         if self.transform == .identity {
            self.transform = CGAffineTransform(rotationAngle: 0.25 * .pi)
            self.backgroundColor = UIColor.myDarkGray()
            self.tintColor = UIColor.myLightGray()
         } else {
            self.transform = .identity
            self.backgroundColor = UIColor.myLightGray()
            self.tintColor = UIColor.myDarkGray()
         }
      })
      
      return super.beginTracking(touch, with: event)
   }
   
   override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
   }
}

//
//  MapButton.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 26.07.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit

class MapButton: UIButton {
   
   override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
      
      UIView.animate(withDuration: 0.5) {
         self.transform = CGAffineTransform(rotationAngle: .pi)
         self.tintColor = UIColor.tabBarButtonActive()
      }
      
      UIView.animate(withDuration: 0.5, delay: 0.25, options: UIViewAnimationOptions.curveEaseIn, animations: {
         self.transform = CGAffineTransform(rotationAngle: .pi * 2)
         self.tintColor = UIColor.tabBarButtonActive()
      }, completion: nil)
      
      return super.beginTracking(touch, with: event)
   }
   
   override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
   }
}


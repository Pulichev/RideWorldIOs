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
            self.transform = CGAffineTransform(rotationAngle: 0.5 * .pi)
         } else {
            self.transform = .identity
         }
      })
      
      return super.beginTracking(touch, with: event)
   }
   
   override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
   }
}

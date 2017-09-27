//
//  SpotAnnotationView.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 27.09.2017.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import MapKit

class SpotAnnotationView: MKAnnotationView {
   
   override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
      let hitView = super.hitTest(point, with: event)
      if hitView != nil {
         self.superview?.bringSubview(toFront: self)
      }
      
      return hitView
   }
   
   override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
      let rect = self.bounds
      var isInside: Bool = rect.contains(point)
      
      if !isInside {
         for view in self.subviews {
            isInside = view.frame.contains(point)
            
            if isInside {
               break
            }
         }
      }
      
      return isInside
   }
}

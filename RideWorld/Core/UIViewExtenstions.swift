//
//  UIViewExtenstions.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 06.07.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

extension UIView {
   
   var parentViewController: UIViewController? {
      var parentResponder: UIResponder? = self
      while parentResponder != nil {
         parentResponder = parentResponder!.next
         if parentResponder is UIViewController {
            return parentResponder as! UIViewController!
         }
      }
      return nil
   }
}

//
//  LoadingProcessView.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 05.05.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit

class LoadingProcessView: UIView {
   private let spinner = UIActivityIndicatorView()
   private let loadingLabel = UILabel()
   
   override init(frame: CGRect) {
      super.init(frame: frame)
      
      addLoadingLabel()
      addSpinner()
   }
   
   init(center: CGPoint) {
      super.init(frame: CGRect(x: 0, y: 0, width: 110, height: 20))
      self.center = center
      
      addLoadingLabel()
      addSpinner()
   }

   required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
   }
   
   private func addLoadingLabel() {
      loadingLabel.textColor = UIColor.gray
      loadingLabel.textAlignment = NSTextAlignment.center
      loadingLabel.text = "Loading..."
      self.addSubview(loadingLabel)
      loadingLabel.frame = CGRect(x: 20, y: -35, width: 90, height: 20)
   }
   
   private func addSpinner() {
      spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
      self.addSubview(spinner)
      spinner.frame = CGRect(x: 0, y: -35, width: 20, height: 20)
   }
   
   func show() {
      loadingLabel.isHidden = false
      spinner.startAnimating()
   }
   
   func dismiss() {
      loadingLabel.isHidden = true
      spinner.stopAnimating()
   }
}

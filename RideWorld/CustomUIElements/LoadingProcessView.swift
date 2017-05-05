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

   required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
   }
   
   private func addLoadingLabel() {
      loadingLabel.textColor = UIColor.gray
      loadingLabel.textAlignment = NSTextAlignment.center
      loadingLabel.text = "Loading..."
      loadingLabel.frame = CGRect(x: 0, y: 0, width: 140, height: 30)
      self.addSubview(loadingLabel)
   }
   
   private func addSpinner() {
      spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
      spinner.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
      
      self.addSubview(spinner)
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

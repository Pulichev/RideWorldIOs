//
//  RoundedImageView.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 18.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit

@IBDesignable
class RoundedImageView: UIImageView {
    override init(image: UIImage?) {
        super.init(image: image)
        super.layer.cornerRadius = super.frame.size.height / 2
        self.layer.cornerRadius = self.frame.size.height / 2
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        super.layer.cornerRadius = super.frame.size.height / 2
        self.layer.cornerRadius = self.frame.size.height / 2
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        super.layer.cornerRadius = super.frame.size.height / 2
        self.layer.cornerRadius = self.frame.size.height / 2
    }
}

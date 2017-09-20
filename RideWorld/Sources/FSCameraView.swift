//
//  FSCameraView.swift
//  Fusuma
//
//  Created by Yuta Akizuki on 2015/11/14.
//  Copyright © 2015年 ytakzk. All rights reserved.
//

import UIKit
import Stevia

class FSCameraView: UIView, UIGestureRecognizerDelegate {
    
    let previewViewContainer = UIView()
    let buttonsContainer = UIView()
    let flipButton = UIButton()
    let shotButton = UIButton()
    let flashButton = UIButton()
    let timeElapsedLabel = UILabel()
    let progressBar = UIProgressView()

    convenience init() {
        self.init(frame:CGRect.zero)
        
        sv(
            previewViewContainer,
            progressBar,
            timeElapsedLabel,
            flashButton,
            flipButton,
            buttonsContainer.sv(
                shotButton
            )
        )
        
        let isIphone4 = UIScreen.main.bounds.height == 480
        let sideMargin: CGFloat = isIphone4 ? 20 : 0
        
        layout(
            0,
            |-sideMargin-previewViewContainer-sideMargin-|,
            -2,
            |progressBar|,
            0,
            |buttonsContainer|,
            0
        )
        
        previewViewContainer.heightEqualsWidth()
        
        layout(
            15,
            |-(15+sideMargin)-flashButton.size(42)
        )
        
        layout(
            15,
            flipButton.size(42)-(15+sideMargin)-|
        )
        
        addConstraint(item: timeElapsedLabel, attribute: .bottom,
                      toItem: previewViewContainer, constant: -15)
        
        timeElapsedLabel-(15+sideMargin)-|
        
        shotButton.centerVertically()
        shotButton.size(84).centerHorizontally()
        
        backgroundColor = .clear
        previewViewContainer.backgroundColor = .black
        timeElapsedLabel.style { l in
            l.textColor = .white
            l.text = "00:00"
            l.isHidden = true
            l.font = .monospacedDigitSystemFont(ofSize: 13, weight: UIFontWeightMedium)
        }
        progressBar.trackTintColor = .clear
        progressBar.tintColor = .red
        
        let flipImage = imageFromBundle("yp_iconLoop")
        let shotImage = imageFromBundle("yp_iconCapture")
        flashButton.setImage(flashOffImage, for: .normal)
        flipButton.setImage(flipImage, for: .normal)
        shotButton.setImage(shotImage, for: .normal)
    }
}

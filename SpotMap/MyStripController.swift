//
//  MyStripController.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 28.02.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import Foundation

class MyStripController: UIViewController {
    
    var backendless: Backendless!
    
    override func viewDidLoad() {
        //some tests
        self.backendless = Backendless.sharedInstance()
    }
}

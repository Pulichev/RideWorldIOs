//
//  userSpotFile.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 20.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

//BEL - BackEndLess

import Foundation

class SpotPost: NSObject {

    var objectId: String? //this is BEL const
    var created: Date?    //this is BEL const too
    var ownerId: String?

    var spot: SpotDetails?
    var user: Users?

    var postDescription: String?
    var isPhoto: Bool = true //default photo
}

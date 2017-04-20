//
//  EditedUserInfoDelegate.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 20.03.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

// protocol for passing user info and photo
protocol EditedUserInfoDelegate {
   func dataChanged(userInfo: UserItem, profilePhoto: UIImage)
}

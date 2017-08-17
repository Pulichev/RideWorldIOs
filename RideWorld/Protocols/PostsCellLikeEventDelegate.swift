//
//  PostsCellLikeEventDelegate.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 17.08.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

protocol PostsCellLikeEventDelegate: class {
   func postLikeEventFinished(for postId: String) // for updating post cell cache
}

//
//  MainTabBarController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 25.05.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

// customizing height of tab bar
class MainTabBarController: UITabBarController {
   override func viewWillLayoutSubviews() {
      var tabFrame = self.tabBar.frame
      // - 40 is editable , the default value is 49 px, below lowers the tabbar and above increases the tab bar size
      tabFrame.size.height = 40
      tabFrame.origin.y = self.view.frame.size.height - 40
      self.tabBar.frame = tabFrame
   }
}

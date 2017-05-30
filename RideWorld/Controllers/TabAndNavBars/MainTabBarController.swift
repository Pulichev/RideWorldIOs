//
//  MainTabBarController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 25.05.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

// customizing height of tab bar
class MainTabBarController: UITabBarController {
   var delegateFBItemsChanges: FeedbackItemsDelegate?
   
   // MARK: - Add badge to Feedback tab bar item and init FB
   override func viewDidLoad() {
      super.viewDidLoad()
      
      loadFeedbackItems()
   }
   
   // we will send it to FeedbackTab
   var feedbackItems = [FeedbackItem]() {
      didSet {
         addBadgeWithNewFBCount()
         
         if let del = self.delegateFBItemsChanges {
            del.lastUpdate(feedbackItems)
         }
      }
   }
   
   private func loadFeedbackItems() {
      FeedbackItem.getArray() { fbItems in
         self.feedbackItems = fbItems
         
         if let del = self.delegateFBItemsChanges {
            del.lastUpdate(fbItems)
         }
      }
   }
   
   private func addBadgeWithNewFBCount() {
      var countUnViewedFBItems = 0
      
      if feedbackItems.count != 0 {
         for fbItem in feedbackItems {
            if !fbItem.isViewed {
               countUnViewedFBItems += 1
            }
         }
      }
      
      if countUnViewedFBItems != 0 {
         self.tabBar.items![2].badgeValue = String(countUnViewedFBItems)
      } else {
         self.tabBar.items![2].badgeValue = nil
      }
   }
   
   // MARK: - Set height
   override func viewWillLayoutSubviews() {
      var tabFrame = self.tabBar.frame
      // - 40 is editable , the default value is 49 px, below lowers the tabbar and above increases the tab bar size
      tabFrame.size.height = 40
      tabFrame.origin.y = self.view.frame.size.height - 40
      self.tabBar.frame = tabFrame
   }
}

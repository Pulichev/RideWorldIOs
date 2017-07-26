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
      setupMiddleButton()
   }
   
   func setupMiddleButton() {
      let mapBackgroundView = UIViewX(frame: CGRect(x: 0, y: 0, width: 68, height: 68))
      mapBackgroundView.backgroundColor = UIColor.myLightBrown()
      mapBackgroundView.cornerRadius = 34
      
      var mapBackgroundViewFrame = mapBackgroundView.frame
      mapBackgroundViewFrame.origin.y = view.bounds.height - mapBackgroundViewFrame.height
      mapBackgroundViewFrame.origin.x = view.bounds.width/2 - mapBackgroundViewFrame.size.width/2
      mapBackgroundView.frame = mapBackgroundViewFrame
      
      let menuButton = MapButton(frame: CGRect(x: 0, y: 0, width: 68, height: 68))
      menuButton.layer.cornerRadius = mapBackgroundViewFrame.height/2
      mapBackgroundView.addSubview(menuButton)
      view.addSubview(mapBackgroundView)
      
      menuButton.setImage(UIImage(named: "MapIcon"), for: .normal)
      menuButton.tintColor = UIColor.myDarkBlue()
      menuButton.addTarget(self, action: #selector(menuButtonAction(sender:)), for: .touchUpInside)
      
      view.layoutIfNeeded()
   }
   
   @objc private func menuButtonAction(sender: UIButton) {
      selectedIndex = 2
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
      Feedback.getArray() { fbItems in
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
         self.tabBar.items![3].badgeValue = String(countUnViewedFBItems)
      } else {
         self.tabBar.items![3].badgeValue = nil
      }
   }
   
   // MARK: - Set height
   override func viewWillLayoutSubviews() {
      var tabFrame = self.tabBar.frame
      // - 40 is editable , the default value is 49 px, below lowers the tabbar and above increases the tab bar size
      tabFrame.size.height = 43
      tabFrame.origin.y = self.view.frame.size.height - 43
      self.tabBar.frame = tabFrame
   }
}

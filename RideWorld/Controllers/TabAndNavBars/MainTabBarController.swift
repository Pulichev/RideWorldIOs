//
//  MainTabBarController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 25.05.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UserNotifications
import FirebaseInstanceID
import FirebaseMessaging

class MainTabBarController: UITabBarController {
   var delegateFBItemsChanges: FeedbackItemsDelegate?
   
   // MARK: - Add badge to Feedback tab bar item and init FB
   override func viewDidLoad() {
      super.viewDidLoad()
      
      loadFeedbackItems()
      setupMiddleButton()
      requestAndRegisterForNotifications()
   }
   
   // MARK: - middle button part
   var mapBackgroundView: UIViewX!
   var menuButton: MapButton!
   
   func setupMiddleButton() {
      mapBackgroundView = UIViewX(frame: CGRect(x: 0, y: 0, width: 54, height: 54))
      mapBackgroundView.backgroundColor = UIColor.myLightBrown()
      mapBackgroundView.cornerRadius = 27
      
      var mapBackgroundViewFrame = mapBackgroundView.frame
      mapBackgroundViewFrame.origin.y = view.bounds.height - mapBackgroundViewFrame.height
      mapBackgroundViewFrame.origin.x = view.bounds.width / 2 - mapBackgroundViewFrame.size.width / 2
      mapBackgroundView.frame = mapBackgroundViewFrame
      
      menuButton = MapButton(frame: CGRect(x: 0, y: 0, width: 54, height: 54))
      menuButton.layer.cornerRadius = mapBackgroundViewFrame.height / 2
      mapBackgroundView.addSubview(menuButton)
      view.addSubview(mapBackgroundView)
      
      menuButton.setImage(UIImage(named: "MapIcon"), for: .normal)
      menuButton.tintColor = UIColor.myDarkBlue()
      menuButton.addTarget(self, action: #selector(menuButtonAction(sender:)), for: .touchUpInside)
      
      view.layoutIfNeeded()
   }
   
   func showMapButton() {
      tabBar.isHidden            = false
      mapBackgroundView.isHidden = false
      menuButton.isHidden        = false
      menuButton.isEnabled       = true
   }
   
   func hideMapButton() {
      tabBar.isHidden            = true
      mapBackgroundView.isHidden = true
      menuButton.isHidden        = true
      menuButton.isEnabled       = false
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

extension MainTabBarController: UNUserNotificationCenterDelegate {
   func requestAndRegisterForNotifications() {
      let application = UIApplication.shared
      
      if #available(iOS 10.0, *) {
         // For iOS 10 display notification (sent via APNS)
         UNUserNotificationCenter.current().delegate = self
         let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
         UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in })
         // For iOS 10 data message (sent via FCM
         Messaging.messaging().delegate = self
      } else {
         let settings: UIUserNotificationSettings =
            UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
         application.registerUserNotificationSettings(settings)
      }
      
      application.registerForRemoteNotifications()
      
      print("FCM TOKEN:" + Messaging.messaging().fcmToken!)
   }
}

extension MainTabBarController: MessagingDelegate {
   // The callback to handle data message received via FCM for devices running iOS 10 or above.
   func application(received remoteMessage: MessagingRemoteMessage) {
      print(remoteMessage.appData)
   }
   
   // [START refresh_token]
   func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
      print("Firebase registration token: \(fcmToken)")
   }
   // [END refresh_token]
   // [START ios_10_data_message]
   // Receive data messages on iOS 10+ directly from FCM (bypassing APNs) when the app is in the foreground.
   // To enable direct data messages, you can set Messaging.messaging().shouldEstablishDirectChannel to true.
   func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
      print("Received data message: \(remoteMessage.appData)")
   }
   // [END ios_10_data_message]
}

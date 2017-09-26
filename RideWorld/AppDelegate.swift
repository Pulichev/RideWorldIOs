//
//  AppDelegate.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 17.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit

import Firebase
import FirebaseDatabase
import FirebaseAuth

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
   var window: UIWindow?
   
   var storyboard: UIStoryboard?
   
   func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
      // FireBase init part
      FirebaseApp.configure()
      Database.database().isPersistenceEnabled = false
      // TIP: Notifications delegates are in MainTabBarController
      
      self.storyboard = UIStoryboard(name: "Authorization", bundle: Bundle.main)
      // Setting initial viewController for user loggedIn?
      if(Auth.auth().currentUser != nil) {
         self.window?.rootViewController = self.storyboard?.instantiateViewController(withIdentifier: "MainTabBarController")
      } else {
         self.window?.rootViewController = self.storyboard?.instantiateViewController(withIdentifier: "LoginPage")
      }
      
      // set some colors
      customizeAppearance()
      
      return true
   }
   
   func customizeAppearance() {
      UISearchBar.appearance().barTintColor = UIColor.myBlack()
      UISearchBar.appearance().tintColor = UIColor.myLightBrown()
      UINavigationBar.appearance().barTintColor = UIColor.myBlack()
      UINavigationBar.appearance().tintColor = UIColor.myLightBrown()
      UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.myLightBrown(),
                                                          NSAttributedStringKey.font : UIFont(name: "PTSans-Bold", size: 20)]
      UITabBar.appearance().barTintColor = UIColor.myBlack()
      UITabBar.appearance().tintColor = UIColor.myLightBrown()
      UILabel.appearance().defaultFont =  UIFont(name: "PT Sans", size: 15.0)
      UILabel.appearance(whenContainedInInstancesOf: [UIButton.self]).defaultFont = UIFont(name: "PT Sans", size: 15.0)
   }
   
   func applicationWillResignActive(_ application: UIApplication) {
      // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
      // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
   }
   
   func applicationDidEnterBackground(_ application: UIApplication) {
      // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
      // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
      window?.endEditing(true)
   }
   
   func applicationWillEnterForeground(_ application: UIApplication) {
      // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
   }
   
   func applicationDidBecomeActive(_ application: UIApplication) {
      // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
   }
   
   func applicationWillTerminate(_ application: UIApplication) {
      // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
   }
   
   func applicationDidFinishLaunching(_ application: UIApplication) {
      
   }
}

// MARK: - Settings for entire application
extension UIColor {
   
   // new colors
   static func myBlack() -> UIColor {
      return #colorLiteral(red: 0.1765, green: 0.1765, blue: 0.1608, alpha: 1) /* #2d2d29 */
   }
   
   static func myDarkGray() -> UIColor {
      return #colorLiteral(red: 0.4902, green: 0.549, blue: 0.5725, alpha: 1) /* #7d8c92 */
   }
   
   static func myLightGray() -> UIColor {
      return #colorLiteral(red: 0.7137, green: 0.7451, blue: 0.7451, alpha: 1) /* #b6bebe */
   }
   
   static func myLightBrown() -> UIColor {
      return #colorLiteral(red: 0.9176, green: 0.8824, blue: 0.8431, alpha: 1) /* #eae1d7 */
   }
   
   static func tabBarButtonActive() -> UIColor {
      return #colorLiteral(red: 0.9137, green: 0.8824, blue: 0.8471, alpha: 1) /* #e9e1d8 */
   }
   
   static func tabBarButtonInActive() -> UIColor {
      return #colorLiteral(red: 0.5725, green: 0.5725, blue: 0.5725, alpha: 1) /* #929292 */
   }
}

extension UILabel {
   
   @objc dynamic var defaultFont: UIFont? {
      get { return self.font }
      set {
         //get old size of lable font
         let sizeOfOldFont = self.font.pointSize
         //get new name of font
         let fontNameOfNewFont = newValue?.fontName
         self.font = UIFont(name: fontNameOfNewFont!, size: sizeOfOldFont)
      }
   }
}

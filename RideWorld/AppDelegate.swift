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
      
      self.storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
      
      // Setting initial viewController for user loggedIn?
      if(Auth.auth().currentUser != nil) {
         self.window?.rootViewController = self.storyboard?.instantiateViewController(withIdentifier: "MainTabBarController")
      } else {
         self.window?.rootViewController = self.storyboard?.instantiateViewController(withIdentifier: "LoginPage")
      }
      
      // set some colors
      UISearchBar.appearance().barTintColor = UIColor.myLightBrown()
      UISearchBar.appearance().tintColor = UIColor.myDarkBlue()
      UINavigationBar.appearance().barTintColor = UIColor.myLightBrown()
      UINavigationBar.appearance().tintColor = UIColor.myDarkBlue()
      UITabBar.appearance().barTintColor = UIColor.myLightBrown()
      UITabBar.appearance().tintColor = UIColor.myDarkBlue()
      
      return true
   }
   
   func applicationWillResignActive(_ application: UIApplication) {
      // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
      // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
   }
   
   func applicationDidEnterBackground(_ application: UIApplication) {
      // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
      // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
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

extension UIColor {
   // old colors
   static func myGray() -> UIColor {
      return #colorLiteral(red: 0.3804, green: 0.3804, blue: 0.3804, alpha: 1) /* #616161 */
   }
   
   static func myGreen() -> UIColor {
      return #colorLiteral(red: 0.5843, green: 0.7373, blue: 0.6353, alpha: 1) /* #95bca2 */
   }
   
   // new colors
   static func myDarkBlue() -> UIColor {
      return #colorLiteral(red: 0.149, green: 0.2275, blue: 0.2824, alpha: 1) /* #263a48 */
   }
   
   static func myDarkGray() -> UIColor {
      return #colorLiteral(red: 0.4902, green: 0.549, blue: 0.5725, alpha: 1) /* #7d8c92 */
   }
   
   static func myLightGray() -> UIColor {
      return #colorLiteral(red: 0.7137, green: 0.7451, blue: 0.7451, alpha: 1) /* #b6bebe */
   }
   
   static func myLighterBrown() -> UIColor {
      return #colorLiteral(red: 0.8, green: 0.7804, blue: 0.7294, alpha: 1) /* #ccc7ba */
   }
   
   static func myLightBrown() -> UIColor {
      return #colorLiteral(red: 0.9294, green: 0.8431, blue: 0.7412, alpha: 1) /* #edd7bd */
   }
}

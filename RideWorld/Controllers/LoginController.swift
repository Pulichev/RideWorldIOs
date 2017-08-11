//
//  LoginController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 27.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import FirebaseAuth
import SVProgressHUD

class LoginController: UIViewController, UITextFieldDelegate {
   @IBOutlet weak var userLogin: UITextField!
   @IBOutlet weak var userPassword: UITextField!
   
   override func viewDidLoad() {
      
      userLogin.delegate = self
      userPassword.delegate = self
      
      //For scrolling the view if keyboard on
      NotificationCenter.default.addObserver(
         self, selector: #selector(LoginController.keyboardWillShow),
         name: NSNotification.Name.UIKeyboardWillShow, object: nil)
      
      NotificationCenter.default.addObserver(
         self, selector: #selector(LoginController.keyboardWillHide),
         name: NSNotification.Name.UIKeyboardWillHide, object: nil)
      
      super.viewDidLoad()
   }
   
   @IBAction func loginButtonTapped(_ sender: Any) {
      SVProgressHUD.show()
      
      // catching user email for login
      UserModel.getItemByLogin(for: userLogin.text!) { userItem in
         if userItem != nil {
            self.signIn(with: userItem!.email)
         } else {
            self.showAlertWithError(text: "Wrong login or password!")
         }
      }
   }
   
   private func signIn(with email: String) {
      Auth.auth().signIn(withEmail: email,
                             password: userPassword.text!)
      { user, error in
         
         SVProgressHUD.dismiss()
         
         if error != nil {
            self.showAlertWithError(text: "Wrong login or password!")
            print("\(String(describing: error?.localizedDescription))")
         } else {
            self.performSegue(withIdentifier: "fromLoggedInToTabBar", sender: self)
         }
      }
   }
   
   @IBAction func registrationButtonTapped(_ sender: Any) {
      performSegue(withIdentifier: "registration", sender: self)
   }
   
   private func showAlertWithError(text: String) {
      SVProgressHUD.dismiss()
      
      let alert = UIAlertController(title: "Login failed!",
                                    message: text,
                                    preferredStyle: .alert)
      
      alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
      
      present(alert, animated: true, completion: nil)
   }
   
   var keyBoardAlreadyShowed = false //using this to not let app to scroll view
   //if we tapped UITextField and then another UITextField
}

// MARK: - Navigation bar show/hide
extension LoginController {
   override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      
      // Hide the navigation bar on the this view controller
      navigationController?.setNavigationBarHidden(true, animated: animated)
   }
   
   override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
      
      // Show the navigation bar on other view controllers
      navigationController?.setNavigationBarHidden(false, animated: animated)
   }
}

// MARK: - Scroll view on keyboard show/hide
extension LoginController {
   func keyboardWillShow(notification: NSNotification) {
      if !keyBoardAlreadyShowed {
         view.frame.origin.y -= 50
         keyBoardAlreadyShowed = true
      }
   }
   
   func keyboardWillHide(notification: NSNotification) {
      view.frame.origin.y += 50
      keyBoardAlreadyShowed = false
   }
   
   override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
      view.endEditing(true)
   }
}

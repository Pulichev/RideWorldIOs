//
//  RegistrationController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 27.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseAuth
import SVProgressHUD

class RegistrationController: UIViewController {
   @IBOutlet weak var userEmail: UITextField!
   @IBOutlet weak var userLogin: UITextField!
   @IBOutlet weak var userPassword: UITextField!
   
   override func viewDidLoad() {
      //For scrolling the view if keyboard on
      NotificationCenter.default.addObserver(self, selector: #selector(RegistrationController.keyboardWillShow),
                                             name: NSNotification.Name.UIKeyboardWillShow, object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(RegistrationController.keyboardWillHide),
                                             name: NSNotification.Name.UIKeyboardWillHide, object: nil)
      
      super.viewDidLoad()
   }
   
   override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
   }
   
   @IBAction func signUpButtonTapped(_ sender: Any) {
      SVProgressHUD.show()
      
      UserModel.getItemByLogin(for: userLogin.text!) { userItem in
         if userItem == nil {
            self.createAndLogin()
         } else {
            self.showAlertThatLoginAlreadyExists()
         }
      }
   }
   
   private func createAndLogin() {
      Auth.auth().createUser(withEmail: userEmail.text!,
                                 password: userPassword.text!)
      { user, error in
         if error == nil {
            // log in
            Auth.auth().signIn(withEmail: self.userEmail.text!,
                                   password: self.userPassword.text!)
            { result in
               // create new user in database, not in FIRAuth
               UserModel.create(with: self.userLogin.text!) { _ in
                  SVProgressHUD.dismiss()
                  
                  self.performSegue(withIdentifier: "fromRegistrationToTabBar", sender: self)
               }
            }
         } else {
            SVProgressHUD.dismiss()

            print("\(String(describing: error?.localizedDescription))")
         }
      }
   }
   
   private func showAlertThatLoginAlreadyExists() {
      SVProgressHUD.dismiss()

      let alert = UIAlertController(title: "Registration failed!",
                                    message: "Login already exists.",
                                    preferredStyle: .alert)
      
      alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
      
      present(alert, animated: true, completion: nil)
   }
   
   var keyBoardAlreadyShowed = false //using this to not let app to scroll view
   //if we tapped UITextField and then another UITextField
}

// MARK: - Scroll view on keyboard show/hide
extension RegistrationController {
   func keyboardWillShow(notification: NSNotification) {
      if !keyBoardAlreadyShowed {
         view.frame.origin.y -= 150
         keyBoardAlreadyShowed = true
      }
   }
   
   func keyboardWillHide(notification: NSNotification) {
      view.frame.origin.y += 150
      keyBoardAlreadyShowed = false
   }
   
   override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
      view.endEditing(true)
   }
}

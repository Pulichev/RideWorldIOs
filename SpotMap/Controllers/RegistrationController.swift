//
//  RegistrationController.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 27.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseAuth

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
      FIRAuth.auth()!.createUser(withEmail: userEmail.text!,
                                 password: userPassword.text!) { user, error in
                                    if error == nil {
                                       // log in
                                       FIRAuth.auth()!.signIn(withEmail: self.userEmail.text!,
                                                              password: self.userPassword.text!,
                                                              completion: { result in
                                                               // create new user in database, not in FIRAuth
                                                               User.create(with: self.userLogin.text!)
                                                               
                                                               self.performSegue(withIdentifier: "fromRegistrationToTabBar", sender: self)
                                       })
                                    } else {
                                       print("\(String(describing: error?.localizedDescription))")
                                    }
      }
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

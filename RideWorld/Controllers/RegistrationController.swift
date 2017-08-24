//
//  RegistrationController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 27.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseAuth
import SVProgressHUD
import ActiveLabel

class RegistrationController: UIViewController {
   
   @IBOutlet weak var userEmail: UITextField!
   @IBOutlet weak var userLogin: UITextField!
   @IBOutlet weak var userPassword: UITextField!
   @IBOutlet weak var agreements: ActiveLabel!
   
   override func viewDidLoad() {
      super.viewDidLoad()
      //For scrolling the view if keyboard on
      NotificationCenter.default.addObserver(self,
                                             selector: #selector(RegistrationController.keyboardWillShow),
                                             name: NSNotification.Name.UIKeyboardWillShow,
                                             object: nil)
      NotificationCenter.default.addObserver(self,
                                             selector: #selector(RegistrationController.keyboardWillHide),
                                             name: NSNotification.Name.UIKeyboardWillHide,
                                             object: nil)
      
      setAgreenentsTextAndCustomize()
   }
   
   private func setAgreenentsTextAndCustomize() {
      agreements.text = NSLocalizedString("RegLinkToTerms", comment: "")
      customizeDescUserLogin()
   }
   
   private func customizeDescUserLogin() {
      agreements.customize { agreements in
         let ToUTappedType = ActiveType.custom(pattern: "\(NSLocalizedString("RegToU", comment: ""))")
         agreements.enabledTypes.append(ToUTappedType)
         agreements.handleCustomTap(for: ToUTappedType) { _ in
            self.goToTermsOfUse()
         }
         
         let PPTappedType = ActiveType.custom(pattern: "\(NSLocalizedString("RegPP", comment: ""))")
         agreements.enabledTypes.append(PPTappedType)
         agreements.handleCustomTap(for: PPTappedType) { _ in
            self.goToPrivacyPolicy()
         }
         
         agreements.customColor[ToUTappedType] = UIColor.myLightBrown()
         agreements.customColor[PPTappedType]  = UIColor.myLightBrown()
      }
   }
   
   // MARK: - links to textView
   var fileNameToOpen: String!
   
   func goToTermsOfUse() {
      fileNameToOpen = "ToU"
      performSegue(withIdentifier: "fromRegToText", sender: self)
   }
   
   func goToPrivacyPolicy() {
      fileNameToOpen = "PP"
      performSegue(withIdentifier: "fromRegToText", sender: self)
   }
   
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      switch segue.identifier! {
      case "fromRegToText":
         let newTextViewController = segue.destination as! TextViewController
         newTextViewController.fileNameString = fileNameToOpen
         break
         
      default:
         break
      }
   }
   
   
   @IBAction func signUpButtonTapped(_ sender: Any) {
      SVProgressHUD.show()
      
      UserModel.getItemByLogin(for: userLogin.text!) { userItem, error in
         if userItem == nil {
            self.createAndLogin()
         } else {
            self.showAlertThatLoginAlreadyExists()
         }
      }
   }
   
   private func createAndLogin() {
      if isLoginSatisfiesRegEx(userLogin.text!) {
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
               let errorText = String(describing: error!.localizedDescription)
               
               self.showAlertWithError(text: errorText)
            }
         }
      } else {
         showAlertWithError(text: NSLocalizedString("Wrong login! You can use only english letters, numbers and ._-. The maximum length is 30 characters.", comment: ""))
      }
   }
   
   private func isLoginSatisfiesRegEx(_ login: String) -> Bool {
      if login.range(of: "^[a-zA-Z0-9._-]{1,30}$", options: .regularExpression) != nil {
         return true
      } else {
         return false
      }
   }
   
   private func showAlertWithError(text: String) {
      SVProgressHUD.dismiss()
      
      let alert = UIAlertController(title: NSLocalizedString("Registration failed!", comment: ""),
                                    message: text,
                                    preferredStyle: .alert)
      
      alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
      
      present(alert, animated: true, completion: nil)
   }
   
   private func showAlertThatLoginAlreadyExists() {
      SVProgressHUD.dismiss()
      
      let alert = UIAlertController(title: NSLocalizedString("Registration failed!", comment: ""),
                                    message: NSLocalizedString("Login already exists.", comment: ""),
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
      if keyBoardAlreadyShowed {
         view.frame.origin.y += 150
         keyBoardAlreadyShowed = false
      }
   }
   
   override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
      view.endEditing(true)
   }
}

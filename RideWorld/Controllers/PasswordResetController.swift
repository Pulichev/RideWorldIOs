//
//  PasswordResetController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 11.08.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import FirebaseAuth
import SVProgressHUD

class PasswordResetController: UIViewController {
   
   @IBOutlet weak var userEmail: UITextFieldX!
   
   override func viewDidLoad() {
      super.viewDidLoad()
   }
   
   @IBAction func sendEmailButtonTapped(_ sender: UIButtonX) {
      SVProgressHUD.show()
      Auth.auth().sendPasswordReset(withEmail: userEmail.text!) { error in
         SVProgressHUD.dismiss()
         if error != nil {
            self.showAlertWithError(text: error!.localizedDescription)
         } else {
            self.showAlertThatEmailWasSent()
         }
      }
   }
   
   private func showAlertWithError(text: String) {
      let alert = UIAlertController(title: NSLocalizedString("Sending E-Mail failed!", comment: ""),
                                    message: text,
                                    preferredStyle: .alert)
      
      alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
      
      present(alert, animated: true, completion: nil)
   }
   
   private func showAlertThatEmailWasSent() {
      let alert = UIAlertController(title: NSLocalizedString("Success!", comment: ""),
                                    message: NSLocalizedString("E-Mail was sent on ", comment: "") + "\(userEmail.text!)",
                                    preferredStyle: .alert)
      
      alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
         _ = self.navigationController?.popViewController(animated: true) // go back
      }))
      
      present(alert, animated: true, completion: nil)
   }
}

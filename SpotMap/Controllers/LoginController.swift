//
//  LoginController.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 27.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import Foundation
import UIKit

class LoginController: UIViewController, UITextFieldDelegate
{
    @IBOutlet weak var userLogin: UITextField!
    @IBOutlet weak var userPassword: UITextField!
    
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad()
    {
        errorLabel.text = "" //Make no errors
        
        self.userLogin.delegate = self
        self.userPassword.delegate = self
        
        //For scrolling the view if keyboard on
        NotificationCenter.default.addObserver(self, selector: #selector(LoginController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LoginController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        super.viewDidLoad()
    }
    
    @IBAction func loginButtonTapped(_ sender: Any)
    {
        let backendless = Backendless.sharedInstance()
        
        backendless?.userService.login(userLogin.text, password:userPassword.text,
            response: { ( user : BackendlessUser?) -> Void in
                let defaults = UserDefaults.standard
                defaults.set(self.userLogin.text, forKey: "userLoggedIn")
                defaults.set(user?.objectId, forKey: "userLoggedInObjectId")
                defaults.set(user?.name, forKey: "userLoggedInNickName")
                defaults.synchronize()
                
                self.performSegue(withIdentifier: "loggedIn", sender: self)
        },
            error: { ( fault : Fault?) -> Void in
                self.errorLabel.text = "Wrong login or password!"
        })
    }
    
    @IBAction func registrationButtonTapped(_ sender: Any)
    {
        self.performSegue(withIdentifier: "registration", sender: self)
    }
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    //Start value of constraint
    var bottomConstraintValue: CGFloat = 174.0
    
    //Function of changing bottom constraint
    func adjustingHeight(show:Bool, notification:NSNotification) {
        
        var userInfo = notification.userInfo!
        let keyboardFrame:CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        if show == true {
            if bottomConstraintValue == 174.0 {
                bottomConstraintValue = (keyboardFrame.height + 40.0)
            }
        } else {
            bottomConstraintValue = 174.0
        }
        
        UIView.animate(withDuration: 5.0, animations: { () -> Void in
            self.bottomConstraint.constant = self.bottomConstraintValue
        })
    }
    
    func keyboardWillShow(notification:NSNotification) {
        adjustingHeight(show: true, notification: notification)
    }
    
    func keyboardWillHide(notification:NSNotification) {
        adjustingHeight(show: false, notification: notification)
    }
    
    //This is for the keyboard to GO AWAYY !! when user clicks anywhere on the view
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

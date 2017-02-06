//
//  RegistrationController.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 27.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import Foundation

class RegistrationController: UIViewController
{
    var backendless: Backendless!
    
    @IBOutlet weak var userEmail: UITextField!
    @IBOutlet weak var userLogin: UITextField!
    @IBOutlet weak var userPassword: UITextField!
    
    override func viewDidLoad()
    {
        //For scrolling the view if keyboard on
        NotificationCenter.default.addObserver(self, selector: #selector(RegistrationController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(RegistrationController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    //Start value of constraint
    var bottomConstraintValue: CGFloat = 40.0
    
    //Function of changing bottom constraint
    func adjustingHeight(show:Bool, notification:NSNotification) {
        
        var userInfo = notification.userInfo!
        let keyboardFrame:CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        if show == true {
            if bottomConstraintValue == 40.0 {
                bottomConstraintValue = (keyboardFrame.height + 40.0)
            }
        } else {
            bottomConstraintValue = 40.0
        }
        
        UIView.animate(withDuration: 1.5, animations: { () -> Void in
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
    
    @IBAction func signUpButtonTapped(_ sender: Any)
    {
        let backendless = Backendless.sharedInstance()
        let user: BackendlessUser = BackendlessUser()
        user.email = userEmail.text as NSString!
        user.password = userPassword.text as NSString!
        user.name = userLogin.text as NSString!
        var userId = backendless?.userService.registering(user)

        let defaults = UserDefaults.standard
        defaults.set(self.userEmail.text, forKey: "userLoggedIn")
        defaults.set(userId, forKey: "userLoggedInObjectId")
        defaults.set(user.name, forKey: "userLoggedInNickName")
        defaults.synchronize()
        
        self.performSegue(withIdentifier: "registrationCompleted", sender: self)
    }
}

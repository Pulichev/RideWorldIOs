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
    
    @IBAction func signUpButtonTapped(_ sender: Any)
    {
        let backendless = Backendless.sharedInstance()
        let user: BackendlessUser = BackendlessUser()
        user.email = userEmail.text as NSString!
        user.password = userPassword.text as NSString!
        user.name = userLogin.text as NSString!
        let addedUser = backendless?.userService.registering(user)
        
        let defaults = UserDefaults.standard
        defaults.set(self.userEmail.text, forKey: "userLoggedIn")
        defaults.set(addedUser?.objectId, forKey: "userLoggedInObjectId")
        defaults.set(user.name, forKey: "userLoggedInNickName")
        defaults.synchronize()
        
        self.performSegue(withIdentifier: "registrationCompleted", sender: self)
    }
    
    var keyBoardAlreadyShowed = false //using this to not let app to scroll view
                                      //if we tapped UITextField and then another UITextField
    func keyboardWillShow(notification: NSNotification) {
        if !keyBoardAlreadyShowed {
            self.view.frame.origin.y -= 150
            keyBoardAlreadyShowed = true
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        self.view.frame.origin.y += 150
        keyBoardAlreadyShowed = false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

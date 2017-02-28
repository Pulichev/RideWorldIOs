//
//  RegistrationController.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 27.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import Foundation

class RegistrationController: UIViewController {

    var backendless: Backendless!

    @IBOutlet weak var userEmail: UITextField!
    @IBOutlet weak var userLogin: UITextField!
    @IBOutlet weak var userPassword: UITextField!

    override func viewDidLoad() {
        //For scrolling the view if keyboard on
        NotificationCenter.default.addObserver(self, selector: #selector(RegistrationController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(RegistrationController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func signUpButtonTapped(_ sender: Any) {
        backendless = Backendless.sharedInstance()
        
        let user: BackendlessUser = BackendlessUser()
        user.email = userEmail.text as NSString!
        user.password = userPassword.text as NSString!
        user.name = userLogin.text as NSString!
        _ = backendless?.userService.registering(user)

        logInAfterRegistration(name: userLogin.text!, password: userPassword.text!)
    }
    
    func logInAfterRegistration(name: String, password: String) {
        backendless?.userService.login(
            userLogin.text, password: userPassword.text, response: {
                (user : BackendlessUser?) -> Void in
                
                self.backendless?.userService.setStayLoggedIn(true) //new we can use backendless.userService.currentUser throught all app
                
                self.performSegue(withIdentifier: "registrationCompleted", sender: self)
        },
            error: { ( _) -> Void in
                //here we can do smth
        })
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

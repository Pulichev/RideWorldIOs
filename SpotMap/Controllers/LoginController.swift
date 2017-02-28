//
//  LoginController.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 27.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import Foundation
import UIKit

class LoginController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var userLogin: UITextField!
    @IBOutlet weak var userPassword: UITextField!

    @IBOutlet weak var errorLabel: UILabel!

    override func viewDidLoad() {
        errorLabel.text = "" //Make no errors

        self.userLogin.delegate = self
        self.userPassword.delegate = self

        //For scrolling the view if keyboard on
        NotificationCenter.default.addObserver(self, selector: #selector(LoginController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LoginController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

        super.viewDidLoad()
    }
    
    //part for hide and view navbar from this navigation controller
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide the navigation bar on the this view controller
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show the navigation bar on other view controllers
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    @IBAction func loginButtonTapped(_ sender: Any) {
        let backendless = Backendless.sharedInstance()

        backendless?.userService.login(
            userLogin.text, password:userPassword.text, response: {
                (user : BackendlessUser?) -> Void in
                
                backendless?.userService.setStayLoggedIn(true) //new we can use backendless.userService.currentUser throught all app

                self.performSegue(withIdentifier: "loggedIn", sender: self)
        },
            error: { ( _) -> Void in
                self.errorLabel.text = "Wrong login or password!"
        })
    }

    @IBAction func registrationButtonTapped(_ sender: Any) {
        self.performSegue(withIdentifier: "registration", sender: self)
    }

    var keyBoardAlreadyShowed = false //using this to not let app to scroll view
    //if we tapped UITextField and then another UITextField
    func keyboardWillShow(notification: NSNotification) {
        if !keyBoardAlreadyShowed {
            self.view.frame.origin.y -= 50
            keyBoardAlreadyShowed = true
        }
    }

    func keyboardWillHide(notification: NSNotification) {
        self.view.frame.origin.y += 50
        keyBoardAlreadyShowed = false
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

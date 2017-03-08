//
//  RegistrationController.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 27.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase

class RegistrationController: UIViewController {
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
        FIRAuth.auth()!.createUser(withEmail: userEmail.text!,
                                   password: userPassword.text!) { user, error in
                                    if error == nil {
                                        FIRAuth.auth()!.signIn(withEmail: self.userEmail.text!,
                                                               password: self.userPassword.text!)
                                        
                                        let loggedInUser = FIRAuth.auth()?.currentUser
                                        let currentDate = Date()
                                        let newUser = UserItem(uid: ((loggedInUser)?.uid)!, email: ((loggedInUser)?.email!)!,
                                                               login: self.userLogin.text!, createdDate: String(describing: currentDate))
                                        
                                        // Create a child path with a key set to the uid underneath the "users" node
                                        let ref = FIRDatabase.database().reference(withPath: "MainDataBase")
                                        ref.child("users").child(((loggedInUser)?.uid)!).setValue(newUser.toAnyObject())
                                        
                                        self.performSegue(withIdentifier: "registrationCompleted", sender: self)
                                    } else {
                                        print("\(error?.localizedDescription)")
                                    }
        }
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

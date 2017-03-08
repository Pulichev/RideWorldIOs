//
//  EditProfileController.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 26.02.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import Foundation
import UIKit

class EditProfileController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var userInfo: UserItem!
    
    var backendless: Backendless!
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var userPhoto: UIImageView!
    
    var userPhotoTemp = UIImage()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(LoginController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LoginController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        self.userPhoto.image = userPhotoTemp
        self.userPhoto.layer.cornerRadius = self.userPhoto.frame.size.height / 2
        
        self.backendless = Backendless.sharedInstance()
    }
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        
    }
    
    @IBAction func changeProfilePhotoButtonTapped(_ sender: Any) {
        
    }
    
    //Main table filling region
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EditProfileCell", for: indexPath) as! EditProfileCell
        let row = indexPath.row
        
        let leftImageView = UIImageView()
        let leftView = UIView()
        leftView.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        leftImageView.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        
        cell.field.leftViewMode = .always
        
        switch row {
        case 0:
            cell.field.text = userInfo.userNameAndSename
            cell.field.placeholder = "Enter new name and sename"
            leftImageView.image = UIImage(named: "nameAndSename.png")
            leftView.addSubview(leftImageView)
            cell.field.leftView = leftView
            break
            
        case 1:
            cell.field.text = userInfo.userBioDescription
            cell.field.placeholder = "Enter new bio description"
            leftImageView.image = UIImage(named: "biography.png")
            leftView.addSubview(leftImageView)
            cell.field.leftView = leftView
            break
            
        case 2:
            cell.field.text = userInfo.name
            cell.field.placeholder = "Enter new login"
            leftImageView.image = UIImage(named: "login.png")
            leftView.addSubview(leftImageView)
            cell.field.leftView = leftView
            break
            
        case 3:
            cell.field.text = userInfo.email
            cell.field.placeholder = "Enter new email"
            leftImageView.image = UIImage(named: "email.ico")
            leftView.addSubview(leftImageView)
            cell.field.leftView = leftView
            break
            
        default:
            break
        }
        
        return cell
    }
    
    var keyBoardAlreadyShowed = false //using this to not let app to scroll view
    //if we tapped UITextField and then another UITextField
}

extension EditProfileController {
    func keyboardWillShow(notification: NSNotification) {
        if !keyBoardAlreadyShowed {
            self.view.frame.origin.y -= 100
            keyBoardAlreadyShowed = true
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        self.view.frame.origin.y += 100
        keyBoardAlreadyShowed = false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

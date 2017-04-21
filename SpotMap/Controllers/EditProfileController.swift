//
//  EditProfileController.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 26.02.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import Fusuma

class EditProfileController: UIViewController, UITableViewDataSource, UITableViewDelegate {
   var delegate: EditedUserInfoDelegate?
   
   var userInfo: UserItem!
   
   @IBOutlet var tableView: UITableView!
   @IBOutlet var userPhoto: RoundedImageView!
   
   var userPhotoTemp = UIImage()
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      NotificationCenter.default.addObserver(self, selector: #selector(LoginController.keyboardWillShow),
                                             name: NSNotification.Name.UIKeyboardWillShow, object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(LoginController.keyboardWillHide),
                                             name: NSNotification.Name.UIKeyboardWillHide, object: nil)
      
      userPhoto.image = userPhotoTemp
      
      tableView.tableFooterView = UIView(frame: .zero) // deleting empty rows
   }
   
   private func getCellFieldText(_ row: Int) -> String {
      return (tableView.cellForRow(at: IndexPath(row: row, section: 0)) as! EditProfileCell).field.text!
   }
   
   @IBAction func saveButtonTapped(_ sender: Any) {
      let nameAndSename  = getCellFieldText(0)
      let bioDescription = getCellFieldText(1)
      let login          = getCellFieldText(2)
      // updating values
      User.updateUserInfo(for: userInfo.uid, bioDescription, login, nameAndSename)
      
      uploadPhoto()
      
      returnToParentControllerOnSaveButtonTapped(bioDescription: bioDescription,
                                                      login: login, nameAndSename: nameAndSename)
   }
   
   func uploadPhoto() {
      UserMedia.upload(for: userInfo.uid,
                       with: userPhoto.image!, withSize: 150.0)
      UserMedia.upload(for: userInfo.uid,
                       with: userPhoto.image!, withSize: 90.0)
   }
   
   func returnToParentControllerOnSaveButtonTapped(bioDescription: String, login: String, nameAndSename: String) {
      // change current user info and pass it and photo to user profile controller
      userInfo.bioDescription = bioDescription
      userInfo.login = login
      userInfo.nameAndSename = nameAndSename
      
      if let del = delegate {
         del.dataChanged(userInfo: userInfo, profilePhoto: userPhoto.image!)
      }
      
      // return to profile
      _ = navigationController?.popViewController(animated: true)
   }
   
   //MARK: - User settings table
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
         cell.field.text = userInfo.nameAndSename
         cell.field.placeholder = "Enter new name and sename"
         leftImageView.image = UIImage(named: "nameAndSename.png")
         leftView.addSubview(leftImageView)
         cell.field.leftView = leftView
         break
         
      case 1:
         cell.field.text = userInfo.bioDescription
         cell.field.placeholder = "Enter new bio description"
         leftImageView.image = UIImage(named: "biography.png")
         leftView.addSubview(leftImageView)
         cell.field.leftView = leftView
         break
         
      case 2:
         cell.field.text = userInfo.login
         cell.field.placeholder = "Enter new nickname"
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
         cell.field.isEnabled = false
         break
         
      default:
         break
      }
      
      return cell
   }
   
   var keyBoardAlreadyShowed = false //using this to not let app to scroll view
   //if we tapped UITextField and then another UITextField
}

//MARK: - Fusuma
extension EditProfileController: FusumaDelegate {
   @IBAction func changeProfilePhotoButtonTapped(_ sender: Any) {
      let fusuma = FusumaViewController()
      fusuma.delegate = self
      fusuma.hasVideo = false // If you want to let the users allow to use video.
      present(fusuma, animated: true, completion: nil)
   }
   
   // MARK: FusumaDelegate Protocol
   func fusumaImageSelected(_ image: UIImage, source: FusumaMode) {
      switch source {
      case .camera:
         print("Image captured from Camera")
      case .library:
         print("Image selected from Camera Roll")
      default:
         print("Image selected")
      }
      
      userPhoto.image = image
      userPhoto.layer.cornerRadius = userPhoto.frame.size.height / 2
      userPhoto.layer.masksToBounds = true
      userPhoto.layer.borderWidth = 0
   }
   
   func fusumaImageSelected(_ image: UIImage) {
      //look example on https://github.com/ytakzk/Fusuma
   }
   
   func fusumaVideoCompleted(withFileURL fileURL: URL) {
      //If u want to use video in future - add code here. You can watch code in NewPostController.swift
   }
   
   func fusumaDismissedWithImage(_ image: UIImage, source: FusumaMode) {
      switch source {
      case .camera:
         print("Called just after dismissed FusumaViewController using Camera")
      case .library:
         print("Called just after dismissed FusumaViewController using Camera Roll")
      default:
         print("Called just after dismissed FusumaViewController")
      }
   }
   
   func fusumaCameraRollUnauthorized() {
      
      print("Camera roll unauthorized")
      
      let alert = UIAlertController(title: "Access Requested", message: "Saving image needs to access your photo album", preferredStyle: .alert)
      
      alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { (action) -> Void in
         
         if let url = URL(string:UIApplicationOpenSettingsURLString) {
            UIApplication.shared.openURL(url)
         }
         
      }))
      
      alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
         
      }))
      
      present(alert, animated: true, completion: nil)
   }
   
   func fusumaClosed() {
      print("Called when the FusumaViewController disappeared")
   }
   
   func fusumaWillClosed() {
      print("Called when the close button is pressed")
   }
}

// MARK: - Scroll for keyboard show/hide
extension EditProfileController {
   func keyboardWillShow(notification: NSNotification) {
      if !keyBoardAlreadyShowed {
         view.frame.origin.y -= 100
         keyBoardAlreadyShowed = true
      }
   }
   
   func keyboardWillHide(notification: NSNotification) {
      view.frame.origin.y += 100
      keyBoardAlreadyShowed = false
   }
   
   override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
      view.endEditing(true)
   }
}

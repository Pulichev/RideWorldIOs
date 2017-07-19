//
//  EditProfileController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 26.02.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import Kingfisher
import Gallery
import SVProgressHUD

class EditProfileController: UIViewController, UITableViewDataSource, UITableViewDelegate {
   var delegate: EditedUserInfoDelegate?
   
   var userInfo: UserItem!
   
   @IBOutlet var tableView: UITableView!
   @IBOutlet var userPhoto: RoundedImageView!
   fileprivate var userChangedPhoto = false
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      NotificationCenter.default.addObserver(self, selector: #selector(LoginController.keyboardWillShow),
                                             name: NSNotification.Name.UIKeyboardWillShow, object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(LoginController.keyboardWillHide),
                                             name: NSNotification.Name.UIKeyboardWillHide, object: nil)
      
      if userInfo.photo150ref != nil {
         userPhoto.kf.setImage(with: URL(string: userInfo.photo150ref!))
      }
      
      tableView.tableFooterView = UIView(frame: .zero) // deleting empty rows
   }
   
   private func getCellFieldText(_ row: Int) -> String {
      return (tableView.cellForRow(at: IndexPath(row: row, section: 0)) as! EditProfileCell).field.text!
   }
   
   @IBAction func saveButtonTapped(_ sender: Any) {
      SVProgressHUD.show()
      let login = getCellFieldText(2).lowercased()
      // updating values
      // check if new login free, because they must be unic
      UserModel.getItemByLogin(for: login) { userItem in
         if userItem == nil || userItem!.uid == UserModel.getCurrentUserId() { // free
            self.updateInfo(with: login)
         } else {
            SVProgressHUD.dismiss()
            self.showAlertThatLoginAlreadyExists()
         }
      }
   }
   
   func updateInfo(with login: String) {
      let nameAndSename  = getCellFieldText(0)
      let bioDescription = getCellFieldText(1)
      
      UserModel.updateInfo(for: userInfo.uid, bioDescription, login, nameAndSename)
      
      if userChangedPhoto {
         uploadPhoto() { _ in
            self.returnToParentController(bioDescription,
                                          login,
                                          nameAndSename)
         }
      }
   }
   
   private func uploadPhoto(completion: @escaping (_ finished: Bool) -> Void) {
      UserMedia.upload(for: userInfo.uid,
                       with: userPhoto.image!, withSize: 150.0)
      { (hasFinishedSuccessfully, url) in
         
         UserModel.updatePhotoRef(for: self.userInfo.uid, size: 150, url: url)
         { _ in
            
            UserMedia.upload(for: self.userInfo.uid,
                             with: self.userPhoto.image!, withSize: 90.0)
            { (hasFinishedSuccessfully, url) in
               
               UserModel.updatePhotoRef(for: self.userInfo.uid, size: 90, url: url)
               { _ in
                  
                  completion(true)
               }
            }
         }
      }
   }
   
   private func returnToParentController(_ bioDescription: String, _ login: String, _ nameAndSename: String) {
      // change current user info and pass it and photo to user profile controller
      userInfo.bioDescription = bioDescription
      userInfo.login = login
      userInfo.nameAndSename = nameAndSename
      
      SVProgressHUD.dismiss()
      
      if let del = delegate {
         del.dataChanged(userInfo: userInfo, profilePhoto: userPhoto.image)
      }
      
      // return to profile
      _ = navigationController?.popViewController(animated: true)
   }
   
   private func showAlertThatLoginAlreadyExists() {
      let alert = UIAlertController(title: "Login change failed!", message: "Login already exists.", preferredStyle: .alert)
      
      alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
      
      present(alert, animated: true, completion: nil)
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

// MARK: - Camera extension
extension EditProfileController: GalleryControllerDelegate {
   
   @IBAction func changeProfilePhotoButtonTapped(_ sender: Any) {
      let gallery = GalleryController()
      gallery.delegate = self
      
      Config.Camera.imageLimit = 1
      Config.showsVideoTab = false
      
      present(gallery, animated: true, completion: nil)
   }
   
   func galleryController(_ controller: GalleryController, didSelectImages images: [UIImage]) {
      let img = images[0]
      
      self.userPhoto.image = img
      self.userChangedPhoto = true
      controller.dismiss(animated: true, completion: nil)
   }
   
   func galleryController(_ controller: GalleryController, didSelectVideo video: Video) {
   }
   
   func galleryController(_ controller: GalleryController, requestLightbox images: [UIImage]) {
   }
   
   func galleryControllerDidCancel(_ controller: GalleryController) {
      controller.dismiss(animated: true, completion: nil)
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

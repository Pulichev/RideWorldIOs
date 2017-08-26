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
   
   @IBOutlet var tableView: UITableView! {
      didSet {
         tableView.tableFooterView = UIView(frame: .zero) // deleting empty rows
      }
   }
   
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
   }
   
   private func getCellFieldText(_ row: Int) -> String {
      return (tableView.cellForRow(at: IndexPath(row: row, section: 0)) as! EditProfileCell).field.text!
   }
   
   @IBAction func saveButtonTapped(_ sender: Any) {
      SVProgressHUD.show()
      let login = getCellFieldText(2).lowercased()
      
      if isLoginSatisfiesRegEx(login) {
         // check if new login free, because they must be unic
         UserModel.getItemByLogin(for: login) { userItem, _ in
            if userItem == nil || userItem!.uid == UserModel.getCurrentUserId() { // free
               self.updateInfo(with: login)
            } else {
               SVProgressHUD.dismiss()
               self.showAlertWithErrorOnLoginChange(NSLocalizedString("Login already exists.", comment: ""))
            }
         }
      } else {
         showAlertWithErrorOnLoginChange(NSLocalizedString("Wrong login! You can use only english letters, numbers and ._-. The maximum length is 30 characters.", comment: ""))
      }
   }
   
   private func isLoginSatisfiesRegEx(_ login: String) -> Bool {
      if login.range(of: "[a-zA-Z0-9._-]{1,30}", options: .regularExpression) != nil {
         return true
      } else {
         return false
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
      } else {
         returnToParentController(bioDescription,
                                  login,
                                  nameAndSename)
      }
   }
   
   private func uploadPhoto(completion: @escaping (_ finished: Bool) -> Void) {
      UserMedia.upload(for: userInfo.uid,
                       with: userPhoto.image!, withSize: 350.0)
      { (hasFinishedSuccessfully, url) in
         
         UserModel.updatePhotoRef(for: self.userInfo.uid, size: 150, url: url)
         { _ in
            self.userInfo.photo150ref = url
            
            UserMedia.upload(for: self.userInfo.uid,
                             with: self.userPhoto.image!, withSize: 150.0)
            { (hasFinishedSuccessfully, url) in
               
               UserModel.updatePhotoRef(for: self.userInfo.uid, size: 90, url: url)
               { _ in
                  self.userInfo.photo90ref = url
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
   
   private func showAlertWithErrorOnLoginChange(_ text: String) {
      let alert = UIAlertController(title: NSLocalizedString("Login change failed!", comment: ""), message: text, preferredStyle: .alert)
      
      alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
      
      present(alert, animated: true, completion: nil)
   }
   
   //MARK: - User settings table
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      switch section {
      case 0:
         return 4
      case 1:
         return 4
      case 2:
         return 1
      default:
         return 0
      }
   }
   
   func numberOfSections(in tableView: UITableView) -> Int {
      return 3
   }
   
   func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
      switch section {
      case 0:
         return NSLocalizedString("User info", comment: "")
      case 1:
         return NSLocalizedString("General settings and rules", comment: "")
      case 2:
         return ""
      default:
         return ""
      }
   }
   
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let row     = indexPath.row
      let section = indexPath.section
      
      switch section {
      case 0:
         let cell = tableView.dequeueReusableCell(withIdentifier: "EditProfileCell", for: indexPath) as! EditProfileCell
         
         let leftImageView = UIImageView()
         let leftView = UIView()
         leftView.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
         leftImageView.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
         
         cell.field.leftViewMode = .always
         
         switch row {
         case 0:
            cell.field.text = userInfo.nameAndSename
            cell.field.placeholder = NSLocalizedString("Enter new name and sename", comment: "")
            leftImageView.image = UIImage(named: "namesename")
            leftView.addSubview(leftImageView)
            cell.field.leftView = leftView
            break
            
         case 1:
            cell.field.text = userInfo.bioDescription
            cell.field.placeholder = NSLocalizedString("Enter new bio description", comment: "")
            leftImageView.image = UIImage(named: "info")
            leftView.addSubview(leftImageView)
            cell.field.leftView = leftView
            break
            
         case 2:
            cell.field.delegate = self // for detecting tap and check last update time
            cell.field.text = self.userInfo.login
            leftImageView.image = UIImage(named: "login")
            leftView.addSubview(leftImageView)
            cell.field.leftView = leftView
            cell.field.placeholder = NSLocalizedString("Enter new login", comment: "")
            addTapGesture(on: cell.field) // for checking last login change date on click b4 editing
            break
            
         case 3:
            cell.field.text = userInfo.email
            cell.field.placeholder = NSLocalizedString("Enter new email", comment: "")
            leftImageView.image = UIImage(named: "mail")
            leftView.addSubview(leftImageView)
            cell.field.leftView = leftView
            cell.field.isEnabled = false
            break
            
         default:
            break
         }
         
         return cell
         
      case 1:
         let cell = tableView.dequeueReusableCell(withIdentifier: "CellWithButton", for: indexPath) as! CellWithButton
         
         switch row {
         case 0:
            cell.button.setTitle(NSLocalizedString("Language", comment: ""), for: .normal)
            cell.button.tintColor = UIColor.myDarkBlue()
            cell.button.addTarget(self, action: #selector(goToLanguageSelect), for: .touchUpInside)
            break
         case 1:
            cell.button.setTitle(NSLocalizedString("Terms of Use", comment: ""), for: .normal)
            cell.button.tintColor = UIColor.myDarkBlue()
            cell.button.addTarget(self, action: #selector(goToTermsOfUse), for: .touchUpInside)
            break
         case 2:
            cell.button.setTitle(NSLocalizedString("Privacy Policy", comment: ""), for: .normal)
            cell.button.tintColor = UIColor.myDarkBlue()
            cell.button.addTarget(self, action: #selector(goToPrivacyPolicy), for: .touchUpInside)
            break
         case 3:
            cell.button.setTitle(NSLocalizedString("Contacts", comment: ""), for: .normal)
            cell.button.tintColor = UIColor.myDarkBlue()
            cell.button.addTarget(self, action: #selector(goToContacts), for: .touchUpInside)
            break
            
         default:
            break
         }
         
         return cell
         
      case 2:
         let cell = tableView.dequeueReusableCell(withIdentifier: "CellWithButton", for: indexPath) as! CellWithButton
         cell.button.setTitle(NSLocalizedString("SignOut", comment: ""), for: .normal)
         cell.button.tintColor = UIColor.red
         cell.button.addTarget(self, action: #selector(signOut), for: .touchUpInside)
         return cell
         
      default:
         // kostil. need to release...
         return UITableViewCell()
      }
   }
   
   func signOut() {
      if UserModel.signOut() { // if no errors
         // then go to login
         performSegue(withIdentifier: "fromEditProfileToLogin", sender: self)
      }
   }
   
   func goToLanguageSelect() {
      performSegue(withIdentifier: "goToLanguageSelect", sender: self)
   }
   
   // MARK: - links to textView
   var fileNameToOpen: String!
   
   func goToTermsOfUse() {
      fileNameToOpen = "ToU"
      performSegue(withIdentifier: "fromEditToTextView", sender: self)
   }
   
   func goToPrivacyPolicy() {
      fileNameToOpen = "PP"
      performSegue(withIdentifier: "fromEditToTextView", sender: self)
   }
   
   func goToContacts() {
      fileNameToOpen = "Contacts info" // it will mean contacts
      performSegue(withIdentifier: "fromEditToTextView", sender: self)
   }
   
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      switch segue.identifier! {
      case "fromEditToTextView":
         let newTextViewController = segue.destination as! TextViewController
         newTextViewController.fileNameString = fileNameToOpen
         break
         
      default:
         break
      }
   }
   
   var keyBoardAlreadyShowed = false //using this to not let app to scroll view
   //if we tapped UITextField and then another UITextField
   
   var loginTextField: UITextField!
}

extension EditProfileController: UITextFieldDelegate {
   
   fileprivate func addTapGesture(on textField: UITextField) {
      loginTextField = textField
      
      let tap = UITapGestureRecognizer(target: self, action:#selector(checkLastUpdateTime))
      tap.numberOfTapsRequired = 1
      textField.addGestureRecognizer(tap)
      textField.isUserInteractionEnabled = true
   }
   
   func checkLastUpdateTime() {
      SVProgressHUD.show()
      
      UserModel.getCountOfDaysAfterLastLoginChangeDate() { countOfDaysFromLastChange in
         SVProgressHUD.dismiss()
         
         if countOfDaysFromLastChange < 180 {
            // fixing frame cz some events happening here with keyboard
            if self.keyBoardAlreadyShowed {
               self.view.frame.origin.y -= 100
            }
            
            self.showAlertWithError(text: NSLocalizedString("Days for next change: ", comment: "") + String((180 - countOfDaysFromLastChange)))
         } else {
            self.loginTextField.isEnabled = true
            self.loginTextField.becomeFirstResponder()
            self.showInfoAlertAboutLoginChangeTime()
         }
      }
   }
   
   private func showAlertWithError(text: String) {
      SVProgressHUD.dismiss()
      
      let alert = UIAlertController(title: NSLocalizedString("Oops!", comment: ""),
                                    message: text,
                                    preferredStyle: .alert)
      
      alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
      
      present(alert, animated: true, completion: nil)
   }
   
   private func showInfoAlertAboutLoginChangeTime() {
      let alert = UIAlertController(title: NSLocalizedString("Info", comment: ""),
                                    message: NSLocalizedString("Login changing is taking some time.", comment: ""),
                                    preferredStyle: .alert)
      
      alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
      
      present(alert, animated: true, completion: nil)
   }
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

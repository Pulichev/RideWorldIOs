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
import Photos
import SVProgressHUD

class EditProfileController: UITableViewController {
   
   var delegate: EditedUserInfoDelegate?
   
   var userInfo: UserItem!
   var sourceLogin: String!
   
   var userInfoTableValues = [String](repeating: "", count: 3) // for saving values from textField
   
   @IBOutlet var userPhoto: RoundedImageView!
   fileprivate var userChangedPhoto = false
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      sourceLogin = userInfo.login
      
      NotificationCenter.default.addObserver(self, selector: #selector(EditProfileController.keyboardWillShow),
                                             name: NSNotification.Name.UIKeyboardWillShow, object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(EditProfileController.keyboardWillHide),
                                             name: NSNotification.Name.UIKeyboardWillHide, object: nil)
      
      if userInfo.photo150ref != nil {
         userPhoto.kf.setImage(with: URL(string: userInfo.photo150ref!))
      }
      
      // init default values, which can be changed.
      userInfoTableValues[0] = userInfo.nameAndSename ?? ""
      userInfoTableValues[1] = userInfo.bioDescription ?? ""
      userInfoTableValues[2] = userInfo.login
      
      initTableRows()
   }
   
   @IBAction func saveButtonTapped(_ sender: Any) {
      view.endEditing(true)
      SVProgressHUD.show()
      let login = userInfoTableValues[2].lowercased()
      
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
         SVProgressHUD.dismiss()
         showAlertWithErrorOnLoginChange(NSLocalizedString("Wrong login! You can use only english letters, numbers and ._-. The maximum length is 30 characters.", comment: ""))
      }
   }
   
   private func isLoginSatisfiesRegEx(_ login: String) -> Bool {
      if login.range(of: "[a-zA-Z0-9._-]{1,30}$", options: .regularExpression) != nil {
         return true
      } else {
         return false
      }
   }
   
   func updateInfo(with login: String) {
      let nameAndSename  = userInfoTableValues[0]
      let bioDescription = userInfoTableValues[1]
      
      UserModel.updateInfo(for: userInfo.uid, bioDescription, login, nameAndSename)
      
      if login != sourceLogin {
         UserModel.setLastLoginChangeDate()
      }
      
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
   
   @IBAction func changeProfilePhotoButtonTapped(_ sender: Any) {
      let gallery = GalleryController()
      gallery.delegate = self
      
      Config.Camera.imageLimit = 1
      Config.showsVideoTab = false
      
      present(gallery, animated: true, completion: nil)
   }
   
   override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
      switch section {
      case 0:
         return ""
      case 1:
         return NSLocalizedString("User info", comment: "")
      case 2:
         return NSLocalizedString("General settings and rules", comment: "")
      case 3:
         return ""
      default:
         return ""
      }
   }
   
   override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      tableView.deselectRow(at: indexPath, animated: true)
   }
   
   // MARK: - IBOutlets from tableView
   // User info section
   @IBOutlet weak var nameAndSename: UITextFieldX!
   @IBOutlet weak var bioDescription: UITextFieldX!
   @IBOutlet weak var login: UITextFieldX!
   @IBOutlet weak var email: UITextFieldX!
   // General settings and rules section
   @IBOutlet weak var language: UIButtonX!
   @IBOutlet weak var termsOfUse: UIButtonX!
   @IBOutlet weak var privacyPolicy: UIButtonX!
   @IBOutlet weak var contacts: UIButtonX!
   //
   @IBOutlet weak var signOut: UIButtonX!
   
   private func initTableRows() {
      // User info section
      nameAndSename.text = userInfoTableValues[0]
      nameAndSename.placeholder = NSLocalizedString("Enter new name and sename", comment: "")
      nameAndSename.delegate = self
      
      bioDescription.text = userInfoTableValues[1]
      bioDescription.placeholder = NSLocalizedString("Enter new bio description", comment: "")
      bioDescription.delegate = self

      login.text = userInfoTableValues[2]
      login.placeholder = NSLocalizedString("Enter new login", comment: "")
      login.delegate = self
      addTapGesture(on: login) // for checking last login change date on click b4 editing
      
      email.text = userInfo.email
      email.placeholder = NSLocalizedString("Enter new email", comment: "")
      email.isEnabled = false

      // General settings and rules section
      language.setTitle(NSLocalizedString("Language", comment: ""), for: .normal)
      language.tintColor = UIColor.myBlack()
      language.addTarget(self, action: #selector(goToLanguageSelect), for: .touchUpInside)
      
      termsOfUse.setTitle(NSLocalizedString("Terms of Use", comment: ""), for: .normal)
      termsOfUse.tintColor = UIColor.myBlack()
      termsOfUse.addTarget(self, action: #selector(goToTermsOfUse), for: .touchUpInside)
      
      privacyPolicy.setTitle(NSLocalizedString("Privacy Policy", comment: ""), for: .normal)
      privacyPolicy.tintColor = UIColor.myBlack()
      privacyPolicy.addTarget(self, action: #selector(goToPrivacyPolicy), for: .touchUpInside)
      
      contacts.setTitle(NSLocalizedString("Contacts", comment: ""), for: .normal)
      contacts.tintColor = UIColor.myBlack()
      contacts.addTarget(self, action: #selector(goToContacts), for: .touchUpInside)
      
      //
      signOut.setTitle(NSLocalizedString("SignOut", comment: ""), for: .normal)
      signOut.tintColor = UIColor.red
      signOut.addTarget(self, action: #selector(signOutButtonTapped), for: .touchUpInside)
   }
   
   @objc func signOutButtonTapped() {
      if UserModel.signOut() { // if no errors
         // then go to login
         performSegue(withIdentifier: "fromEditProfileToLogin", sender: self)
      }
   }
   
   @objc func goToLanguageSelect() {
      performSegue(withIdentifier: "goToLanguageSelect", sender: self)
   }
   
   // MARK: - links to textView
   var fileNameToOpen: String!
   
   @objc func goToTermsOfUse() {
      fileNameToOpen = "ToU"
      performSegue(withIdentifier: "fromEditToTextView", sender: self)
   }
   
   @objc func goToPrivacyPolicy() {
      fileNameToOpen = "PP"
      performSegue(withIdentifier: "fromEditToTextView", sender: self)
   }
   
   @objc func goToContacts() {
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
   
   @objc func checkLastUpdateTime() {
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
   
   func textFieldDidEndEditing(_ textField: UITextField) {
      let index = textField.tag
      userInfoTableValues[index] = textField.text! ?? ""
   }
}

// MARK: - Camera extension
extension EditProfileController: GalleryControllerDelegate {
   
   func galleryController(_ controller: GalleryController, didSelectImages images: [Gallery.Image]) {
      let img = images[0]
      
      self.userPhoto.image = img.uiImage(ofSize: PHImageManagerMaximumSize)
      self.userChangedPhoto = true
      controller.dismiss(animated: true, completion: nil)
   }
   
   func galleryController(_ controller: GalleryController, didSelectVideo video: Video) {
   }
   
   func galleryController(_ controller: GalleryController, requestLightbox images: [Gallery.Image]) {
   }
   
   func galleryControllerDidCancel(_ controller: GalleryController) {
      controller.dismiss(animated: true, completion: nil)
   }
}

// MARK: - Scroll for keyboard show/hide
extension EditProfileController {
   @objc func keyboardWillShow(notification: NSNotification) {
      if !keyBoardAlreadyShowed {
         view.frame.origin.y -= 100
         keyBoardAlreadyShowed = true
      }
   }
   
   @objc func keyboardWillHide(notification: NSNotification) {
      view.frame.origin.y += 100
      keyBoardAlreadyShowed = false
   }
   
   override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
      view.endEditing(true)
   }
}

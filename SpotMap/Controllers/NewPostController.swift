//
//  NewPostController.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 24.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import MobileCoreServices

class NewPostController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate
{
    var backendless: Backendless!
    
    var spotDetails: SpotDetails!
    
    @IBOutlet weak var postDescription: UITextView!
    
    @IBOutlet weak var imageView: UIImageView!
    var newMedia: Bool?
    
    override func viewDidLoad()
    {
        backendless = Backendless.sharedInstance()
        imageView.image = UIImage(named: "plus-512.gif") //Setting default picture
        placeBorderOnTextField()
        
        //adding method on spot main photo tap
        let tap = UITapGestureRecognizer(target:self, action:#selector(takePhoto(_:)))
        imageView.addGestureRecognizer(tap)
        imageView.isUserInteractionEnabled = true
        
        self.postDescription.delegate = self
        
        //For scrolling the view if keyboard on
        NotificationCenter.default.addObserver(self, selector: #selector(NewPostController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NewPostController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func placeBorderOnTextField()
    {
        postDescription.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
        postDescription.layer.borderWidth = 1.0
        postDescription.layer.cornerRadius = 5
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.characters.count
        return numberOfChars < 150
    }
    
    @IBAction func takePhoto(_ sender: Any)
    {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)
        {
            let imagePicker = UIImagePickerController()
            
            imagePicker.delegate = self
            imagePicker.sourceType =
                UIImagePickerControllerSourceType.camera
            imagePicker.mediaTypes = [kUTTypeImage as String]
            imagePicker.allowsEditing = false
            
            self.present(imagePicker, animated: true, completion: nil)
            newMedia = true
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        
        self.dismiss(animated: true, completion: nil)
        
        if mediaType.isEqual(to: kUTTypeImage as String) {
            let image = info[UIImagePickerControllerOriginalImage]
                as! UIImage
            
            imageView.image = image
            imageView.layer.cornerRadius = imageView.frame.size.height / 8
            imageView.layer.masksToBounds = true
            imageView.layer.borderWidth = 0
            
            if (newMedia == true) {
                UIImageWriteToSavedPhotosAlbum(image, self,
                                               #selector(NewSpotController.image(image:didFinishSavingWithError:contextInfo:)), nil)
            } else if mediaType.isEqual(to: kUTTypeMovie as String) {
                // Code to support video here
            }
        }
    }
    
    func image(image: UIImage, didFinishSavingWithError error: NSErrorPointer, contextInfo:UnsafeRawPointer)
    {
        if error != nil {
            let alert = UIAlertController(title: "Save Failed",
                                          message: "Failed to save image",
                                          preferredStyle: UIAlertControllerStyle.alert)
            
            let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func saveSpotDetails(_ sender: Any)
    {
        let defaults = UserDefaults.standard
        let userId = defaults.string(forKey: "userLoggedInObjectId")
        
        let spotPost = SpotPost()
        spotPost.userId = userId
        spotPost.spotId = spotDetails.objectId
        spotPost.postDescription = self.postDescription.text
        
        let savedSpotPostID = backendless.persistenceService.of(spotPost.ofClass()).save(spotPost) as! SpotPost
        uploadRecordSync(postId: savedSpotPostID.objectId!)
        
        self.performSegue(withIdentifier: "backToPosts", sender: self) //back to spot posts
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if(segue.identifier == "backToPosts")
        {
            let spotDetailsController = (segue.destination as! SpotDetailsController)
            spotDetailsController.spotDetails = self.spotDetails
        }
    }
    
    //Uploading files with the SYNC API
    func uploadRecordSync(postId: String)
    {
        Types.tryblock({ () -> Void in
            
            let data: Data = UIImageJPEGRepresentation(self.imageView.image!, 0.3)!
            let uploadedFile = self.backendless.fileService.saveFile("media/SpotPostPhotos/" + postId.replacingOccurrences(of: "-", with: "") + ".jpeg", content: data, overwriteIfExist: true)
            print("File has been uploaded. File URL is - \(uploadedFile?.fileURL)")
        },
                       catchblock: { (exception) -> Void in
                        print("Server reported an error: \(exception as! Fault)")
        })
    }
    
    //PART FOR RESIZE VIEW WHEN KEYBOARD ON
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    var bottomConstraintValue: CGFloat = 40.0 //Start value of constraint
    
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
        
        UIView.animate(withDuration: 3.0, animations: { () -> Void in
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
    //END PART
}

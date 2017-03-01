//
//  MyStripController.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 28.02.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import FirebaseAuth

class MyStripController: UIViewController {
    override func viewDidLoad() {
        // Get a reference to the storage service using the default Firebase App
        let storage = FIRStorage.storage()
        
        // Create a storage reference from our storage service
        let storageRef = storage.reference()
        
        // Create a reference to the file to delete
        let desertRef = storageRef.child("iPhone 6.png")
        
        if FIRAuth.auth()?.currentUser == nil {
            FIRAuth.auth()?.signInAnonymously(completion: { (user: FIRUser?, error: Error?) in
                if let error = error {
                    print("********************************************ERROR")
                } else {
                    print("********************************************Deleted")
                }
            })
        }
        
        // Delete the file
        desertRef.delete { error in
            if let error = error {
                print("********************************************ERROR")
                // Uh-oh, an error occurred!
            } else {
                print("********************************************Deleted")
                // File deleted successfully
            }
        }
        
        // Data in memory
        let data: Data = UIImageJPEGRepresentation(UIImage(named: "plus-512.gif")!, 1.0)!
        
        // Create a reference to the file you want to upload
        let riversRef = storageRef.child("images/rivers.jpg")
        
        // Upload the file to the path "images/rivers.jpg"
        let uploadTask = riversRef.put(data, metadata: nil) { (metadata, error) in
            guard let metadata = metadata else {
                // Uh-oh, an error occurred!
                return
            }
            // Metadata contains file metadata such as size, content-type, and download URL.
            let downloadURL = metadata.downloadURL
        }
    }
}

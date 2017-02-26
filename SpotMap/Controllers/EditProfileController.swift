//
//  EditProfileController.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 26.02.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import Foundation
import UIKit

class EditProfileController: UIViewController {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var userPhoto: UIImageView!
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        
    }
    
    @IBAction func changeProfilePhotoButtonTapped(_ sender: Any) {
        
    }
    
    //Main table filling region
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        } else {
            if section == 1 {
                return 2
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SpotPostsCell", for: indexPath) as! SpotPostsCell
        let row = indexPath.row
        
        
        
        return cell
    }

}

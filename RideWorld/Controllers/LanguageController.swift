//
//  LanguageController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 20.08.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit

class LanguageController: UITableViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.delegate = self
    tableView.dataSource = self
    tableView.tableFooterView = UIView() // deleting empty rows
  }
  
  // MARK: - Table view filling part
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 2
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "CellWithButton", for: indexPath) as! CellWithButton
    
    let row = indexPath.row
    
    switch (row) {
    case 0:
      cell.button.setTitle("English🇬🇧", for: .normal)
      cell.button.tintColor = UIColor.myBlack()
      break
    case 1:
      cell.button.setTitle("Русский🇷🇺", for: .normal)
      cell.button.tintColor = UIColor.myBlack()
      break
    default:
      break
    }
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let row = indexPath.row
    
    switch (row) {
    case 0:
      UserDefaults.standard.set(["Base"], forKey: "AppleLanguages")
      UserDefaults.standard.synchronize()
      break
      
    case 1:
      UserDefaults.standard.set(["Russian"], forKey: "AppleLanguages")
      UserDefaults.standard.synchronize()
      break
    default:
      break
    }
    
    showAlertThatRestartRequired()
  }
  
  private func showAlertThatRestartRequired() {
    let alert = UIAlertController(title: NSLocalizedString("Restart required!", comment: ""),
                                  message: NSLocalizedString("Please, restart an application", comment: ""),
                                  preferredStyle: .alert)
    
    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
    
    present(alert, animated: true, completion: nil)
  }
}

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
   }
   
   // MARK: - Table view data source
   override func numberOfSections(in tableView: UITableView) -> Int {
      return 1
   }
   
   override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return 2
   }
   
   override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = tableView.dequeueReusableCell(withIdentifier: "CellWithButton", for: indexPath) as! CellWithButton
      
      let row = indexPath.row
      
      switch (row) {
      case 0:
         cell.button.setTitle("English🇬🇧", for: .normal)
         break
      case 1:
         cell.button.setTitle("Русский🇷🇺", for: .normal)
         break
      default:
         break
      }
      
      return cell
   }
}

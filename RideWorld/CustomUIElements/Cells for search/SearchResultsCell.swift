//
//  UIRidersCell.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 17.06.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit

class SearchResultsCell: UITableViewCell {

   @IBOutlet weak var photo: RoundedImageView!
   @IBOutlet weak var name: UILabel!
   
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

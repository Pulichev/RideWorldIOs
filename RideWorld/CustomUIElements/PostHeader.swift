//
//  PostHeader.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 03.07.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit

class PostHeader: UITableViewCell {
   
   @IBOutlet weak var spotPhoto: RoundedImageView!
   @IBOutlet weak var spotName: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}

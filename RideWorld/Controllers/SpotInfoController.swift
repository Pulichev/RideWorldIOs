//
//  SpotInfoController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 30.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import Kingfisher

class SpotInfoController: UIViewController {
   var spotInfo: SpotDetailsItem!
   
   @IBOutlet weak var photosCollection: UICollectionView!
   private var photos = [UIImageView]()
   
   @IBOutlet weak var name: UILabel!
   @IBOutlet weak var desc: UILabel!
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      name.text = spotInfo.name
      desc.text = spotInfo.description
   }
   
   // MARK: - Photo collection part
   func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
      return photos.count
   }
   
   func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCollectionViewCell", for: indexPath as IndexPath) as! ImageCollectionViewCell
      
      cell.postPicture.image = photos[indexPath.row].image!
      
      return cell
   }
}

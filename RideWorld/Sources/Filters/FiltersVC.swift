//
//  FiltersVC.swift
//  photoTaking
//
//  Created by Sacha Durand Saint Omer on 21/10/16.
//  Copyright © 2016 octopepper. All rights reserved.
//

import UIKit

class FiltersVC: UIViewController {
    
    override var prefersStatusBarHidden: Bool { return true }
    
    var v = FiltersView()
    var filterPreviews = [FilterPreview]()
    var filters = [Filter]()
    var originalImage = UIImage()
    var thumbImage = UIImage()
    var didSelectImage: ((UIImage, Bool) -> Void)?
    var isImageFiltered = false
    
    override func loadView() { view = v }
    
    required init(image: UIImage) {
        super.init(nibName: nil, bundle: nil)
        title = fsLocalized("YPFusumaFilter")
        self.originalImage = image
        
        filterPreviews = [
            FilterPreview("Normal"),
            FilterPreview("Mono"),
            FilterPreview("Tonal"),
            FilterPreview("Noir"),
            FilterPreview("Fade"),
            FilterPreview("Chrome"),
            FilterPreview("Process"),
            FilterPreview("Transfer"),
            FilterPreview("Instant"),
            FilterPreview("Sepia")
        ]
        
        let filterNames = [
            "",
            "CIPhotoEffectMono",
            "CIPhotoEffectTonal",
            "CIPhotoEffectNoir",
            "CIPhotoEffectFade",
            "CIPhotoEffectChrome",
            "CIPhotoEffectProcess",
            "CIPhotoEffectTransfer",
            "CIPhotoEffectInstant",
            "CISepiaTone"
        ]
        
        for fn in filterNames {
            filters.append(Filter(fn))
        }
    }
    
    func thumbFromImage(_ img: UIImage) -> UIImage {
        let width: CGFloat = img.size.width / 5
        let height: CGFloat = img.size.height / 5
        UIGraphicsBeginImageContext(CGSize(width:width, height:height))
        img.draw(in: CGRect(x:0, y:0, width:width, height:height))
        let smallImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return smallImage!
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        v.imageView.image = originalImage
        thumbImage = thumbFromImage(originalImage)
        v.collectionView.register(FilterCollectionViewCell.self, forCellWithReuseIdentifier: "FilterCell")
        v.collectionView.dataSource = self
        v.collectionView.delegate = self
        v.collectionView.selectItem(at: IndexPath(row: 0, section: 0),
                                                  animated: false,
                                                  scrollPosition: UICollectionViewScrollPosition.bottom)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                            target: self,
                                                            action: #selector(done))
    }
    
    func done() {
        didSelectImage?(v.imageView.image!, isImageFiltered)
    }
}

extension FiltersVC: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filterPreviews.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let filterPreview = filterPreviews[indexPath.row]
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterCell",
                                                         for: indexPath) as? FilterCollectionViewCell {
            cell.name.text = filterPreview.name
            if let img = filterPreview.image {
                cell.imageView.image = img
            } else {
                let filter = self.filters[indexPath.row]
                let filteredImage = filter.filter(self.thumbImage)
                cell.imageView.image = filteredImage
                filterPreview.image = filteredImage // Cache
            }
            return cell
        }
        return UICollectionViewCell()
    }
}

extension FiltersVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedFilter = filters[indexPath.row]
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            let filteredImage = selectedFilter.filter(self.originalImage)
            DispatchQueue.main.async {
                self.v.imageView.image = filteredImage
            }
        }
        
        if selectedFilter.name != "" {
            self.isImageFiltered = true
        }
    }
}

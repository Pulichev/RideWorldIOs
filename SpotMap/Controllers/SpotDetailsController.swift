//
//  SpotDetailsController.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 19.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit

class SpotDetailsController: UIViewController, UITableViewDataSource, UITableViewDelegate
{
    var backendless: Backendless!
    
    @IBOutlet weak var tableView: UITableView!
    
    var spotDetails: SpotDetails!
    
    var spotPosts = [SpotPost]()
    var spotPostsCellsCache = [SpotPostsCellCache]()
    
    var imageCache = NSMutableDictionary()
    
    override func viewDidLoad()
    {
        backendless = Backendless.sharedInstance()
        
        loadSpotPosts()
        loadSpotPostCellsTextInfo()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        super.viewDidLoad()
    }
    
    func loadSpotPosts()
    {
        let whereClause = "spotId = '\(spotDetails.objectId!)'"
        let dataQuery = BackendlessDataQuery()
        dataQuery.whereClause = whereClause
        
        var error: Fault?
        let spotPostsList = backendless.data.of(SpotPost.ofClass()).find(dataQuery, fault: &error)
        
        if error != nil
        {
            //when no posts on this spot
            let whenNoPostsAvailable = SpotPost()
            whenNoPostsAvailable.postDescription = ""
            whenNoPostsAvailable.spotId = spotDetails.objectId
            whenNoPostsAvailable.userId = ""
            whenNoPostsAvailable.objectId = "noPosts" //passing this id cz our picture from server called noPosts.jpeg
            
            spotPosts.insert(whenNoPostsAvailable, at: 0)
            print("Server reported an error: \(spotPostsList)")
            return
        }
        
        spotPosts = spotPostsList?.data as! [SpotPost]
    }
    
    //First add must have info. Text info.
    func loadSpotPostCellsTextInfo()
    {
        var i = 0
        let userNickName = getUserNickName()
        for spot in spotPosts
        {
            let newSpotPostCellCache = SpotPostsCellCache()
            
            newSpotPostCellCache.postId = spot.objectId!
            newSpotPostCellCache.userNickName.text = userNickName
            
            let sourceDate = String(describing: spot.created!)
            //formatting date to yyyy-mm-dd
            let finalDate = sourceDate[sourceDate.startIndex..<sourceDate.index(sourceDate.startIndex, offsetBy: 10)]
            newSpotPostCellCache.postDate.text = finalDate
            newSpotPostCellCache.postDescription.text = spot.postDescription
            newSpotPostCellCache.userLikedThisPost()
            newSpotPostCellCache.countPostLikes()
            
            spotPostsCellsCache.append(newSpotPostCellCache)
            i += 1
        }
    }
    
    //Main table filling region
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.spotPosts.count
    }
    
    //ЗАПОЛНИТЬ В ОТДЕЛЬНОМ ПОТОКЕ ВСЕ ТЕКСТОВЫЕ ПОЛЯ
    //В ДРУГОМ ФОТКИ
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SpotPostsCell", for: indexPath) as! SpotPostsCell
        let row = indexPath.row
        let cellFromCache = spotPostsCellsCache[row]
        
        cell.postId = cellFromCache.postId
        
        //Downloading and caching images
        let postPhotoURL = "https://api.backendless.com/4B2C12D1-C6DE-7B3E-FFF0-80E7D3628C00/v1/files/media/SpotPostPhotos/" + (spotPosts[row].objectId!).replacingOccurrences(of: "-", with: "") + ".jpeg"
        let cacheKey = indexPath.row
        if (self.imageCache.object(forKey: cacheKey) != nil) {
            cell.spotPostPhoto.image = self.imageCache.object(forKey: cacheKey) as? UIImage
        } else {
            DispatchQueue.global(qos: .userInteractive).async(execute: {
                if let url = URL(string: postPhotoURL) {
                    if let data = NSData(contentsOf: url) {
                        let image: UIImage = UIImage(data: data as Data)!
                        self.imageCache.setObject(image, forKey: cacheKey as NSCopying)
                        DispatchQueue.main.async(execute: {
                            cell.spotPostPhoto.image = image
                        })
                    }
                }
            })
        } //end d and c images
        
        cell.userNickName.text = cellFromCache.userNickName.text
        cell.postDate.text = cellFromCache.postDate.text
        cell.postDescription.text = cellFromCache.postDescription.text
        cell.likesCount.text = String(cellFromCache.likesCount)
        cell.postIsLiked = cellFromCache.postIsLiked
        cell.isLikedPhoto.image = cellFromCache.isLikedPhoto.image
        
        DispatchQueue.main.async {
            cell.addDoubleTapGestureOnPostPhotos()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func getUserNickName() -> String
    {
        let defaults = UserDefaults.standard
        let userNickName = defaults.string(forKey: "userLoggedInNickName")
        
        return userNickName!
    }
    //ENDTABLE filling region
    
    @IBAction func addNewPost(_ sender: Any)
    {
        self.performSegue(withIdentifier: "addNewPost", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if(segue.identifier == "addNewPost")
        {
            let newPostController = (segue.destination as! NewPostController)
            newPostController.spotDetails = self.spotDetails
        }
    }
}

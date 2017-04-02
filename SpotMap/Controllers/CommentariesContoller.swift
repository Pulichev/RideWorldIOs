//
//  CommentariesContoller.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 01.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//
import UIKit

class CommentariesController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var postDescription: UITextView!
    @IBOutlet weak var tableView: UITableView!
    
    var comments = [CommentItem]()
    
    override func viewDidLoad() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.followList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FollowersTableCell", for: indexPath) as! FollowersTableCell
        let row = indexPath.row
        
        cell.follower = self.followList[row]
        
        // adding tap event -> perform segue to profile
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(goToProfile(_:)))
        cell.userImage.tag = row
        cell.userImage.isUserInteractionEnabled = true
        cell.userImage.addGestureRecognizer(tapGestureRecognizer)
        
        return cell
    }
}

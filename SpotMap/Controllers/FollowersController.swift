//
//  FollowersControllers.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 14.03.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage

class FollowersController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var tableView: UITableView!
    
    var userId: String!
    var followersOrFollowingList: Bool! // if true - followers else - following
    private var followList = [UserItem]()
    
    override func viewDidLoad() {
        self.loadFollowList()
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func loadFollowList() {
        var userFollowRef = FIRDatabase.database().reference(withPath: "MainDataBase/users/").child(self.userId)
        if followersOrFollowingList == true { // followers ref
            userFollowRef = userFollowRef.child("followers")
        } else { // following ref
            userFollowRef = userFollowRef.child("following")
        }
        
        userFollowRef.observe(.value, with: { snapshot in
            let value = snapshot.value as? NSDictionary
            if let followingsId = value?.allKeys as? [String] {
                for followId in followingsId {
                    let followRef = FIRDatabase.database().reference(withPath: "MainDataBase/users/").child(followId)
                    
                    followRef.observe(.value, with: { snapshot in
                        let followItem = UserItem(snapshot: snapshot)
                        
                        self.followList.append(followItem)
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    })
                }
            }
        })
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
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // idk if i will use it
    }
}

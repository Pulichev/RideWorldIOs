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
import FirebaseAuth

class FollowersController: UIViewController, UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    @IBOutlet var tableView: UITableView!
    
    var userId: String!
    var followersOrFollowingList: Bool! // if true - followers else - following
    private var followList = [UserItem]()
    
    override func viewDidLoad() {
        self.loadFollowList()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.emptyDataSetSource = self
        self.tableView.emptyDataSetDelegate = self
        self.tableView.tableFooterView = UIView()
    }
    
    private func loadFollowList() {
        var userFollowRef = FIRDatabase.database().reference(withPath: "MainDataBase/users/").child(self.userId)
        if followersOrFollowingList == true { // followers ref
            userFollowRef = userFollowRef.child("followers")
        } else { // following ref
            userFollowRef = userFollowRef.child("following")
        }
        
        userFollowRef.observeSingleEvent(of: .value, with: { snapshot in
            let value = snapshot.value as? NSDictionary
            if let followingsId = value?.allKeys as? [String] {
                for followId in followingsId {
                    let followRef = FIRDatabase.database().reference(withPath: "MainDataBase/users/").child(followId)
                    
                    followRef.observeSingleEvent(of: .value, with: { snapshot in
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
        
        // adding tap event -> perform segue to profile
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(goToProfile(_:)))
        cell.userImage.tag = row
        cell.userImage.isUserInteractionEnabled = true
        cell.userImage.addGestureRecognizer(tapGestureRecognizer)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // idk if i will use it
    }
    
    func goToProfile(_ sender: UIGestureRecognizer) {
        if self.followList[(sender.view?.tag)!].uid == (FIRAuth.auth()?.currentUser?.uid)! {
            self.performSegue(withIdentifier: "openUserProfileFromFollowList", sender: self)
        } else {
            self.ridersInfoForSending = self.followList[(sender.view?.tag)!]
            self.performSegue(withIdentifier: "openRidersProfileFromFollowList", sender: self)
        }
    }
    
    var ridersInfoForSending: UserItem!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "openRidersProfileFromFollowList" {
            let newRidersProfileController = segue.destination as! RidersProfileController
            newRidersProfileController.ridersInfo = ridersInfoForSending
            newRidersProfileController.title = ridersInfoForSending.login
        }
        
        if segue.identifier == "openUserProfileFromFollowList" {
            let userProfileController = segue.destination as! UserProfileController
            userProfileController.cameFromSpotDetails = true
        }
    }
    
    // MARK: DZNEmptyDataSet for empty data tables
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let str = ":("
        let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let str = "Nothing to show"
        let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    // ENDMARK: DZNEmptyDataSet
}

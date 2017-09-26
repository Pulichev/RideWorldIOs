//
//  SpotFollowingsController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 22.08.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit

class SpotFollowingsController: UIViewController, UITableViewDelegate, UITableViewDataSource {
   
   @IBOutlet weak var tableView: UITableView!
   
   var userId: String!
   
   fileprivate var spotFollowList = [SpotItem]()
   
   override func viewDidLoad() {
      loadSpotFollowList()
      
      tableView.delegate = self
      tableView.dataSource = self
      tableView.emptyDataSetSource = self
      tableView.emptyDataSetDelegate = self
      tableView.tableFooterView = UIView()
   }
   
   private func loadSpotFollowList() {
      Spot.getUserFollowedSpots(userId) { followingsList in
         self.spotFollowList = followingsList
         
         self.haveWeFinishedLoading = true
         self.tableView.reloadData()
      }
   }
   
   func numberOfSections(in tableView: UITableView) -> Int {
      return 1
   }
   
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return spotFollowList.count
   }
   
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = tableView.dequeueReusableCell(withIdentifier: "SpotFollowingCell", for: indexPath) as! SpotFollowingCell
      let row = indexPath.row
      
      cell.spot = spotFollowList[row]
      
      // adding tap event -> perform segue to spot info
      let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(sendRowToGoToSpotInfo(_:)))
      cell.spotImage.tag = row
      cell.spotImage.isUserInteractionEnabled = true
      cell.spotImage.addGestureRecognizer(tapGestureRecognizer)
      
      return cell
   }
   
   // here is redirecting to spot info by click on row.
   // So we have 2 redirects. By image and row
   func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      tableView.deselectRow(at: indexPath, animated: true)
      
      let row = indexPath.row
      
      goToSpotInfo(row: row)
   }
   
   // Idk how to make next 2 func to be 1
   @objc func sendRowToGoToSpotInfo(_ sender: UIGestureRecognizer) {
      goToSpotInfo(row: (sender.view?.tag)!)
   }
   
   func goToSpotInfo(row: Int) {
      spotInfoForSending = spotFollowList[row]
      performSegue(withIdentifier: "fromSpotFollowingsToSpotInfo", sender: self)
   }
   
   var spotInfoForSending: SpotItem!
   
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      switch segue.identifier! {
      case "fromSpotFollowingsToSpotInfo":
         let newSpotInfoController = segue.destination as! SpotInfoController
         newSpotInfoController.spotInfo = spotInfoForSending
         newSpotInfoController.delegateFollowTaps = self
         
      default: break
      }
   }
   
   var haveWeFinishedLoading = false // bool value have we loaded followers list or not. Mainly for DZNEmptyDataSet
}

extension SpotFollowingsController: FollowTappedFromSpotInfo {
   func followTapped(on spotId: String) {
      // update follow button
      let index = spotFollowList.index(where: { $0.key == spotId })
      
      let indexPath = [IndexPath(row: index!, section: 0)]
      
      // update cell
      tableView.beginUpdates()
      tableView.reloadRows(at: indexPath, with: .none)
      tableView.endUpdates()
   }
}

// MARK: - DZNEmptyDataSet for empty data tables
extension SpotFollowingsController: DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
   func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
      if haveWeFinishedLoading {
         let str = ":("
         let attrs = [NSAttributedStringKey.font: UIFont(name: "PTSans-Bold", size: 22)]
         return NSAttributedString(string: str, attributes: attrs)
      } else {
         let str = NSLocalizedString("Wait, please", comment: "")
         let attrs = [NSAttributedStringKey.font: UIFont(name: "PTSans-Bold", size: 22)]
         return NSAttributedString(string: str, attributes: attrs)
      }
   }
   
   func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
      if haveWeFinishedLoading {
         let str = NSLocalizedString("Nothing to show.", comment: "")
         let attrs = [NSAttributedStringKey.font: UIFont(name: "PT Sans", size: 19.0)]
         return NSAttributedString(string: str, attributes: attrs)
      } else {
         let str = NSLocalizedString("Loading list..", comment: "")
         let attrs = [NSAttributedStringKey.font: UIFont(name: "PT Sans", size: 19.0)]
         return NSAttributedString(string: str, attributes: attrs)
      }
   }
}

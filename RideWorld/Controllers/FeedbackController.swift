//
//  FeedbackController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 11.05.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import Kingfisher

class FeedbackController: UIViewController, UITableViewDelegate, UITableViewDataSource {
   private let userId: String = User.getCurrentUserId()
   
   @IBOutlet weak var tableView: UITableView!
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      loadFeedbackItems()
   }
   
   // example of bad code. need review here
   private func loadFeedbackItems() {
      User.getFeedbackSnapShotData(for: userId,
                                   completion: { feedItems in
                                    if feedItems == nil { return }
                                    let sortedKeys = feedItems!.keys.sorted(by: {$0 > $1}) // order by date
                                    
                                    for key in sortedKeys {
                                       let value = feedItems![key] as? [String: Any]
                                       // what type of feedbacK?
                                       if value == nil { // this is not [string: any], so it is follower
                                          print("follower")
                                       } else {
                                          if let commentId = value!["commentId"] { // commentary
                                             print("commentary")
                                          }
                                          
                                          if let like = value!["likePlacedTime"] { // like
                                             print("like")
                                          }
                                       }
                                    }
      })
   }
   
   var haveWeFinishedLoading: Bool = false // bool value have we loaded feed or not. Mainly for DZNEmptyDataSet
   
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = UITableViewCell()
      
      return cell
   }
   
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return 0
   }
}

// MARK: - DZNEmptyDataSet for empty data tables
extension FeedbackController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
   func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
      if haveWeFinishedLoading {
         let str = "Welcome"
         let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
         return NSAttributedString(string: str, attributes: attrs)
      } else {
         let str = ""
         let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
         return NSAttributedString(string: str, attributes: attrs)
      }
   }
   
   func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
      if haveWeFinishedLoading {
         let str = "Nothing to show."
         let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
         return NSAttributedString(string: str, attributes: attrs)
      } else {
         let str = ""
         let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
         return NSAttributedString(string: str, attributes: attrs)
      }
   }
   
   func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
      if haveWeFinishedLoading {
         return Image.resize(UIImage(named: "no_photo.png")!, targetSize: CGSize(width: 300.0, height: 300.0))
      } else {
         return Image.resize(UIImage(named: "PleaseWaitTxt.gif")!, targetSize: CGSize(width: 300.0, height: 300.0))
      }
   }
}

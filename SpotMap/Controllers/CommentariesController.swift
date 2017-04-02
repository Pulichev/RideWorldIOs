//
//  CommentariesContoller.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 01.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import IGListKit
import FirebaseDatabase

class CommentariesController: UIViewController {
    var postId: String!
    
    var comments = [CommentItem]()
    
    let collectionView: IGListCollectionView = {
        let view = IGListCollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout())
        return view
    }()
    
    lazy var adapter: IGListAdapter = {
        return IGListAdapter(updater: IGListAdapterUpdater(), viewController: self, workingRangeSize: 0)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadComments()
        
        view.addSubview(collectionView)
        adapter.collectionView = collectionView
        adapter.dataSource = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.frame = view.bounds
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

// MARK: - IGListAdapterDataSource
extension CommentariesController: IGListAdapterDataSource {
    func loadComments() {
        let ref = FIRDatabase.database().reference(withPath: "MainDataBase/spotpost").child(self.postId).child("comments")
        
        ref.queryOrdered(byChild: "key").observe(.value, with: { snapshot in
            var newItems: [CommentItem] = []
            
            for item in snapshot.children {
                let commentItem = CommentItem(snapshot: item as! FIRDataSnapshot)
                newItems.append(commentItem)
            }
            
            self.comments = newItems
            self.adapter.reloadData(completion: nil)
        })
    }
    
    func objects(for listAdapter: IGListAdapter) -> [IGListDiffable] {
        var items = [IGListDiffable]()
        
        items = self.comments as [IGListDiffable]
        
        return items
    }
    
    func listAdapter(_ listAdapter: IGListAdapter, sectionControllerFor object: Any) -> IGListSectionController {
        return CommentariesSectionController()
    }
    
    func emptyView(for listAdapter: IGListAdapter) -> UIView? { return nil }
}

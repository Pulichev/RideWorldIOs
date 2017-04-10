//
//  CommentCell.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 02.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import FirebaseStorage
import FirebaseDatabase
import ActiveLabel

class CommentCell: UITableViewCell {
    @IBOutlet weak var userPhoto: UIImageView!
    @IBOutlet weak var userNickName: UIButton!
    @IBOutlet weak var commentText: ActiveLabel!
    @IBOutlet weak var date: UILabel!
    
    var comment: CommentItem! {
        didSet {
            self.commentText.text = self.comment.commentary
            let sourceDate = self.comment.datetime
            // Formatting date to yyyy-mm-dd
            let finalDate = sourceDate[sourceDate.startIndex..<sourceDate.index(sourceDate.startIndex, offsetBy: 16)]
            self.date.text = finalDate
            self.initialiseUserPhoto()
            self.initialiseUserButton()
            self.initializeCommentText()
        }
    }
    
    func initialiseUserPhoto() {
        self.userPhoto.layer.cornerRadius = self.userPhoto.frame.size.height / 2
        self.userPhoto.image = UIImage(named: "grayRec.jpg")
        
        let storage = FIRStorage.storage()
        let url = "gs://spotmap-e3116.appspot.com/media/userMainPhotoURLs/" + self.comment.userId + "_resolution90x90.jpeg"
        let riderPhotoURL = storage.reference(forURL: url)
        
        riderPhotoURL.downloadURL { (URL, error) in
            if let error = error {
                print("\(error)")
            } else {
                self.userPhoto.kf.setImage(with: URL) // Using kf for caching images.
            }
        }
    }
    
    func initialiseUserButton() {
        let ref = FIRDatabase.database().reference(withPath: "MainDataBase/users/").child(self.comment.userId)
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            let user = UserItem(snapshot: snapshot)
            self.userNickName.setTitle(user.login, for: .normal)
        })
    }
    
    func initializeCommentText() {
        self.commentText.numberOfLines = 0
        self.commentText.enabledTypes = [.mention, .hashtag, .url]
        self.commentText.textColor = .black
        self.commentText.mentionColor = .brown
        self.commentText.hashtagColor = .purple
    }
}

//
//  CommentsModel.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 11.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseDatabase

struct Comment {
   static var refToSpotPostsNode = FIRDatabase.database().reference(withPath: "MainDataBase/spotpost")
   
   // Function for loading comments for certain post
   static func loadList(for postId: String,
                        completion: @escaping (_ loadedComments: [CommentItem]) -> Void) {
      let ref = refToSpotPostsNode.child(postId).child("comments")
      
      ref.queryOrdered(byChild: "key").observeSingleEvent(of: .value, with: { snapshot in
         var newItems: [CommentItem] = []
         
         for item in snapshot.children {
            let commentItem = CommentItem(snapshot: item as! FIRDataSnapshot)
            newItems.append(commentItem)
         }
         
         newItems = newItems.sorted(by: { $0.commentId < $1.commentId })
         completion(newItems)
      })
   }
   
   static func add(for post: PostItem, withText text: String?,
                   completion: @escaping (_ loadedComment: CommentItem) -> Void) {
      let ref = FIRDatabase.database().reference(withPath: "MainDataBase")
      
      let refForNewCommentKey = refToSpotPostsNode.child(post.key).child("comments")
         .childByAutoId().key
      
      let currentUserId = User.getCurrentUserId()
      let currentDateTime = String(describing: Date())
      let newComment = CommentItem(refForNewCommentKey, currentUserId, post.key, text!, currentDateTime)
      
      getAllMentionedUsersIds(from: text!,
                              completion: { mentionedUserIds in
                                 var userIds = mentionedUserIds
                                 userIds.append(post.addedByUser) // adding post author
                                 
                                 var updates: [String: Any?] = ["/spotpost/" + post.key + "/comments/" + refForNewCommentKey: newComment.toAnyObject()]
                                 
                                 for userId in userIds {
                                    updates.updateValue(newComment.toAnyObject(), forKey: "/feedback/" + userId + "/" + refForNewCommentKey) //
                                 }
                                 
                                 ref.updateChildValues(updates,
                                                       withCompletionBlock: { (error, _) in
                                                            completion(newComment)
                                 })
      })
   }
   
   static private func getAllMentionedUsersIds(from text: String,
                                               completion: @escaping (_ userIds: [String]) -> Void) {
      let userLogins = getLinkedUsersFromText(text)
      
      var userIds = [String]()
      
      if userLogins.count == 0 { completion(userIds) } // created empty array
      
      var countOfProcessedUsers = 0
      
      for userLogin in userLogins {
         User.getItemByLogin(for: userLogin, completion: { user in
            countOfProcessedUsers += 1
            
            if user != nil {
               userIds.append(user!.uid)
            }
            
            if countOfProcessedUsers == userLogins.count {
               completion(userIds)
            }
         })
      }
   }
   
   static private func getLinkedUsersFromText(_ text: String) -> [String] {
      var userLogins = [String]()
      
      var words = text.components(separatedBy: " ")
      words = words.filter { $0 != "" }
      
      for word in words {
         if word[0] == "@" && word.characters.count >= 2 {
            userLogins.append(word[1..<word.characters.count + 1]) // removing @
         }
      }
      
      userLogins = String.uniqueElementsFrom(array: userLogins)
      
      return userLogins
   }
   
   static func remove(with id: String, from postId: String) {
      let refToComment = refToSpotPostsNode.child(postId).child("comments").child(id)
      
      refToComment.removeValue()
   }
}

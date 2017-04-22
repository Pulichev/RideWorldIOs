//  602660
//  User.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 03.03.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseDatabase

struct UserItem {
   let uid: String
   
   let email: String
   var login: String
   var bioDescription: String
   var nameAndSename: String
   let createdDate: String
   
   let ref: FIRDatabaseReference?
   
   init(uid: String, email: String, login: String,
        bioDescription: String = "", nameAndSename: String = "", createdDate: String) {
      self.uid = uid
      
      self.email = email
      self.login = login
      self.bioDescription = bioDescription
      self.nameAndSename = nameAndSename
      self.createdDate = createdDate
      
      self.ref = nil
   }
   
   init(snapshot: FIRDataSnapshot) {
      uid = snapshot.key
      
      let snapshotValue = snapshot.value as! [String: AnyObject]
      email = snapshotValue["email"] as! String
      login = snapshotValue["login"] as! String
      bioDescription = snapshotValue["bioDescription"] as! String
      nameAndSename = snapshotValue["nameAndSename"] as! String
      createdDate = snapshotValue["createdDate"] as! String
      
      ref = snapshot.ref
   }
   
   func toAnyObject() -> Any {
      return [
         "uid": uid,
         "email": email,
         "login": login,
         "bioDescription": bioDescription,
         "nameAndSename": nameAndSename,
         "createdDate": createdDate
      ]
   }
}

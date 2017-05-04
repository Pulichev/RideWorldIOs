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
   var bioDescription: String?
   var nameAndSename: String?
   let createdDate: String
   
   // photos refs
   var photo150ref: String?
   var photo90ref: String?
   
   let ref: FIRDatabaseReference?
   
   init(uid: String, email: String, login: String,
        bioDescription: String = "", nameAndSename: String = "", createdDate: String,
        photo150ref: String = "", photo90ref: String = "") {
      self.uid = uid
      
      self.email = email
      self.login = login
      self.bioDescription = bioDescription
      self.nameAndSename = nameAndSename
      self.createdDate = createdDate
      
      self.photo150ref = photo150ref
      self.photo90ref = photo90ref
      
      self.ref = nil
   }
   
   init(snapshot: FIRDataSnapshot) {
      uid = snapshot.key
      
      let snapshotValue = snapshot.value as! [String: AnyObject]
      email = snapshotValue["email"] as! String
      login = snapshotValue["login"] as! String
      bioDescription = snapshotValue["bioDescription"] as? String
      nameAndSename = snapshotValue["nameAndSename"] as? String
      createdDate = snapshotValue["createdDate"] as! String
      
      photo150ref = snapshotValue["photo150ref"] as? String
      photo90ref = snapshotValue["photo90ref"] as? String

      ref = snapshot.ref
   }
   
   func toAnyObject() -> Any {
      return [
         "uid": uid,
         "email": email,
         "login": login,
         "bioDescription": bioDescription,
         "nameAndSename": nameAndSename,
         "createdDate": createdDate,
         "photo150ref": photo150ref,
         "photo90ref": photo90ref
      ]
   }
}

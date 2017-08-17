//  602660
//  UserModel.swift
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
   
   // photos refs
   var photo150ref: String?
   var photo90ref: String?
   
   let ref: DatabaseReference?
   
   init(uid: String, email: String, login: String,
        bioDescription: String = "", nameAndSename: String = "",
        photo150ref: String = "", photo90ref: String = "") {
      self.uid = uid
      
      self.email = email
      self.login = login
      self.bioDescription = bioDescription
      self.nameAndSename = nameAndSename
      
      self.photo150ref = photo150ref
      self.photo90ref = photo90ref
      
      ref = nil
   }
   
   init(snapshot: DataSnapshot) {
      let snapshotValue = snapshot.value as! [String: AnyObject]
      uid = snapshotValue["uid"] as! String
      
      email = snapshotValue["email"] as! String
      login = snapshotValue["login"] as! String
      bioDescription = snapshotValue["bioDescription"] as? String
      nameAndSename = snapshotValue["nameAndSename"] as? String
      
      photo150ref = snapshotValue["photo150ref"] as? String
      photo90ref = snapshotValue["photo90ref"] as? String

      ref = snapshot.ref
   }
   
   init(_ userData: [String: Any]) {
      uid = userData["uid"] as! String
      
      email = userData["email"] as! String
      login = userData["login"] as! String
      bioDescription = userData["bioDescription"] as? String
      nameAndSename = userData["nameAndSename"] as? String
      
      photo150ref = userData["photo150ref"] as? String
      photo90ref = userData["photo90ref"] as? String
      
      ref = nil
   }
   
   func toAnyObject() -> Any {
      return [
         "uid": uid,
         
         "email": email,
         "login": login,
         "bioDescription": bioDescription,
         "nameAndSename": nameAndSename,
         
         "photo150ref": photo150ref,
         "photo90ref": photo90ref
      ]
   }
}

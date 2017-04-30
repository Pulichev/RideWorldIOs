//
//  DateTimeParser.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 29.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

struct DateTimeParser {
   static func getDate(from dateTime: String) -> String {
      let startIndex = dateTime.startIndex
      let endIndex = dateTime.index(dateTime.startIndex, offsetBy: 10)
      let finalDate = dateTime[startIndex..<endIndex]
      
      return finalDate
   }
   
   static func getTime(from dateTime: String) -> String {
      let startIndex = dateTime.index(dateTime.startIndex, offsetBy: 11)
      let endIndex = dateTime.index(dateTime.startIndex, offsetBy: 16)
      let finalTime = dateTime[startIndex..<endIndex]
      
      return finalTime
   }
   
   static func getDateTime(from dateTime: String) -> String {
      let startIndex = dateTime.startIndex
      let endIndex = dateTime.index(dateTime.startIndex, offsetBy: 16)
      let finalDateTime = dateTime[startIndex..<endIndex]
      
      return finalDateTime
   }
}

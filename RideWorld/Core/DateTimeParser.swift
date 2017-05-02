//
//  DateTimeParser.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 29.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

struct DateTimeParser {
   static func getDate(from dateTime: String) -> String {
      let dateInCurrentTimeZone = stringToDateInCurrentTimeZone(dateTime)
      let dateInCurrentTimeZoneString = String(describing: dateInCurrentTimeZone)

      let startIndex = dateInCurrentTimeZoneString.startIndex
      let endIndex = dateInCurrentTimeZoneString.index(dateInCurrentTimeZoneString.startIndex, offsetBy: 10)
      let finalDate = dateInCurrentTimeZoneString[startIndex..<endIndex]
      
      return finalDate
   }
   
   static func getTime(from dateTime: String) -> String {
      let dateInCurrentTimeZone = stringToDateInCurrentTimeZone(dateTime)
      let dateInCurrentTimeZoneString = String(describing: dateInCurrentTimeZone)

      let startIndex = dateInCurrentTimeZoneString.index(dateInCurrentTimeZoneString.startIndex, offsetBy: 11)
      let endIndex = dateInCurrentTimeZoneString.index(dateInCurrentTimeZoneString.startIndex, offsetBy: 16)
      let finalTime = dateInCurrentTimeZoneString[startIndex..<endIndex]

      return finalTime
   }
   
   static func getDateTime(from dateTime: String) -> String {
      let dateInCurrentTimeZone = stringToDateInCurrentTimeZone(dateTime)
      let dateInCurrentTimeZoneString = String(describing: dateInCurrentTimeZone)
      
      let startIndex = dateInCurrentTimeZoneString.startIndex
      let endIndex = dateTime.index(dateInCurrentTimeZoneString.startIndex, offsetBy: 16)
      let finalDateTime = dateInCurrentTimeZoneString[startIndex..<endIndex]
     
      return finalDateTime
   }
   
   static func stringToDateInCurrentTimeZone(_ str: String) -> Date {
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd HH:mm:ss +zzzz"
      let date = formatter.date(from: str)!
      let newDate = date.addingTimeInterval(TimeInterval(secondsFromGMT))
      
      return newDate
   }
   
   // unused atm
   static func dateToString(_ str: Date) -> String {
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss +zzzz"
      dateFormatter.timeStyle = DateFormatter.Style.short
      dateFormatter.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
      return dateFormatter.string(from: str)
   }
   
   static var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }
}

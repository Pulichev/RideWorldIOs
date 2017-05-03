//
//  DateTimeParser.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 29.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import DateToolsSwift

struct DateTimeParser {
   static func getDateTime(from dateTime: String) -> String {
      let dateInCurrentTimeZone = stringToDateInCurrentTimeZone(dateTime)
      let dateInCurrentTimeZoneString = dateInCurrentTimeZone.timeAgoSinceNow
      
      return dateInCurrentTimeZoneString
   }
   
   static func stringToDateInCurrentTimeZone(_ str: String) -> Date {
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd HH:mm:ss +zzzz"
      let date = formatter.date(from: str)!
      
      return date
   }
}

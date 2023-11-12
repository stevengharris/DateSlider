//
//  DateFormat.swift
//  DateSlider
//
//  Created by Steven Harris on 10/28/23.
//

import Foundation

public struct DateFormat {
    var dateStyle: DateFormatter.Style = .none
    var timeStyle: DateFormatter.Style = .none
    var timeZone: TimeZone? = nil
    
    var isShortDate: Bool { dateStyle == .short && timeStyle == .none }
    var isShortDateTime: Bool { dateStyle == .short && timeStyle == .short }
    
    static let shortDateUTC = DateFormat(dateStyle: .short, timeStyle: .none, timeZone: TimeZone(abbreviation: "UTC"))
    static let shortDateTimeUTC = DateFormat(dateStyle: .short, timeStyle: .short, timeZone: TimeZone(abbreviation: "UTC"))
    
    static let shortDateLocal = DateFormat(dateStyle: .short, timeStyle: .none, timeZone: nil)
    static let shortDateTimeLocal = DateFormat(dateStyle: .short, timeStyle: .short, timeZone: nil)
}

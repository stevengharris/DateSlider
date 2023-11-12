//
//  DateFormat.swift
//  DateSlider
//
//  Created by Steven Harris on 10/28/23.
//

import Foundation

public struct DateFormat {
    public var dateStyle: DateFormatter.Style = .none
    public var timeStyle: DateFormatter.Style = .none
    public var timeZone: TimeZone? = nil
    
    public var isShortDate: Bool { dateStyle == .short && timeStyle == .none }
    public var isShortDateTime: Bool { dateStyle == .short && timeStyle == .short }
    
    public static let shortDateUTC = DateFormat(dateStyle: .short, timeStyle: .none, timeZone: TimeZone(abbreviation: "UTC"))
    public static let shortDateTimeUTC = DateFormat(dateStyle: .short, timeStyle: .short, timeZone: TimeZone(abbreviation: "UTC"))
    
    public static let shortDateLocal = DateFormat(dateStyle: .short, timeStyle: .none, timeZone: nil)
    public static let shortDateTimeLocal = DateFormat(dateStyle: .short, timeStyle: .short, timeZone: nil)
}

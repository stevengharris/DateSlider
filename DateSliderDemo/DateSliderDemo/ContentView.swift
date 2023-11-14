//
//  ContentView.swift
//  DateSliderDemo
//
//  Created by Steven Harris on 11/14/23.
//

import SwiftUI
import DateSlider

struct ContentView: View {
    
    struct DatedString: DatedObject {
        var date: Date
        var string: String
    }
    
    let dates = [
        Date(),
        Date().addingTimeInterval(100000),
        Date().addingTimeInterval(200000),
    ]
    
    let datedStrings: [DatedString] = [
        DatedString(date: Date(), string: "foo"),
        DatedString(date: Date().addingTimeInterval(100000), string: "bar"),
        DatedString(date: Date().addingTimeInterval(200000), string: "baz"),
    ]
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                DateSliderView(datedObjects: dates, format: .shortDateLocal, onDateSelect: dateSelected(_:))
                    .frame(width: geometry.size.width, height: 30)
                DateSliderView(datedObjects: datedStrings, format: .shortDateTimeLocal, onDateSelect: dateSelected(_:))
                    .frame(width: geometry.size.width, height: 30)
                Spacer()
            }
        }
        .padding()
    }
    
    func dateSelected(_ date: Date) {
        print("Selected \(date)")
    }
}

#Preview {
    ContentView()
}

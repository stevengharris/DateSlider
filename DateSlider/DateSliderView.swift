//
//  DateSliderView.swift
//  DateSlider
//
//  Created by Steven Harris on 10/24/23.
//

import SwiftUI

public struct DateSliderView: View {
    public typealias T = any DatedObjectCollection
    
    /// Whether the order for the `datedObjects` and `boundedDatedObjects` was specified as `.orderedAscending`.
    let ascendingOrder: Bool
    /// The format for for a string represenation of `draggingDate`.
    let format: DateFormat
    
    /// The index of the DatedObject that is currently selected, which changes when dragging ends.
    @Binding private var selectedDateIndex: Int
    
    /// All datedObjects that can be selected-from. Large DatedObjectCollections should use OrderedSet so that
    /// selections by date are O(1) and identifying the nearest date to the slider position is not O(n).
    @State private var datedObjects: T
    /// Simplify access to datedObjects.startIndex, which never changes.
    @State private var firstDateIndex: Int
    /// Simplify access to datedObjects.endIndex - 1, which never changes.
    @State private var lastDateIndex: Int
    /// The index of the first DatedObject within `boundedDatedObjects`, may change during `zoomIn` and `zoomOut`.
    @State private var leadingDateIndex: Int
    /// The index of the last DatedObject within `boundedDatedObjects`, may change during `zoomIn` and `zoomOut`.
    @State private var trailingDateIndex: Int
    /// The date that the slider is positioned-at, not necessarily the same as `selectedDate`.
    @State private var draggingDate: Date
    /// The index of the DatedObject shown in the slider label, which is where it will snap-to when released.
    @State private var sliderDateIndex: Int
    /// The previous location.x of the drag point, used to allow smooth drag from the pointer position.
    @State private var previousPosition: CGFloat?
    
    /// A subsequence of `datedObjects` starting with `leadingDate` and ending with `trailingDate`.
    var boundedDatedObjects: T {
        if datedObjects.count > 1 {
            return datedObjects[leadingDateIndex...trailingDateIndex] as! T
        } else {
            return datedObjects
        }
    }
    /// The date of the first DatedObject in `boundedDatedObjects`.
    var leadingDate: Date { datedObjects[leadingDateIndex].date }
    /// The date of the last DatedObject in `boundedDatedObjects`.
    var trailingDate: Date { datedObjects[trailingDateIndex].date }
    /// The date of the selected DatedObject in `boundedDatedObjects`.
    var selectedDate: Date { datedObjects[selectedDateIndex].date }
    /// The date shown in the slider label, which is where it will snap-to when released.
    var sliderDate: Date { datedObjects[sliderDateIndex].date }
    
    public var body: some View {
        //let _ = Self._printChanges()
        HStack {
            // The toolbar to move the date and zoom in/out
            HStack(spacing: 4) {
                Button(
                    action: zoomOut,
                    label: { Image(systemName: "minus.magnifyingglass") }
                )
                .disabled(leadingDateIndex == firstDateIndex && trailingDateIndex == lastDateIndex)
                Button(
                    action: moveToLeading,
                    label: { Image(systemName: "backward.end") }
                )
                .disabled(selectedDateIndex == firstDateIndex)
                Button(
                    action: moveTowardLeading,
                    label: { Image(systemName: "arrowtriangle.backward") }
                )
                .disabled(selectedDateIndex == nextDateIndexTowardLeading(from: selectedDateIndex))
                Button(
                    action: moveTowardTrailing,
                    label: { Image(systemName: "arrowtriangle.forward") }
                )
                .disabled(selectedDateIndex == nextDateIndexTowardTrailing(from: selectedDateIndex))
                Button(
                    action: moveToTrailing,
                    label: { Image(systemName: "forward.end") }
                )
                .disabled(selectedDateIndex == lastDateIndex)
                Button(
                    action: zoomIn,
                    label: { Image(systemName: "plus.magnifyingglass") }
                )
                .disabled(boundedDatedObjects.count < 4)    // Stop the madness
            }
            Divider()
            // Where all the fun takes place: a bar that shows tick marks at each date
            // (altho limited to a reasonable number of ticks based on the width), and
            // a slider label that shows the selected date but stays within the width
            // of the bar.
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                let tickOffsets = tickOffsets(in: width)
                let sliderWidth = sliderWidth()
                // This is the view you slide a slider across to select a date.
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: width)
                        .border(barBorder())
                        .foregroundColor(barForeground())
                        .zIndex(0)
                    // Place a tick mark at each date, but filter for large date sets.
                    // The active tick, which is what is identified by its date in the
                    // label, is colored the same as the label border and thicker than
                    // the other ticks, and extends above the bar.
                    ForEach(tickOffsets.indices, id: \.self) { index in
                        let offset = tickOffsets[index]
                        let active = tickIsActive(at: offset, in: width)
                        let tickColor = tickColor(active)
                        let tickWidth = tickWidth(active)
                        let tickHeight = active ? height + 2 : height
                        let tickX = offset
                        let tickY = active ? height / 2 - 1 : height / 2
                        RoundedRectangle(cornerRadius: 1).frame(width: tickWidth, height: tickHeight)
                            .position(x: tickX, y: tickY)
                            .foregroundColor(tickColor)
                            .zIndex(active ? 1.1 : 1)   // Active is on top of other ticks
                    }
                    // The slider is a label that is offset to that it always remains within the
                    // rectangle. It will generally sit over the top of the selected date, except
                    // while it's sliding, the highlighted tick mark may be outside of it before
                    // it snaps to position.
                    if boundedDatedObjects.count > 1 {
                        Color.clear.contentShape(Rectangle())
                            .frame(width: sliderWidth)
                            .offset(x: sliderWidth / 2)
                            .overlay {
                                // The date label offset starts at half of the slider width when at
                                // the leading edge, will reach zero at the middle, and minus half
                                // the slider width on the trailing edge.
                                Label(format(sliderDate), image: "calendar")
                                    .frame(width: sliderWidth)
                                    .labelStyle(.titleOnly)
                                    .background(sliderBackground())
                                    .cornerRadius(2)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 2)
                                            .strokeBorder(tickColor(true), lineWidth: 1, antialiased: true)
                                    )
                                    .offset(x: labelOffset(sliderWidth: sliderWidth, in: width))
                            }
                            .zIndex(2)
                            .position(CGPoint(x: offset(from: draggingDate, in: width), y: geometry.size.height / 2))
                            .gesture(drag(in: width))
                    }
                }
            }
        }
    }
    
    /// Initialize the DateSliderView with the `datedObjects` it holds, the index into those datedObjects it should point to, and the `format`.
    ///
    /// Note that the way to update the DateSliderView is to replace it via its `id` in the containing view. Otherwise, the underlying
    /// DatedObjectsCollection would need to be equatable to cause a change, and while it very well might be equatable, you probably
    /// for example, don't want this view to update based on whether every datedObject is == and in the same order. Far better for the
    /// containing view which has the context for what's in this one make the decision about whether the `id` changes.
    public init(datedObjects: T, datedObjectsIndex: Binding<Int>, format: DateFormat) {
        _datedObjects = State(initialValue: datedObjects)
        _selectedDateIndex = datedObjectsIndex
        self.format = format
        ascendingOrder = (datedObjects.first?.date ?? Date()) < (datedObjects.last?.date ?? Date().addingTimeInterval(1))
        let startIndex = datedObjects.startIndex
        let endIndex = max(datedObjects.startIndex, datedObjects.endIndex - 1)
        _firstDateIndex = State(initialValue: startIndex)
        _lastDateIndex = State(initialValue: endIndex)
        _leadingDateIndex = State(initialValue: startIndex)
        _trailingDateIndex = State(initialValue: endIndex)
        _draggingDate = State(initialValue: datedObjects.isEmpty ? Date() : datedObjects[datedObjectsIndex.wrappedValue].date)
        _sliderDateIndex = State(initialValue: datedObjectsIndex.wrappedValue)
    }
    
    //MARK: Colors
    
    @ViewBuilder
    func sliderBackground() -> Color {
        #if os(macOS)
        Color(.windowBackgroundColor)
        #else
        Color(uiColor: .systemBackground)
        #endif
    }
    
    @ViewBuilder
    func barForeground() -> Color {
        #if os(macOS)
        Color(.lightGray)
        #else
        Color(uiColor: .lightGray)
        #endif
    }
    
    @ViewBuilder
    func barBorder() -> Color {
        #if os(macOS)
        Color(.darkGray)
        #else
        Color(uiColor: .darkGray)
        #endif
    }
    
    /// Return a color to use for the tick based on whether it is active or not.
    @ViewBuilder
    func tickColor(_ active: Bool) -> Color {
        active ? Color.accentColor : barBorder()
    }
    
    //MARK: Dragging
    
    /// Return the DragGesture that executes when the slider is dragged and when dragging stops.
    private func drag(in width: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { gesture in
                // Use gesture translation from the place where drag starts
                let location = gesture.location.x
                var newOffset: CGFloat
                if previousPosition == nil {
                    let delta = gesture.translation.width
                    newOffset = offset(from: selectedDate, in: width) + delta
                } else {
                    let delta = location - previousPosition!
                    newOffset = offset(from: draggingDate, in: width) + delta
                }
                previousPosition = location
                let dateOffset = max(0, min(newOffset, width))
                draggingDate = date(from: dateOffset, in: width)        // A "raw" date based on position
                sliderDateIndex = dateIndexNearest(to: draggingDate)    // The index that is closest to draggingDate
            }
            .onEnded { gesture in
                previousPosition = nil
                setDateIndex(sliderDateIndex)
            }
    }
    
    /// Update all the indices and dates to be consistent for `index`.
    func setDateIndex(_ index: Int) {
        let date = datedObjects[index].date
        selectedDateIndex = index
        draggingDate = date
        sliderDateIndex = index
    }
    
    //MARK: Conversions in width
    
    /// Return the amount to offset the label that floats over of the pointer to the date.
    ///
    /// The offset is half of the slider width when the `dateOffset` is zero, reaches zero
    /// when `dateOffset` is at the halfway point, and minus half of the slider width
    /// when `dateOffset` is width.
    private func labelOffset(sliderWidth: CGFloat, in width: CGFloat) -> CGFloat {
        let halfWidth = width / 2
        let dateOffset = offset(from: draggingDate, in: width)
        let offsetFromCenter = halfWidth - dateOffset   // + on leading, - on trailing
        let fraction = offsetFromCenter / halfWidth
        return sliderWidth / 2 * fraction
    }
    
    /// Return the offset of `date` from the leading edge of `width` where `width` extends from `leadingDate` to `trailingDate`.
    func offset(from date: Date, in width: CGFloat) -> CGFloat {
        let totalSpan = trailingDate.timeIntervalSince(leadingDate)
        let dateSpan = date.timeIntervalSince(leadingDate)
        return width * (dateSpan / totalSpan)
    }
    
    /// Return the Date that corresponds to an offset position from the leading edge of `width`.
    func date(from offset: CGFloat, in width: CGFloat) -> Date {
        let totalSpan = trailingDate.timeIntervalSince(leadingDate)
        let offsetInterval = totalSpan * offset / width
        return leadingDate.addingTimeInterval(offsetInterval)
    }
    
    //MARK: Utilities
    
    /// Return a string formatted according to the settings in `format`.
    func format(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = format.dateStyle
        formatter.timeStyle = format.timeStyle
        if format.timeZone != nil { formatter.timeZone = format.timeZone! }
        return formatter.string(from: date)
    }
    
    /// Return the slider width based on the `format`.
    func sliderWidth() -> CGFloat {
        if format.isShortDate {
            return 74
        } else if format.isShortDateTime {
            return 136
        } else {
            return 74
        }
    }
    
    //MARK: Ticks
    
    /// Return an array of offsets between `leadingDate` and `trailingDate`whose size
    /// is tailored to width.
    ///
    /// The `tickOffsets` indicate where to put tick marks in the view, indicating where an item
    /// in `boundedDatedObjects` is positioned across `width`. Because there might be many DatedObjects, but
    /// they can only really show up in a one-pixel size across `width`, we limit the size of `tickOffsets`
    /// so that the actual views that are created from `tickOffsets` are limited in size to something
    /// that is appropriate.
    ///
    /// FWIW, this method is written to be somewhat more efficient than a `reduce` equivalent that uses
    /// a Set (or OrderedSet) to filter out dups as `boundedDatedObjects` get squashed into `width` like:
    ///
    ///     boundedDatedObjects.reduce(into: OrderedSet<CGFloat>()) { offsets, datedObject in
    ///         offsets.append(offset(from: datedObject.date, in: width).rounded(.towardZero))
    ///     }
    ///
    /// If we want to show ticks, then there isn't going to be any way to avoid an O(n) traversal of a potentially
    /// large `boundedDatedObjects`.
    func tickOffsets(in width: CGFloat) -> [CGFloat] {
        let roundWidth = width.rounded(.towardZero)
        let previousDate = boundedDatedObjects.first?.date
        var previousOffset = previousDate == nil ? 0 : offset(from: previousDate!, in: roundWidth).rounded(.towardZero)
        var offsets: [CGFloat] = []
        for index in boundedDatedObjects.indices {
            let nextOffset = offset(from: boundedDatedObjects[index].date, in: roundWidth).rounded(.towardZero)
            if nextOffset > previousOffset {
                offsets.append(nextOffset)
                previousOffset = nextOffset
                if nextOffset >= roundWidth { break }
            }
        }
        return offsets
    }
    
    /// Return true if the tick at `offset` corresponds to the offset of `sliderDate`.
    func tickIsActive(at offset: CGFloat, in width: CGFloat) -> Bool {
        let sliderDateOffset = self.offset(from: sliderDate, in: width).rounded(.towardZero)
        let active = offset.rounded(.towardZero) == sliderDateOffset
        return active
    }
    
    /// Return the width for the tick based on whether it is active or not.
    func tickWidth(_ active: Bool) -> CGFloat {
        active ? 2 : 1
    }
    
    /// Given the `index`, return the index that is toward the `leadingDateIndex` within `boundedDatedObjects`.
    ///
    /// Specify `bounded: false` to use `datedObjects` instead of `boundedDatedObjects`.
    func nextDateIndexTowardLeading(from index: Int, bounded: Bool = true) -> Int {
        if bounded {
            guard index > boundedDatedObjects.startIndex else { return index }
            return index - 1
        } else {
            guard index > datedObjects.startIndex else { return index }
            return index - 1
        }
    }
  
    /// Given the `index`, return the index that is toward the `trailingDateIndex` within `boundedDatedObjects`.
    ///
    /// Specify `bounded: false` to use `datedObjects` instead of `boundedDatedObjects`.
    func nextDateIndexTowardTrailing(from index: Int, bounded: Bool = true) -> Int {
        if bounded {
            guard index < boundedDatedObjects.endIndex - 1 else { return index }
            return index + 1
        } else {
            guard index < datedObjects.endIndex - 1 else { return index }
            return index + 1
        }
    }
    
    /// Return the index in either `boundedDatedObjects`of the DatedObject whose date that is closest-to or equal-to `date`.
    ///
    /// Specify `bounded: false` to use `datedObjects` instead of `boundedDatedObjects`.
    ///
    /// Note we use a binary search as a quick way to get the index in an OrderedSet.
    func indexTowardTrailing(of date: Date, bounded: Bool = true) -> Int {
        if ascendingOrder {
            if bounded {
                return boundedDatedObjects.bisectToFirstIndex(where: { $0.date >= date }) ?? boundedDatedObjects.endIndex - 1
            } else {
                return datedObjects.bisectToFirstIndex(where: { $0.date >= date }) ?? datedObjects.endIndex - 1
            }
        } else {
            if bounded {
                return boundedDatedObjects.bisectToFirstIndex(where: { $0.date <= date }) ?? boundedDatedObjects.endIndex - 1
            } else {
                return datedObjects.bisectToFirstIndex(where: { $0.date <= date }) ?? datedObjects.endIndex - 1
            }
        }
    }
    
    /// Return the index of the DatedObject in either `boundedDatedObjects` or `datedObjects`whose date is closest to `date`.
    ///
    /// Specify `bounded: false` to use `datedObjects` instead of `boundedDatedObjects`.
    func dateIndexNearest(to date: Date, bounded: Bool = true) -> Int {
        let t = indexTowardTrailing(of: date, bounded: bounded)
        let l = max(bounded ? boundedDatedObjects.startIndex : firstDateIndex, t - 1)
        let leading = datedObjects[l]
        let trailing = datedObjects[t]
        let leadingDelta = abs(date.timeIntervalSince(leading.date))
        let trailingDelta = abs(date.timeIntervalSince(trailing.date))
        return leadingDelta < trailingDelta ? l : t
    }
    
    //MARK: Actions
    
    /// Change the slider to be at the `leadingDate` (i.e., the date of the first DatedObject within `boundedDatedObjects`).
    func moveToLeading() {
        setDateIndex(leadingDateIndex)
    }
    
    /// Change the slider to be at the `trailingDate` (i.e., the date of the last DatedObject within `boundedDatedObjects`).
    func moveToTrailing() {
        setDateIndex(trailingDateIndex)
    }
    
    /// Change the slider to be at the date before the `selectedDate` within `boundedDatedObjects`.
    func moveTowardLeading() {
        setDateIndex(nextDateIndexTowardLeading(from: selectedDateIndex))
    }
    
    /// Change the slider to be at the date after the `selectedDate` within `boundedDatedObjects`.
    func moveTowardTrailing() {
        setDateIndex(nextDateIndexTowardTrailing(from: selectedDateIndex))
    }
    
    /// Zoom in at the `selectedDate`, always leaving the `selectedDate` visible.
    ///
    /// While we zoom in nominally based on a factor of 2 (i.e., go in from leading and trailing by 1/4), the
    /// `leadingDate` and `trailingDate` are actual dates found in `boundedDatedObjects`.
    /// This way the timeline is always anchored at either end by a date found in `boundedDatedObjects`, like it
    /// starts out, not just some arbitrary date based on zooming in and out.
    func zoomIn() {
        // By accounting for order, `*Increment` is always positive
        if ascendingOrder {
            let leadingIncrement = selectedDate.timeIntervalSince(leadingDate) / 4
            let trailingIncrement = trailingDate.timeIntervalSince(selectedDate) / 4
            leadingDateIndex = dateIndexNearest(to: leadingDate.addingTimeInterval(leadingIncrement))
            trailingDateIndex = dateIndexNearest(to: trailingDate.addingTimeInterval(-trailingIncrement))
        } else {
            let leadingIncrement = leadingDate.timeIntervalSince(selectedDate) / 4
            let trailingIncrement = selectedDate.timeIntervalSince(trailingDate) / 4
            leadingDateIndex = dateIndexNearest(to: leadingDate.addingTimeInterval(-leadingIncrement))
            trailingDateIndex = dateIndexNearest(to: trailingDate.addingTimeInterval(trailingIncrement))
        }
    }
    
    /// Zoom out at the `selectedDate`, always leaving the `selectedDate` visible and staying between
    /// first date and last date of the `datedObjects`.
    ///
    /// Unlike `zoomIn`, when we `zoomOut`, we have to find the new endpoint from `datedObjects`, not
    /// `boundedDatedObjects`. So, we pass `bounded: false` to `dateIndexNearest(to:bounded:)`.
    ///
    /// While we zoom out nominally based on a factor of 2 (i.e., go out from leading and trailing by 1/3), the
    /// `leadingDate` and `trailingDate` are actual dates  found in `datedObjects`.
    /// This way the timeline is always anchored at either end by a date found in `datedObjects`, like it
    /// starts out, not just some arbitrary date based on zooming in and out.
    func zoomOut() {
        // By accounting for order, `*Increment` is always positive
        if ascendingOrder {
            let leadingIncrement = selectedDate.timeIntervalSince(leadingDate) / 3
            let trailingIncrement = trailingDate.timeIntervalSince(selectedDate) / 3
            var newLeadingDateIndex = dateIndexNearest(to: leadingDate.addingTimeInterval(-leadingIncrement), bounded: false)
            if newLeadingDateIndex == leadingDateIndex {  // The nearestDateIndex can sometimes not change
                newLeadingDateIndex = nextDateIndexTowardLeading(from: leadingDateIndex, bounded: false)
            }
            leadingDateIndex = newLeadingDateIndex
            var newTrailingDateIndex = dateIndexNearest(to: trailingDate.addingTimeInterval(trailingIncrement), bounded: false)
            if newTrailingDateIndex == trailingDateIndex {  // The nearestDateIndex can sometimes not change
                newTrailingDateIndex = nextDateIndexTowardTrailing(from: trailingDateIndex, bounded: false)
            }
            trailingDateIndex = newTrailingDateIndex
        } else {
            let leadingIncrement = leadingDate.timeIntervalSince(selectedDate) / 3
            let trailingIncrement = selectedDate.timeIntervalSince(trailingDate) / 3
            var newLeadingDateIndex = dateIndexNearest(to: leadingDate.addingTimeInterval(leadingIncrement), bounded: false)
            if newLeadingDateIndex == leadingDateIndex {  // The nearestDateIndex can sometimes not change
                newLeadingDateIndex = nextDateIndexTowardLeading(from: leadingDateIndex, bounded: false)
            }
            leadingDateIndex = newLeadingDateIndex
            var newTrailingDateIndex = dateIndexNearest(to: trailingDate.addingTimeInterval(-trailingIncrement), bounded: false)
            if newTrailingDateIndex == trailingDateIndex {  // The nearestDateIndex can sometimes not change
                newTrailingDateIndex = nextDateIndexTowardTrailing(from: trailingDateIndex, bounded: false)
            }
            trailingDateIndex = newTrailingDateIndex
        }
    }

}

//struct DateSliderView_Previews: PreviewProvider {
//
//    static var previews: some View {
//        let dates = [
//            Date(),
//            Date().addingTimeInterval(100000),
//            Date().addingTimeInterval(200000),
//        ]
//        DateSliderView(datedObjects: dates, format: DateFormat.shortDateTimeLocal)
//    }
//
//}

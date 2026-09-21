import Foundation

enum CalendarRules {
    static func daysUntilPayday(_ payday: Int, from date: Date = .now, calendar: Calendar = .current) -> Int {
        let today = calendar.startOfDay(for: date)
        var next = paydayDate(payday, inMonthOf: today, calendar: calendar)
        if next < today, let nextMonth = calendar.date(byAdding: .month, value: 1, to: today) {
            next = paydayDate(payday, inMonthOf: nextMonth, calendar: calendar)
        }
        return calendar.dateComponents([.day], from: today, to: next).day ?? 0
    }

    // เดือนที่ไม่มีวันที่ตั้งไว้ (เช่น 31 ในเดือน ก.พ.) ใช้วันสุดท้ายของเดือนแทน
    private static func paydayDate(_ payday: Int, inMonthOf date: Date, calendar: Calendar) -> Date {
        let daysInMonth = calendar.range(of: .day, in: .month, for: date)?.count ?? 28
        var components = calendar.dateComponents([.year, .month, .era], from: date)
        components.day = min(payday, daysInMonth)
        return calendar.date(from: components) ?? date
    }

    // เทศกาลกินเจ = วันที่ 1–9 เดือน 9 ตามปฏิทินจีน (ไม่นับเดือน 9 ที่เป็นเดือนแทรก)
    static func jayFestivalDay(on date: Date = .now) -> Int? {
        let components = Calendar(identifier: .chinese).dateComponents([.month, .day], from: date)
        guard components.month == 9, components.isLeapMonth != true,
              let day = components.day, (1...9).contains(day) else { return nil }
        return day
    }

    static func nextJayFestival(from date: Date = .now) -> ClosedRange<Date>? {
        let calendar = Calendar(identifier: .gregorian)
        var day = calendar.startOfDay(for: date)
        var start: Date?
        for _ in 0..<420 {
            if jayFestivalDay(on: day) != nil {
                if start == nil { start = day }
            } else if let start {
                return start...calendar.date(byAdding: .day, value: -1, to: day)!
            }
            day = calendar.date(byAdding: .day, value: 1, to: day)!
        }
        return nil
    }

    static func gregorianYear(of date: Date = .now) -> Int {
        Calendar(identifier: .gregorian).component(.year, from: date)
    }
}

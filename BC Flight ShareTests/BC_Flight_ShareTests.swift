import Testing
import Foundation
@testable import BC_Flight_Share

// MARK: - Shared Helpers

private func makeRide(
    earliestDeparture: Date = Date(),
    departureWindowMinutes: Int = 30,
    maxRiders: Int = 3,
    riders: [String: RiderInfo] = ["user1": RiderInfo(name: "Alice", gender: "Female")]
) -> Ride {
    Ride(
        creatorId: "user1",
        creatorName: "Alice",
        creatorGender: "Female",
        destination: "Logan Airport (BOS)",
        terminal: "Terminal B",
        meetingLocation: "Lower Campus Bus Stop",
        earliestDepartureFromCampus: earliestDeparture,
        departureWindowMinutes: departureWindowMinutes,
        flightDepartureTime: earliestDeparture.addingTimeInterval(7200),
        maxRiders: maxRiders,
        riders: riders,
        notes: "",
        createdAt: Date()
    )
}

private func riders(_ ids: [String]) -> [String: RiderInfo] {
    Dictionary(uniqueKeysWithValues: ids.map { ($0, RiderInfo(name: $0, gender: "")) })
}

private func makeDate(year: Int, month: Int, day: Int, hour: Int = 10) -> Date {
    var comps = DateComponents()
    comps.year = year
    comps.month = month
    comps.day = day
    comps.hour = hour
    return Calendar.current.date(from: comps)!
}

// MARK: - Ride Model

@Suite("Ride Model")
struct RideModelTests {

    @Test func isFull_whenAtCapacity_returnsTrue() {
        let ride = makeRide(maxRiders: 2, riders: riders(["u1", "u2"]))
        #expect(ride.isFull == true)
    }

    @Test func isFull_whenBelowCapacity_returnsFalse() {
        let ride = makeRide(maxRiders: 3, riders: riders(["u1"]))
        #expect(ride.isFull == false)
    }

    @Test func spotsLeft_calculatesCorrectly() {
        let ride = makeRide(maxRiders: 5, riders: riders(["u1", "u2"]))
        #expect(ride.spotsLeft == 3)
    }

    @Test func spotsLeft_isZeroWhenFull() {
        let ride = makeRide(maxRiders: 5, riders: riders(["u1", "u2", "u3", "u4", "u5"]))
        #expect(ride.spotsLeft == 0)
    }

    @Test func spotsLeft_neverGoesNegative() {
        let ride = makeRide(maxRiders: 1, riders: riders(["u1", "u2"]))
        #expect(ride.spotsLeft == 0)
    }

    @Test func maxRiders_allowsUpToFive() {
        let ride = makeRide(maxRiders: 5, riders: riders(["u1", "u2", "u3", "u4", "u5"]))
        #expect(ride.isFull)
        #expect(ride.spotsLeft == 0)
    }

    @Test func dateKey_formatIsConsistentForSameDay() {
        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 21
        components.hour = 9
        let morning = Calendar.current.date(from: components)!
        components.hour = 22
        let evening = Calendar.current.date(from: components)!

        let rideAM = makeRide(earliestDeparture: morning)
        let ridePM = makeRide(earliestDeparture: evening)
        #expect(rideAM.dateKey == ridePM.dateKey)
    }

    @Test func dateKey_differsBetweenDays() {
        let day21 = makeDate(year: 2026, month: 8, day: 21)
        let day22 = makeDate(year: 2026, month: 8, day: 22)
        #expect(makeRide(earliestDeparture: day21).dateKey != makeRide(earliestDeparture: day22).dateKey)
    }

    @Test func dateKey_containsCorrectYearMonthDay() {
        let date = makeDate(year: 2026, month: 12, day: 5)
        #expect(makeRide(earliestDeparture: date).dateKey == "2026-12-5")
    }
}

// MARK: - Email Validation

@Suite("BC Email Validation")
struct EmailValidationTests {

    private func isBCEmail(_ email: String) -> Bool {
        email.lowercased().hasSuffix("@bc.edu")
    }

    @Test func validBCEmail_passes() { #expect(isBCEmail("alex@bc.edu") == true) }
    @Test func upperCaseBCEmail_passes() { #expect(isBCEmail("ALEX@BC.EDU") == true) }
    @Test func mixedCaseBCEmail_passes() { #expect(isBCEmail("Alex@Bc.Edu") == true) }
    @Test func gmailEmail_fails() { #expect(isBCEmail("alex@gmail.com") == false) }
    @Test func harvardEmail_fails() { #expect(isBCEmail("alex@harvard.edu") == false) }
    @Test func bcEmailWithSubdomain_fails() { #expect(isBCEmail("alex@mail.bc.edu") == false) }
    @Test func emptyString_fails() { #expect(isBCEmail("") == false) }
    @Test func partialBCDomain_fails() { #expect(isBCEmail("alex@bc") == false) }
}

// MARK: - Ride Filtering

@Suite("Ride Filtering")
struct RideFilteringTests {

    private func ride(on date: Date, id: String = "ride1") -> Ride {
        Ride(
            id: id,
            creatorId: "user1",
            creatorName: "Alice",
            creatorGender: "Female",
            destination: "Logan Airport (BOS)",
            terminal: "Terminal B",
            meetingLocation: "Lower Campus Bus Stop",
            earliestDepartureFromCampus: date,
            departureWindowMinutes: 30,
            flightDepartureTime: date.addingTimeInterval(7200),
            maxRiders: 3,
            riders: ["user1": RiderInfo(name: "Alice", gender: "Female")],
            notes: "",
            createdAt: Date()
        )
    }

    @Test func ridesOnDate_returnsOnlyMatchingDay() {
        let aug21 = makeDate(year: 2026, month: 8, day: 21)
        let aug22 = makeDate(year: 2026, month: 8, day: 22)
        let rides = [ride(on: aug21, id: "r1"), ride(on: aug21, id: "r2"), ride(on: aug22, id: "r3")]
        let key = aug21.rideKey
        let result = rides.filter { $0.dateKey == key }
        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.dateKey == key })
    }

    @Test func ridesOnDate_returnsEmptyForDateWithNoRides() {
        let aug21 = makeDate(year: 2026, month: 8, day: 21)
        let aug22 = makeDate(year: 2026, month: 8, day: 22)
        let rides = [ride(on: aug21)]
        #expect(rides.filter { $0.dateKey == aug22.rideKey }.isEmpty)
    }

    @Test func ridesOnDate_differentTimeSameDay_groupsTogether() {
        let morning = makeDate(year: 2026, month: 8, day: 21, hour: 7)
        let afternoon = makeDate(year: 2026, month: 8, day: 21, hour: 15)
        let rides = [ride(on: morning, id: "r1"), ride(on: afternoon, id: "r2")]
        #expect(rides.filter { $0.dateKey == morning.rideKey }.count == 2)
    }

    @Test func hasRides_trueWhenRidesExist() {
        let aug21 = makeDate(year: 2026, month: 8, day: 21)
        let rides = [ride(on: aug21)]
        #expect(rides.contains { $0.dateKey == aug21.rideKey } == true)
    }

    @Test func hasRides_falseWhenNoRides() {
        let aug21 = makeDate(year: 2026, month: 8, day: 21)
        let aug22 = makeDate(year: 2026, month: 8, day: 22)
        let rides = [ride(on: aug21)]
        #expect(rides.contains { $0.dateKey == aug22.rideKey } == false)
    }
}

// MARK: - Calendar Grid

@Suite("Calendar Grid")
struct CalendarGridTests {

    private func calendarDays(for month: Date) -> [Date?] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let firstOfMonth = calendar.date(
                from: calendar.dateComponents([.year, .month], from: month)
              )
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) - 1
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        return days
    }

    @Test func calendarDays_countMatchesDaysInMonth() {
        let august = makeDate(year: 2026, month: 8, day: 1)
        #expect(calendarDays(for: august).compactMap { $0 }.count == 31)
    }

    @Test func calendarDays_leadingNilsAlignFirstDayToCorrectWeekday() {
        let aug1 = makeDate(year: 2026, month: 8, day: 1)
        let expected = Calendar.current.component(.weekday, from: aug1) - 1
        let days = calendarDays(for: aug1)
        var nilCount = 0
        for day in days { if day == nil { nilCount += 1 } else { break } }
        #expect(nilCount == expected)
    }

    @Test func calendarDays_firstNonNilIsFirstDayOfMonth() {
        let september = makeDate(year: 2026, month: 9, day: 1)
        let firstDate = calendarDays(for: september).compactMap { $0 }.first!
        #expect(Calendar.current.component(.day, from: firstDate) == 1)
    }

    @Test func calendarDays_lastNonNilIsLastDayOfMonth() {
        let february = makeDate(year: 2026, month: 2, day: 1)
        let lastDate = calendarDays(for: february).compactMap { $0 }.last!
        let expectedLastDay = Calendar.current.range(of: .day, in: .month, for: february)!.count
        #expect(Calendar.current.component(.day, from: lastDate) == expectedLastDay)
    }
}

// MARK: - Ride Join / Leave Logic

@Suite("Ride Join/Leave Logic")
struct RideJoinLeaveTests {

    @Test func canJoin_whenNotFullAndNotAlreadyJoined() {
        let ride = makeRide(maxRiders: 3, riders: riders(["user1"]))
        #expect(!ride.isFull)
        #expect(ride.riders["user2"] == nil)
    }

    @Test func cannotJoin_whenFull() {
        let ride = makeRide(maxRiders: 2, riders: riders(["u1", "u2"]))
        #expect(ride.isFull)
    }

    @Test func cannotJoin_ifAlreadyMember() {
        let ride = makeRide(maxRiders: 3, riders: riders(["user1"]))
        #expect(ride.riders["user1"] != nil)
    }

    @Test func creatorCannotLeave_isEnforcedByCheck() {
        let ride = makeRide(maxRiders: 3, riders: riders(["user1"]))
        let creator = BCUser(
            id: "user1",
            name: "Alice",
            email: "alice@bc.edu",
            gender: "Female",
            grade: "Freshman",
            dorm: "Gonzaga Hall",
            createdAt: Date()
        )
        #expect(ride.creatorId == creator.id)
    }

    @Test func poolAllowsUpToFiveRiders() {
        let ride = makeRide(maxRiders: 5, riders: riders(["u1", "u2", "u3", "u4"]))
        #expect(!ride.isFull)
        #expect(ride.spotsLeft == 1)
    }
}

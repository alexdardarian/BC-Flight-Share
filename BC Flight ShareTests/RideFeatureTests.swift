import Testing
import Foundation
@testable import BC_Flight_Share

// MARK: - BCUser Model

@Suite("BCUser Model")
struct BCUserModelTests {

    @Test func bcUserInitializesCorrectly() {
        let user = BCUser(
            id: "abc123",
            name: "John Pork",
            email: "john@bc.edu",
            gender: "Male",
            grade: "Freshman",
            dorm: "Gonzaga Hall",
            createdAt: Date()
        )
        #expect(user.id == "abc123")
        #expect(user.name == "John Pork")
        #expect(user.email == "john@bc.edu")
        #expect(user.gender == "Male")
        #expect(user.grade == "Freshman")
        #expect(user.dorm == "Gonzaga Hall")
    }
}

// MARK: - Departure Range

@Suite("Departure Range")
struct DepartureRangeTests {

    @Test func departureEndTime_is30MinAfterStart() {
        let start = Date()
        let ride = makeRide(earliestDeparture: start, windowMinutes: 30)
        let expected = start.addingTimeInterval(30 * 60)
        #expect(abs(ride.departureEndTime.timeIntervalSince(expected)) < 1)
    }

    @Test func departureEndTime_is45MinAfterStart() {
        let start = Date()
        let ride = makeRide(earliestDeparture: start, windowMinutes: 45)
        let expected = start.addingTimeInterval(45 * 60)
        #expect(abs(ride.departureEndTime.timeIntervalSince(expected)) < 1)
    }

    @Test func departureEndTime_is60MinAfterStart() {
        let start = Date()
        let ride = makeRide(earliestDeparture: start, windowMinutes: 60)
        let expected = start.addingTimeInterval(60 * 60)
        #expect(abs(ride.departureEndTime.timeIntervalSince(expected)) < 1)
    }

    @Test func departureRangeString_containsDash() {
        let ride = makeRide(earliestDeparture: Date(), windowMinutes: 30)
        #expect(ride.departureRangeString.contains("–"))
    }

    @Test func flightDepartureTime_storedCorrectly() {
        let flight = Date().addingTimeInterval(3600 * 5)
        let ride = makeRide(earliestDeparture: Date(), windowMinutes: 30, flightTime: flight)
        #expect(abs(ride.flightDepartureTime.timeIntervalSince(flight)) < 1)
    }

    @Test func terminal_storedCorrectly() {
        let ride = makeRide(earliestDeparture: Date(), windowMinutes: 30)
        #expect(ride.terminal == "Terminal B")
    }

    private func makeRide(earliestDeparture: Date, windowMinutes: Int, flightTime: Date? = nil) -> Ride {
        Ride(
            creatorId: "u1",
            creatorName: "Alice",
            creatorGender: "Female",
            destination: "Logan Airport (BOS)",
            terminal: "Terminal B",
            meetingLocation: "Bus Stop",
            earliestDepartureFromCampus: earliestDeparture,
            departureWindowMinutes: windowMinutes,
            flightDepartureTime: flightTime ?? earliestDeparture.addingTimeInterval(7200),
            maxRiders: 3,
            riders: ["u1": RiderInfo(name: "Alice", gender: "Female")],
            notes: "",
            createdAt: Date()
        )
    }
}

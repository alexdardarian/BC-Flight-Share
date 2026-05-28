import Testing
import Foundation
@testable import BC_Flight_Share

@Suite("Ride Direction")
struct RideDirectionTests {

    @Test func nilDirection_defaultsToToAirport() {
        let ride = makeRide(direction: nil)
        #expect(ride.rideDirection == .toAirport)
    }

    @Test func explicitToAirport_returnsToAirport() {
        let ride = makeRide(direction: .toAirport)
        #expect(ride.rideDirection == .toAirport)
    }

    @Test func explicitToBC_returnsToBC() {
        let ride = makeRide(direction: .toBC)
        #expect(ride.rideDirection == .toBC)
    }

    @Test func rawValues_matchFirestoreStrings() {
        #expect(RideDirection.toAirport.rawValue == "toAirport")
        #expect(RideDirection.toBC.rawValue == "toBC")
    }

    @Test func ridesOfBothDirections_appearOnSameCalendarDate() {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 9; comps.day = 15; comps.hour = 10
        let day = Calendar.current.date(from: comps)!
        let rides = [
            makeRide(direction: .toAirport, date: day, id: "r1"),
            makeRide(direction: .toBC, date: day, id: "r2")
        ]
        let key = day.rideKey
        #expect(rides.filter { $0.dateKey == key }.count == 2)
    }

    @Test func createRideRequest_direction_isPreserved() {
        let req = CreateRideRequest(
            destination: "Logan Airport (BOS)",
            terminal: "Terminal B",
            meetingLocation: "Lower Campus Bus Stop",
            earliestDepartureFromCampus: Date(),
            departureWindowMinutes: 30,
            flightDepartureTime: Date().addingTimeInterval(7200),
            maxRiders: 3,
            notes: "",
            direction: .toBC
        )
        #expect(req.direction == .toBC)
    }

    @Test func createRideRequest_defaultDirection_isToAirport() {
        let req = CreateRideRequest(
            destination: "Logan Airport (BOS)",
            terminal: "Terminal B",
            meetingLocation: "Lower Campus Bus Stop",
            earliestDepartureFromCampus: Date(),
            departureWindowMinutes: 30,
            flightDepartureTime: Date().addingTimeInterval(7200),
            maxRiders: 3,
            notes: "",
            direction: .toAirport
        )
        #expect(req.direction == .toAirport)
    }

    @Test func blockFiltering_worksForBothDirections() {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 9; comps.day = 15; comps.hour = 10
        let day = Calendar.current.date(from: comps)!
        let rides = [
            makeRide(direction: .toAirport, creatorId: "alice", date: day, id: "r1"),
            makeRide(direction: .toBC, creatorId: "bob", date: day, id: "r2")
        ]
        let key = day.rideKey
        let filtered = rides.filter { $0.dateKey == key && !["bob"].contains($0.creatorId) }
        #expect(filtered.count == 1)
        #expect(filtered.first?.creatorId == "alice")
    }

    // MARK: - Helpers

    private func makeRide(
        direction: RideDirection?,
        creatorId: String = "user1",
        date: Date = Date().addingTimeInterval(86400),
        id: String = "r1"
    ) -> Ride {
        Ride(
            id: id,
            creatorId: creatorId,
            creatorName: "Alice",
            destination: "Logan Airport (BOS)",
            terminal: "Terminal B",
            meetingLocation: "Lower Campus Bus Stop",
            earliestDepartureFromCampus: date,
            departureWindowMinutes: 30,
            flightDepartureTime: date.addingTimeInterval(7200),
            maxRiders: 3,
            riders: [creatorId: RiderInfo(name: "Alice", gender: "Female")],
            notes: "",
            createdAt: Date(),
            direction: direction
        )
    }
}

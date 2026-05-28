import Testing
import Foundation
@testable import BC_Flight_Share

// MARK: - Helpers

private func makeBlockingRide(
    id: String,
    creatorId: String,
    date: Date = Date().addingTimeInterval(86400)
) -> Ride {
    Ride(
        id: id,
        creatorId: creatorId,
        creatorName: "Test User",
        destination: "Logan Airport (BOS)",
        terminal: "Terminal B",
        meetingLocation: "Lower Campus Bus Stop",
        earliestDepartureFromCampus: date,
        departureWindowMinutes: 30,
        flightDepartureTime: date.addingTimeInterval(7200),
        maxRiders: 3,
        riders: [creatorId: RiderInfo(name: "Test User", gender: "Other")],
        notes: "",
        createdAt: Date(),
        direction: nil
    )
}

private func ridesOn(date: Date, from rides: [Ride], excluding blocked: Set<String>) -> [Ride] {
    let key = date.rideKey
    return rides.filter { $0.dateKey == key && !blocked.contains($0.creatorId) }
}

// MARK: - Block Filtering

@Suite("Block Filtering")
struct BlockFilteringTests {

    @Test func emptyBlockList_returnsAllRidesForDay() {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 9; comps.day = 1; comps.hour = 10
        let day = Calendar.current.date(from: comps)!
        let rides = [
            makeBlockingRide(id: "r1", creatorId: "alice", date: day),
            makeBlockingRide(id: "r2", creatorId: "bob", date: day)
        ]
        let result = ridesOn(date: day, from: rides, excluding: [])
        #expect(result.count == 2)
    }

    @Test func blockedCreator_isExcludedFromResults() {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 9; comps.day = 1; comps.hour = 10
        let day = Calendar.current.date(from: comps)!
        let rides = [
            makeBlockingRide(id: "r1", creatorId: "alice", date: day),
            makeBlockingRide(id: "r2", creatorId: "bob", date: day)
        ]
        let result = ridesOn(date: day, from: rides, excluding: ["bob"])
        #expect(result.count == 1)
        #expect(result.first?.creatorId == "alice")
    }

    @Test func allCreatorsBlocked_returnsEmpty() {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 9; comps.day = 1; comps.hour = 10
        let day = Calendar.current.date(from: comps)!
        let rides = [
            makeBlockingRide(id: "r1", creatorId: "alice", date: day),
            makeBlockingRide(id: "r2", creatorId: "bob", date: day)
        ]
        let result = ridesOn(date: day, from: rides, excluding: ["alice", "bob"])
        #expect(result.isEmpty)
    }

    @Test func blockListWithUnknownId_hasNoEffect() {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 9; comps.day = 1; comps.hour = 10
        let day = Calendar.current.date(from: comps)!
        let rides = [makeBlockingRide(id: "r1", creatorId: "alice", date: day)]
        let result = ridesOn(date: day, from: rides, excluding: ["nobody"])
        #expect(result.count == 1)
    }

    @Test func blockingDoesNotAffectDifferentDay() {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 9; comps.day = 1; comps.hour = 10
        let day1 = Calendar.current.date(from: comps)!
        comps.day = 2
        let day2 = Calendar.current.date(from: comps)!
        let rides = [
            makeBlockingRide(id: "r1", creatorId: "alice", date: day1),
            makeBlockingRide(id: "r2", creatorId: "bob", date: day2)
        ]
        // Bob is blocked, but querying day2 still gets no bob ride (correct — bob is blocked)
        let resultDay1 = ridesOn(date: day1, from: rides, excluding: ["bob"])
        let resultDay2 = ridesOn(date: day2, from: rides, excluding: ["bob"])
        #expect(resultDay1.count == 1)
        #expect(resultDay2.isEmpty)
    }
}

// MARK: - Expired Ride Logic

@Suite("Expired Ride Logic")
struct ExpiredRideTests {

    private func makeExpiredRide(expiredSecondsAgo: Double) -> Ride {
        let twoHours: Double = 7200
        let window: Double = 30 * 60
        // Set earliestDeparture so that departureEndTime + 2h is `expiredSecondsAgo` in the past
        let earliest = Date().addingTimeInterval(-(expiredSecondsAgo + twoHours + window))
        return makeBlockingRide(id: "r", creatorId: "u", date: earliest)
    }

    @Test func ride_isExpiredWhenEndTimePlusTwoHoursPassed() {
        let ride = makeExpiredRide(expiredSecondsAgo: 1)
        #expect(ride.isExpired)
    }

    @Test func ride_isNotExpiredWhenDepartureIsInFuture() {
        let future = Date().addingTimeInterval(86400)
        let ride = makeBlockingRide(id: "r", creatorId: "u", date: future)
        #expect(!ride.isExpired)
    }

    @Test func ride_isNotExpiredDuringDepartureWindow() {
        // Window starts now, so we're inside the window
        let ride = makeBlockingRide(id: "r", creatorId: "u", date: Date())
        #expect(!ride.isExpired)
    }

    @Test func expiredRideFilter_removesExpiredRides() {
        let future = Date().addingTimeInterval(86400)
        let rides = [
            makeBlockingRide(id: "r1", creatorId: "u1", date: future),
            makeExpiredRide(expiredSecondsAgo: 60)
        ]
        let active = rides.filter { !$0.isExpired }
        #expect(active.count == 1)
        #expect(active.first?.id == "r1")
    }

    @Test func expiredRideFilter_keepsAllWhenNoneExpired() {
        let future = Date().addingTimeInterval(86400)
        let rides = [
            makeBlockingRide(id: "r1", creatorId: "u1", date: future),
            makeBlockingRide(id: "r2", creatorId: "u2", date: future.addingTimeInterval(3600))
        ]
        #expect(rides.filter { !$0.isExpired }.count == 2)
    }
}

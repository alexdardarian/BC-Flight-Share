import Foundation
import FirebaseFirestore

enum RideDirection: String, Codable {
    case toAirport
    case toBC
}

struct RiderInfo: Codable, Equatable {
    var name: String
    var gender: String
}

struct Ride: Identifiable, Codable {
    @DocumentID var id: String?
    var creatorId: String
    var creatorName: String
    var creatorGender: String
    var destination: String
    var terminal: String
    var meetingLocation: String
    var earliestDepartureFromCampus: Date
    var departureWindowMinutes: Int
    var flightDepartureTime: Date
    var maxRiders: Int
    var riders: [String: RiderInfo]
    var notes: String
    var createdAt: Date
    var direction: RideDirection?

    var rideDirection: RideDirection { direction ?? .toAirport }

    var isFull: Bool { riders.count >= maxRiders }
    var spotsLeft: Int { max(0, maxRiders - riders.count) }

    var departureEndTime: Date {
        earliestDepartureFromCampus.addingTimeInterval(Double(departureWindowMinutes) * 60)
    }

    var departureRangeString: String {
        let start = earliestDepartureFromCampus.formatted(.dateTime.hour().minute())
        let end = departureEndTime.formatted(.dateTime.hour().minute())
        return "\(start) – \(end)"
    }

    var isExpired: Bool {
        departureEndTime.addingTimeInterval(2 * 3600) < Date()
    }

    var dateKey: String {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: earliestDepartureFromCampus)
        return "\(comps.year!)-\(comps.month!)-\(comps.day!)"
    }
}

struct BCUser: Identifiable, Codable {
    var id: String
    var name: String
    var email: String
    var gender: String
    var grade: String
    var dorm: String
    var createdAt: Date
}

struct CreateRideRequest {
    var destination: String
    var terminal: String
    var meetingLocation: String
    var earliestDepartureFromCampus: Date
    var departureWindowMinutes: Int
    var flightDepartureTime: Date
    var maxRiders: Int
    var notes: String
    var direction: RideDirection
}

struct Message: Identifiable, Codable {
    @DocumentID var id: String?
    var senderId: String
    var senderName: String
    var text: String
    var createdAt: Date
}

extension Date {
    var rideKey: String {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: self)
        return "\(comps.year!)-\(comps.month!)-\(comps.day!)"
    }
}

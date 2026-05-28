import SwiftUI

struct CalendarTabView: View {
    @Environment(RideViewModel.self) private var rideVM
    @Environment(AuthViewModel.self) private var authVM
    @Environment(BlockViewModel.self) private var blockVM
    @State private var displayedMonth = Date()
    @State private var selectedDate: Date?
    @State private var showCreateRide = false

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let dayLabels = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                monthHeader
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

                LazyVGrid(columns: columns) {
                    ForEach(dayLabels, id: \.self) { day in
                        Text(day)
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 12)

                Divider().padding(.vertical, 8)

                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(Array(calendarDays().enumerated()), id: \.offset) { _, date in
                        if let date {
                            DayCell(
                                date: date,
                                isSelected: selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false,
                                isToday: calendar.isDateInToday(date),
                                hasRides: rideVM.hasRides(on: date, excluding: blockVM.blockedUserIds),
                                isPast: date < calendar.startOfDay(for: Date())
                            )
                            .onTapGesture { selectedDate = date }
                        } else {
                            Color.clear.frame(height: 46)
                        }
                    }
                }
                .padding(.horizontal, 12)

                Divider().padding(.top, 12)

                if let selected = selectedDate {
                    DayRidesView(date: selected)
                } else {
                    emptyPrompt
                }
            }
            .navigationTitle("BC Flight Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showCreateRide = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.bcMaroon)
                    }
                }
            }
            .sheet(isPresented: $showCreateRide) {
                CreateRideView(selectedDate: selectedDate)
                    .environment(rideVM)
                    .environment(authVM)
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth)!
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.bold())
                    .foregroundStyle(Color.bcMaroon)
            }

            Spacer()

            Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.title2.bold())

            Spacer()

            Button {
                displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth)!
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.bold())
                    .foregroundStyle(Color.bcMaroon)
            }
        }
    }

    private var emptyPrompt: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "hand.tap")
                .font(.system(size: 40))
                .foregroundStyle(Color.secondary.opacity(0.4))
            Text("Tap a date to see rides")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func calendarDays() -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
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
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasRides: Bool
    let isPast: Bool

    var body: some View {
        VStack(spacing: 3) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 16, weight: isToday ? .bold : .regular))
                .foregroundStyle(
                    isSelected ? .white :
                    isPast ? Color.secondary.opacity(0.35) :
                    isToday ? Color.bcMaroon : .primary
                )
                .frame(width: 36, height: 36)
                .background(Circle().fill(isSelected ? Color.bcMaroon : Color.clear))

            Circle()
                .fill(hasRides ? (isSelected ? Color.bcGold : Color.bcMaroon) : Color.clear)
                .frame(width: 5, height: 5)
        }
    }
}

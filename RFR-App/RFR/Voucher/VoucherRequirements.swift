/*
 * Copyright 2024 Cyface GmbH
 *
 * This file is part of the Ready for Robots App.
 *
 * The Ready for Robots App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Ready for Robots App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Ready for Robots App. If not, see <http://www.gnu.org/licenses/>.
 */

import CoreLocation
import SwiftUI
import DataCapturing

struct VoucherRequirements {
    // MARK: - Properties
    let daysInSpecialRegion = 3
    let specialRegion = CLCircularRegion(
        center: CLLocationCoordinate2D(latitude: 12.220760571276312, longitude: 51.395503403504705),
        radius: CLLocationDistance(150),
        identifier: "Schkeuditz Town Hall"
    )
    let dataStoreStack: DataStoreStack
    var daysInSpecialRegionFullFilled = 0
    var uploaded = 0

    // MARK: - Methods
    @ViewBuilder
    func progressView(voucherCount: Int) -> some View {
        VStack {
            HStack {
                Image(systemName: "rosette")
                VStack {
                    if daysInSpecialRegionFullFilled < daysInSpecialRegion {
                        Text("Bitte fahren Sie \(daysInSpecialRegion - daysInSpecialRegionFullFilled) mal am Rathaus vorbei, um ein Gewinnlos zu erhalten!")
                    } else {
                        Text("Laden Sie bitte noch \(daysInSpecialRegion - uploaded) von \(daysInSpecialRegionFullFilled) Messungen hoch, um ein Gewinnlos zu erhalten!")
                    }
                }
            }
        }
    }

    func isQualifiedForVoucher() -> Bool {
        return daysInSpecialRegionFullFilled >= daysInSpecialRegion
    }

    mutating func refreshProgress() async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try dataStoreStack.wrapInContext { context in
                    let fetchedMeasurements = try MeasurementMO.fetchRequest().execute()

                    let fullFilledDates = fetchedMeasurements.filter {
                        // At least one track of this measurement fullfills the embedded condition
                        $0.typedTracks()
                            .filter {
                                // 10 or more locations are around the Schkeuditz Town Hall.
                                $0.typedLocations()
                                    .filter {
                                        specialRegion.contains(CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon))
                                    }.count >= 10
                            }.count > 0
                    }
                    // Map measurements to capturing time and count days without duplicates
                        .compactMap { if let time = $0.time { return (time, $0.synchronized) } else { return nil } }
                        .map { (timeTuple: (Date, Bool)) in
                            let day = Calendar.current.component(.day, from: timeTuple.0)
                            let month = Calendar.current.component(.month, from: timeTuple.0)
                            let year = Calendar.current.component(.year, from: timeTuple.0)
                            return DateWithOutTime(day: day, month: month, year: year, synchronized: timeTuple.1)
                        }

                    let synchronizedDates = Set(fullFilledDates.filter { $0.synchronized })
                    let unsychronizedDates = Set(fullFilledDates.filter { !$0.synchronized })
                    daysInSpecialRegionFullFilled = synchronizedDates.union(unsychronizedDates).count
                    uploaded = synchronizedDates.count
                }
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Private Methods
    private func toDistance(track: TrackMO) -> Double {
        return toDistance(
            locations: track.typedLocations().sorted {
                $0.time! < $1.time!
            }
        )
    }

    private func toDistance(locations: [GeoLocationMO]) -> Double {
        var previousLocation: GeoLocationMO? = nil
        var accumulatedDistance = 0.0
        locations.forEach { location in
            if let previousLocation = previousLocation {
                accumulatedDistance += previousLocation.distance(to: location)
            }
            previousLocation = location
        }
        return accumulatedDistance
    }

    private func toDistance(measurement: MeasurementMO) -> Double {
        return measurement.typedTracks().map { track in
            toDistance(track: track)
        }.reduce(0.0) { $0 + $1 }
    }

    private struct DateWithOutTime: Equatable, Hashable {
        let day: Int
        let month: Int
        let year: Int
        let synchronized: Bool

        static func == (lhs: DateWithOutTime, rhs: DateWithOutTime) -> Bool {
            return lhs.day == rhs.day && lhs.month == rhs.month && lhs.year == rhs.year
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(day)
            hasher.combine(month)
            hasher.combine(year)
        }
    }
}

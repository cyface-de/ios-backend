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

/**
 A wrapper for the requirements for getting a voucher.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.2.2
 */
struct VoucherRequirements {
    // MARK: - Properties
    /// The number of days to have at least one measurement in the special region
    let daysInSpecialRegion = 3
    /// The coordinates of the special region.
    let specialRegion = CLCircularRegion(
        center: CLLocationCoordinate2D(latitude: 12.220760571276312, longitude: 51.395503403504705),
        radius: CLLocationDistance(150),
        identifier: "Schkeuditz Town Hall"
    )
    /// Access to the apps data storage to store load progress from.
    let dataStoreStack: DataStoreStack
    /// The number of days the user already did drive through the special region.
    var daysInSpecialRegionFullFilled = 0
    /// The number of valid measurements already uploaded.
    var uploaded = 0

    // MARK: - Methods
    /// The view showing the progress towards the challenge goal.
    @ViewBuilder
    func progressView(voucherCount: Int) -> some View {
        VStack {
            HStack {
                Image(systemName: "rosette")
                VStack {
                    if daysInSpecialRegionFullFilled < daysInSpecialRegion {
                        Text(
                            String.localizedStringWithFormat(
                                NSLocalizedString(
                                    "de.cyface.rfr.text.VoucherRequirements.condition_town_hall",
                                    comment: "Tell the user how often they should pass town hall. The number is provided as the first argument"
                                ),
                                daysInSpecialRegion - daysInSpecialRegionFullFilled
                            )
                            //"Bitte fahren Sie \() mal am Rathaus vorbei, um ein Gewinnlos zu erhalten!"
                        )
                    } else {
                        Text(
                            String.localizedStringWithFormat(
                                NSLocalizedString(
                                    "de.cyface.rfr.text.VoucherRequirements.condition_upload",
                                    comment: """
Tell the user how many of their measurements they are still required to upload. The number of uploads required is provided as the first parameter. The second parameter are the uploads required alltogether.
"""
                                ),
                                daysInSpecialRegion - uploaded,
                                daysInSpecialRegionFullFilled
                            )
                            //"Laden Sie bitte noch \(daysInSpecialRegion - uploaded) von \(daysInSpecialRegionFullFilled) Messungen hoch, um ein Gewinnlos zu erhalten!"
                        )
                    }
                }
            }
        }
    }

    /// This is `true` if the user is qualified to recieve a new voucher.
    func isQualifiedForVoucher() -> Bool {
        return daysInSpecialRegionFullFilled >= daysInSpecialRegion
    }

    /// Refresh the progress from the measurements currently stored on the device.
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
    /// Calculate the covered distance for one single track.
    private func toDistance(track: TrackMO) -> Double {
        return toDistance(
            locations: track.typedLocations().sorted {
                $0.time! < $1.time!
            }
        )
    }

    /// Calculate the distance between an array of geo locations ordered by time.
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

    /// Calculate the distance covered by a measurement.
    private func toDistance(measurement: MeasurementMO) -> Double {
        return measurement.typedTracks().map { track in
            toDistance(track: track)
        }.reduce(0.0) { $0 + $1 }
    }

    /**
     Since the natie date structure always requires a time component (and that time component will change the date based on the users time zone), this struct provides us the possibility to only store a date.

     - Author: Klemens Muthmann
     - Version: 1.0.0
     - Since: 3.2.2
     */
    private struct DateWithOutTime: Equatable, Hashable {
        /// The day in the month.
        let day: Int
        /// The month in the year.
        let month: Int
        /// The year AD.
        let year: Int
        /// Whether the measurement with that date was synchronized.
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

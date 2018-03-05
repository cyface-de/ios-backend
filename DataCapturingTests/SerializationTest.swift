//
//  SerializationTest.swift
//  DataCapturing-Unit-Tests
//
//  Created by Team Cyface on 01.03.18.
//

import XCTest
@testable import DataCapturing

class SerializationTest: XCTestCase {
    
    var oocut: CyfaceBinaryFormatSerializer?
    var pl: PersistenceLayer?
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        oocut = CyfaceBinaryFormatSerializer()
        pl = PersistenceLayer()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        oocut = nil
        super.tearDown()
    }
    
    func testUncompressedSerialization() {
        guard let oocut = oocut else {
            fatalError("Test failed! No object of class under test.")
        }
        guard let pl = pl else {
            fatalError("Test failed! No persistence layer to create test fixture from.")
        }
        let measurement = pl.createMeasurement(at: 1)
        let acc1 = pl.createAcceleration(x: 1.0, y: 1.0, z: 1.0, at: 10_000)
        let acc2 = pl.createAcceleration(x: 1.0, y: 1.0, z: 1.0, at: 10_100)
        let acc3 = pl.createAcceleration(x: 1.0, y: 1.0, z: 1.0, at: 10_200)
        measurement.addToAccelerations(acc1)
        measurement.addToAccelerations(acc2)
        measurement.addToAccelerations(acc3)
        let geo1 = pl.createGeoLocation(latitude: 1.0, longitude: 1.0, accuracy: 2.0, speed: 1.0, at: 10_000)
        let geo2 = pl.createGeoLocation(latitude: 1.0, longitude: 1.0, accuracy: 2.0, speed: 1.0, at: 10_100)
        let geo3 = pl.createGeoLocation(latitude: 1.0, longitude: 1.0, accuracy: 2.0, speed: 1.0, at: 10_200)
        measurement.addToGeoLocations(geo1)
        measurement.addToGeoLocations(geo2)
        measurement.addToGeoLocations(geo3)
        
        let res = oocut.serialize(measurement)
        
        XCTAssertEqual(res.count, 222)
        // Data Format Version
        XCTAssertEqual(res[0],0)
        XCTAssertEqual(res[1],1)
        // Count of Geo Locations
        XCTAssertEqual(res[2],0)
        XCTAssertEqual(res[3],0)
        XCTAssertEqual(res[4],0)
        XCTAssertEqual(res[5],3)
        // Count of Accelerations
        XCTAssertEqual(res[9],3)
        
        /*for i in 0..<res.count {
            print("Index \(i): ",res[i])
        }*/
    }
    
    func testCompressedSerialization() {
        guard let oocut = oocut else {
            fatalError("Test failed! No object of class under test.")
        }
        guard let pl = pl else {
            fatalError("Test failed! No persistence layer to create test fixture from.")
        }
        let measurement = pl.createMeasurement(at: 1)
        let acc1 = pl.createAcceleration(x: 1.0, y: 1.0, z: 1.0, at: 10_000)
        let acc2 = pl.createAcceleration(x: 1.0, y: 1.0, z: 1.0, at: 10_100)
        let acc3 = pl.createAcceleration(x: 1.0, y: 1.0, z: 1.0, at: 10_200)
        measurement.addToAccelerations(acc1)
        measurement.addToAccelerations(acc2)
        measurement.addToAccelerations(acc3)
        let geo1 = pl.createGeoLocation(latitude: 1.0, longitude: 1.0, accuracy: 2.0, speed: 1.0, at: 10_000)
        let geo2 = pl.createGeoLocation(latitude: 1.0, longitude: 1.0, accuracy: 2.0, speed: 1.0, at: 10_100)
        let geo3 = pl.createGeoLocation(latitude: 1.0, longitude: 1.0, accuracy: 2.0, speed: 1.0, at: 10_200)
        measurement.addToGeoLocations(geo1)
        measurement.addToGeoLocations(geo2)
        measurement.addToGeoLocations(geo3)
        
        let res = oocut.serializeCompressed(measurement)
        
        let uncompressedData = res.inflate()

        XCTAssertEqual(uncompressedData?.count, 222)
        // Data Format Version
        XCTAssertEqual(uncompressedData![0],0)
        XCTAssertEqual(uncompressedData![1],1)
        // Count of Geo Locations
        XCTAssertEqual(uncompressedData![2],0)
        XCTAssertEqual(uncompressedData![3],0)
        XCTAssertEqual(uncompressedData![4],0)
        XCTAssertEqual(uncompressedData![5],3)
        // Count of Accelerations
        XCTAssertEqual(uncompressedData![9],3)
        /*for i in 0..<uncompressedData!.count {
            print("Index \(i): ",uncompressedData![i])
        }*/
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}

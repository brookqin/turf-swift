import XCTest
#if !os(Linux)
import CoreLocation
#endif
import Turf

class PolygonTests: XCTestCase {
    
    func testPolygonFeature() {
        let data = try! Fixture.geojsonData(from: "polygon")!
        let geojson = try! GeoJSON.parse(Feature.self, from: data)
        
        let firstCoordinate = LocationCoordinate2D(latitude: 37.00255267215955, longitude: -109.05029296875)
        let lastCoordinate = LocationCoordinate2D(latitude: 40.6306300839918, longitude: -108.56689453125)
        
        XCTAssert((geojson.identifier!.value as! Number).value! as! Double == 1.01)
        
        guard case let .polygon(polygon) = geojson.geometry else {
            XCTFail()
            return
        }
        XCTAssert(polygon.outerRing.coordinates.first == firstCoordinate)
        XCTAssert(polygon.innerRings.last?.coordinates.last == lastCoordinate)
        XCTAssert(polygon.outerRing.coordinates.count == 5)
        XCTAssert(polygon.innerRings.first?.coordinates.count == 5)
        
        let encodedData = try! JSONEncoder().encode(geojson)
        let decoded = try! GeoJSON.parse(Feature.self, from: encodedData)
        guard case let .polygon(decodedPolygon) = decoded.geometry else {
                   XCTFail()
                   return
               }
        
        XCTAssertEqual(polygon, decodedPolygon)
        XCTAssertEqual(geojson.identifier!.value as! Number, decoded.identifier!.value! as! Number)
        XCTAssert(decodedPolygon.outerRing.coordinates.first == firstCoordinate)
        XCTAssert(decodedPolygon.innerRings.last?.coordinates.last == lastCoordinate)
        XCTAssert(decodedPolygon.outerRing.coordinates.count == 5)
        XCTAssert(decodedPolygon.innerRings.first?.coordinates.count == 5)
    }
    
    func testPolygonContains() {
        let coordinate = LocationCoordinate2D(latitude: 44, longitude: -77)
        let polygon = Polygon([[
            LocationCoordinate2D(latitude: 41, longitude: -81),
            LocationCoordinate2D(latitude: 47, longitude: -81),
            LocationCoordinate2D(latitude: 47, longitude: -72),
            LocationCoordinate2D(latitude: 41, longitude: -72),
            LocationCoordinate2D(latitude: 41, longitude: -81),
        ]])
        XCTAssertTrue(polygon.contains(coordinate))
    }
    
    func testPolygonDoesNotContain() {
        let coordinate = LocationCoordinate2D(latitude: 44, longitude: -77)
        let polygon = Polygon([[
            LocationCoordinate2D(latitude: 41, longitude: -51),
            LocationCoordinate2D(latitude: 47, longitude: -51),
            LocationCoordinate2D(latitude: 47, longitude: -42),
            LocationCoordinate2D(latitude: 41, longitude: -42),
            LocationCoordinate2D(latitude: 41, longitude: -51),
        ]])
        XCTAssertFalse(polygon.contains(coordinate))
    }
    
    func testPolygonDoesNotContainWithHole() {
        let coordinate = LocationCoordinate2D(latitude: 44, longitude: -77)
        let polygon = Polygon([
            [
                LocationCoordinate2D(latitude: 41, longitude: -81),
                LocationCoordinate2D(latitude: 47, longitude: -81),
                LocationCoordinate2D(latitude: 47, longitude: -72),
                LocationCoordinate2D(latitude: 41, longitude: -72),
                LocationCoordinate2D(latitude: 41, longitude: -81),
            ],
            [
                LocationCoordinate2D(latitude: 43, longitude: -76),
                LocationCoordinate2D(latitude: 43, longitude: -78),
                LocationCoordinate2D(latitude: 45, longitude: -78),
                LocationCoordinate2D(latitude: 45, longitude: -76),
                LocationCoordinate2D(latitude: 43, longitude: -76),
            ],
        ])
        XCTAssertFalse(polygon.contains(coordinate))
    }

    func testPolygonContainsAtBoundary() {
        let coordinate = LocationCoordinate2D(latitude: 1, longitude: 1)
        let polygon = Polygon([[
            LocationCoordinate2D(latitude: 0, longitude: 0),
            LocationCoordinate2D(latitude: 1, longitude: 0),
            LocationCoordinate2D(latitude: 1, longitude: 1),
            LocationCoordinate2D(latitude: 0, longitude: 1),
            LocationCoordinate2D(latitude: 0, longitude: 0),
        ]])

        XCTAssertFalse(polygon.contains(coordinate, ignoreBoundary: true))
        XCTAssertTrue(polygon.contains(coordinate, ignoreBoundary: false))
        XCTAssertTrue(polygon.contains(coordinate))
    }

    func testPolygonWithHoleContainsAtBoundary() {
        let coordinate = LocationCoordinate2D(latitude: 43, longitude: -78)
        let polygon = Polygon([
            [
                LocationCoordinate2D(latitude: 41, longitude: -81),
                LocationCoordinate2D(latitude: 47, longitude: -81),
                LocationCoordinate2D(latitude: 47, longitude: -72),
                LocationCoordinate2D(latitude: 41, longitude: -72),
                LocationCoordinate2D(latitude: 41, longitude: -81),
            ],
            [
                LocationCoordinate2D(latitude: 43, longitude: -76),
                LocationCoordinate2D(latitude: 43, longitude: -78),
                LocationCoordinate2D(latitude: 45, longitude: -78),
                LocationCoordinate2D(latitude: 45, longitude: -76),
                LocationCoordinate2D(latitude: 43, longitude: -76),
            ],
        ])

        XCTAssertFalse(polygon.contains(coordinate, ignoreBoundary: true))
        XCTAssertTrue(polygon.contains(coordinate, ignoreBoundary: false))
        XCTAssertTrue(polygon.contains(coordinate))
    }

    func testCirclePolygon()
    {
        let coord = LocationCoordinate2D(latitude: 10.0, longitude: 5.0)
        let radius = 500
        let circleShape = Polygon(center: coord, radius: LocationDistance(radius), vertices: 64)

        // Test number of vertices is 64.
        let expctedNumberOfSteps = circleShape.coordinates[0].count - 1
        XCTAssertEqual(expctedNumberOfSteps, 64)

        // Test the diameter of the circle is 2x its radius.
        let startingCoord = circleShape.coordinates[0][0]
        let oppositeCoord = circleShape.coordinates[0][circleShape.coordinates[0].count / 2]

        let expectedDiameter = LocationDistance(radius * 2)
        let diameter = startingCoord.distance(to: oppositeCoord)

        XCTAssertEqual(expectedDiameter, diameter, accuracy: 0.25)
    }
}

//
//  MapDataItem.swift
//  Errand
//
//  Created by Jim on 2020/1/20.
//  Copyright © 2020 Jim. All rights reserved.
//

import Foundation

struct Direction: Codable {
    let geocodedWaypoints: [GeocodedWaypoint]
    let routes: [Route]
    let status: String

    enum CodingKeys: String, CodingKey {
        case geocodedWaypoints = "geocoded_waypoints"
        case routes, status
    }
}

struct GeocodedWaypoint: Codable {
    let geocoderStatus, placeID: String
    let types: [String]

    enum CodingKeys: String, CodingKey {
        case geocoderStatus = "geocoder_status"
        case placeID = "place_id"
        case types
    }
}


struct Route: Codable {
    let bounds: Bounds
    let copyrights: String
    let legs: [Leg]
    let overviewPolyline: Polyline
    let summary: String
    let warnings, waypointOrder: [String]

    enum CodingKeys: String, CodingKey {
        case bounds, copyrights, legs
        case overviewPolyline = "overview_polyline"
        case summary, warnings
        case waypointOrder = "waypoint_order"
    }
}

struct Bounds: Codable {
    let northeast, southwest: Northeast
}

struct Northeast: Codable {
    let lat, lng: Double
}

struct Leg: Codable {
    let distance, duration: Distance
    let endAddress: String
    let endLocation: Northeast
    let startAddress: String
    let startLocation: Northeast
    let steps: [Step]
    let trafficSpeedEntry, viaWaypoint: [String]

    enum CodingKeys: String, CodingKey {
        case distance, duration
        case endAddress = "end_address"
        case endLocation = "end_location"
        case startAddress = "start_address"
        case startLocation = "start_location"
        case steps
        case trafficSpeedEntry = "traffic_speed_entry"
        case viaWaypoint = "via_waypoint"
    }
}

struct Distance: Codable {
    let text: String
    let value: Int
}

struct Step: Codable {
    let distance, duration: Distance
    let endLocation: Northeast
    let htmlInstructions: String
    let polyline: Polyline
    let startLocation: Northeast
    let travelMode: TravelMode
    let maneuver: String?

    enum CodingKeys: String, CodingKey {
        case distance, duration
        case endLocation = "end_location"
        case htmlInstructions = "html_instructions"
        case polyline
        case startLocation = "start_location"
        case travelMode = "travel_mode"
        case maneuver
    }
}

struct Polyline: Codable {
    let points: String
}

enum TravelMode: String, Codable {
    case driving = "DRIVING"
}


struct Address: Codable {
    let plusCode: PlusCode
    let results: [Outcome]
    let status: String

    enum CodingKeys: String, CodingKey {
        case plusCode = "plus_code"
        case results, status
    }
}

// MARK: - PlusCode
struct PlusCode: Codable {
    let compoundCode, globalCode: String

    enum CodingKeys: String, CodingKey {
        case compoundCode = "compound_code"
        case globalCode = "global_code"
    }
}


struct Outcome: Codable {
    let addressComponents: [AddressComponent]
    let formattedAddress: String
    let geometry: Geometry
    let placeID: String
    let plusCode: PlusCode?
    let types: [String]

    enum CodingKeys: String, CodingKey {
        case addressComponents = "address_components"
        case formattedAddress = "formatted_address"
        case geometry
        case placeID = "place_id"
        case plusCode = "plus_code"
        case types
    }
}


struct AddressComponent: Codable {
    let longName, shortName: String
    let types: [String]

    enum CodingKeys: String, CodingKey {
        case longName = "long_name"
        case shortName = "short_name"
        case types
    }
}


struct Geometry: Codable {
    let location: Location
    let locationType: String
    let viewport: Edge
    let bounds: Edge?

    enum CodingKeys: String, CodingKey {
        case location
        case locationType = "location_type"
        case viewport, bounds
    }
}


struct Edge: Codable {
    let northeast, southwest: Location
}

struct Location: Codable {
    let lat, lng: Double
}

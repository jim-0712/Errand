//
//  MapManager.swift
//  Errand
//
//  Created by Jim on 2020/1/20.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import CoreLocation
import Foundation
//import Alamofire

enum GoogleApiError: Error {
  
  case comnnectError
}

enum STHTTPHeaderField: String {
  
  case GET
}

protocol STRequest {
  var headers: [String: String] { get }
  var body: Data? { get }
  var method: String { get }
  var urlString: String { get }
  
}

extension STRequest {
  func makeRequest() -> URLRequest {
    let url = URL(string: urlString)!
    var request = URLRequest(url: url)
    request.allHTTPHeaderFields = headers
    request.httpBody = body
    request.httpMethod = method
    return request
  }
}

enum APIRequest: STRequest {
  
  case directionAPI(origin: String, destination: String, key: String)
  
  case location(latitude: String, longitude: String)
  
  var headers: [String: String] {
    switch self {
    case .directionAPI, .location:
      return ["Content-Type": "application/json"]
      
    }
  }
  
  var body: Data? {
    
    switch self {
    case .directionAPI, .location:
      return nil
    }
  }
  
  var method: String {
    switch self {
    case .directionAPI, .location: return STHTTPHeaderField.GET.rawValue
    }
  }
  
  var urlString: String {
    switch self {
      
    case .directionAPI(let origin, let destination, let key):
      return "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&key=\(key)&mode=driving"
      
    case .location(let latitude, let longitude):
      
      return "https://maps.googleapis.com/maps/api/geocode/json?latlng=\(latitude),\(longitude)&key=AIzaSyBbTnBn0MHPMnioaL4y68Da3d41JlaSY-g&language=zh-tw"
      
    }
  }
}

class MapManager {
  
  static let shared = MapManager()
  
  let key = "AIzaSyCR-Y_YZQakVbRAHn-DstXRUmy883ZcsG4"
  
  var totalMin = 0
  
  let decoder = JSONDecoder()
  
  func getDirection(origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D, completion: @escaping ((Result<Welcome, Error>) -> Void)) {
    
    let originString = "\(origin.latitude),\(origin.longitude)"
    
    let destinationString = "\(destination.latitude),\(destination.longitude)"
    
    URLSession.shared.dataTask(with: APIRequest.makeRequest(APIRequest.directionAPI(origin: originString, destination: destinationString, key: key))()) { (data, response, error) in
      
      guard let response = response as? HTTPURLResponse, response.statusCode == 200 else { return }
      
      if error != nil {
        
        completion(.failure(GoogleApiError.comnnectError))
        
      } else {
        
        guard let data = data else { return }
        do {
          
          let result = try self.decoder.decode(Welcome.self, from: data)
          
          completion(.success(result))
          
        } catch {
          
          completion(.failure(GoogleApiError.comnnectError))
        }
      }
    }.resume()
  }
  
  func getLocation(latitude: String, longitude: String, completion: @escaping ((Result<Address, Error>) -> Void)) {
    
    URLSession.shared.dataTask(with: APIRequest.makeRequest(APIRequest.location(latitude: latitude, longitude: longitude))()) { (data, response, error) in
      guard let response = response as? HTTPURLResponse, response.statusCode == 200 else { return }
      
      if error != nil {
        
        completion(.failure(GoogleApiError.comnnectError))
        
      } else {
        
        guard let data = data else { return }
        do {
          
          let result = try self.decoder.decode(Address.self, from: data)
          
          completion(.success(result))
          
        } catch {
          
          completion(.failure(GoogleApiError.comnnectError))
        }
      }
    }.resume()
  }

}

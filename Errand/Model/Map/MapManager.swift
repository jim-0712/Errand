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

enum DirectionApiError: Error {
  
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

enum DirectionRequest: STRequest {
  
  case directionAPI(origin: String, destination: String, key: String)
  
  var headers: [String: String] {
    switch self {
    case .directionAPI:
      return ["Content-Type": "application/json"]
    }
  }
  
  var body: Data? {
    
    switch self {
    case .directionAPI:
      return nil
    }
  }
  
  var method: String {
    switch self {
    case .directionAPI: return STHTTPHeaderField.GET.rawValue
    }
  }
  
  var urlString: String {
    switch self {
    
    case .directionAPI(let origin, let destination, let key):
      return "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&key=\(key)&mode=driving"
    }
  }
}

class MapManager {
  
  static let shared = MapManager()
  
  let key = "AIzaSyBbTnBn0MHPMnioaL4y68Da3d41JlaSY-g"
  
  var totalMin = 0
  
  let decoder = JSONDecoder()
  
  func getDirection(origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D, completion: @escaping ((Result<Welcome, Error>) -> Void)) {
    
    let originString = "\(origin.latitude),\(origin.longitude)"
    let destinationString = "\(destination.latitude),\(destination.longitude)"
    
    URLSession.shared.dataTask(with: DirectionRequest.makeRequest(DirectionRequest.directionAPI(origin: originString, destination: destinationString, key: key))()) { (data, response, error) in
      
      guard let response = response as? HTTPURLResponse, response.statusCode == 200 else { return }
      
      guard let _ = error else {
        
      completion(.failure(DirectionApiError.comnnectError))
        
      return }
      
      guard let data = data else { return }
      do {
        
        let result = try self.decoder.decode(Welcome.self, from: data)
        
        completion(.success(result))
        
      } catch {
        
        completion(.failure(DirectionApiError.comnnectError))
      }
    }.resume()
  }
  
}

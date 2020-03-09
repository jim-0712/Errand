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
  
  case POST
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
  
  case location(latitude: String, longitude: String)
  
  case notification(token: String, body: String)
  
  var headers: [String: String] {
    switch self {
    case .location:
      return ["Content-Type": "application/json"]
    
    case .notification:
      return ["Content-Type": "application/json",
              "Authorization": "key=AAAAY-GQkaQ:APA91bGnEGseSWOnzukgSP4M6AfWadP3fUqPYiMCHHRkK28WoRBkeqhOmfkH1tDRetPZ58OGV2KzTG3tkNwG3IY9kQmUgVtPMuat7qV47uoZlKS7i5QAFB8VDgS24u6KHBnzNx_rS5_y"
            ]
    }
  }
  
  var body: Data? {
    
    switch self {
    case .location:
      return nil
    case .notification(let token, let body):
      let requestBody: [String: Any] = ["to": token,
                "notification": ["title": "任務通知", "body": body],
                                      "data": ["user": "test_id"]
      ]
      return try? JSONSerialization.data(withJSONObject: requestBody, options: .prettyPrinted)
    }
  }
  
  var method: String {
    switch self {
    case .location: return STHTTPHeaderField.GET.rawValue
    case .notification: return STHTTPHeaderField.POST.rawValue
    }
  }
  
  var urlString: String {
    switch self {
      
    case .location(let latitude, let longitude):
      
      return "https://maps.googleapis.com/maps/api/geocode/json?latlng=\(latitude),\(longitude)&key=AIzaSyBbTnBn0MHPMnioaL4y68Da3d41JlaSY-g&language=zh-tw"
      
    case .notification:
      return "https://fcm.googleapis.com/fcm/send"
    }
  }
}

class APImanager {
  
  static let shared = APImanager()
  
  let key = "AIzaSyCR-Y_YZQakVbRAHn-DstXRUmy883ZcsG4"
  
  var totalMin = 0
  
  let decoder = JSONDecoder()
  
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
  
func postNotification(to token: String, body: String) {
    
    URLSession.shared.dataTask(with: APIRequest.makeRequest(APIRequest.notification(token: token, body: body))()) { _, response, _ in
      guard let response = response as? HTTPURLResponse, response.statusCode == 200 else { return }
        
      }.resume()
  }
  
  func radian(inputDouble: Double) -> Double {
       return inputDouble * Double.pi/180.0
  }

  func getDistance(lat1: Double, lng1: Double, lat2: Double, lng2: Double) -> Double {
      let earthRadius: Double = 6378137.0
      
      let radLat1: Double = self.radian(inputDouble: lat1)
      let radLat2: Double = self.radian(inputDouble: lat2)
      
      let radLng1: Double = self.radian(inputDouble: lng1)
      let radLng2: Double = self.radian(inputDouble: lng2)
      
      let latDifference: Double = radLat1 - radLat2
      let longDifference: Double = radLng1 - radLng2
      
      var distance: Double = 2 * asin(sqrt(pow(sin(latDifference/2), 2) + cos(radLat1) * cos(radLat2) * pow(sin(longDifference/2), 2)))
    
      distance = (distance * earthRadius) / 1000

     return distance
  }
}

//
//  AddLocationViewController.swift
//  Errand
//
//  Created by Jim on 2020/1/24.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import GoogleMaps
import CoreLocation
import Alamofire

class AddLocationViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setUp()
  }
  
  let myLocationManager = CLLocationManager()
  
  var addressFinal: String = "" {
    
    didSet {
      
    }
  }
  
  @IBOutlet weak var confirmLocation: UIButton!
  
  @IBOutlet weak var addLocationMap: GMSMapView!
  
  @IBAction func checkThePosition(_ sender: Any) {
    print("456")
    
    let latitude = "25.033671"
       
    let longitude = "121.564427"
    
    getAddressFromLatLong(latitude: latitude, longitude: longitude)
    
  }
  
  func setUp() {
    
    addLocationMap.delegate = self
    
    myLocationManager.delegate = self
    
    guard let center = myLocationManager.location?.coordinate else { return }
    
    let myArrange = GMSCameraPosition.camera(withTarget: center, zoom: 15)
    
    addLocationMap.camera = myArrange
    
  }
  
  func getAddressFromLatLong(latitude: String, longitude: String) {
    
    let decoder = JSONDecoder()
    
    let locationSession = URLSession(configuration: URLSessionConfiguration.default)
    
    let key = "AIzaSyBbTnBn0MHPMnioaL4y68Da3d41JlaSY-g"
     
    let url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=\(latitude),\(longitude)&key=\(key)&language=zh-TW"
    
//     let url = "https://maps.googleapis.com/maps/api/geocode/json"
    
//     let bodyString = "latlng=25.033671,121.564427&key=AIzaSyBbTnBn0MHPMnioaL4y68Da3d41JlaSY-g&language=zh-TW"
     
     guard let locationURL = URL(string: url) else { return }
     
     var request = URLRequest(url: locationURL)
     
      request.httpMethod = "GET"
    
      request.addValue("application/json", forHTTPHeaderField: "Content-Type")
     
     locationSession.dataTask(with: request) { (data, response, error) in
       
       guard let response = response as? HTTPURLResponse, response.statusCode == 200 else { return }
       
       guard let _ = error else {
         
         print("wtf")
         
         return }
       
       guard let data = data else { return }
       do {
         
         let result = try decoder.decode(Address.self, from: data)
         
        print(result)
         
       } catch {
         
       }
     }.resume()
   }
  
}

extension AddLocationViewController: GMSMapViewDelegate, CLLocationManagerDelegate {
  
  func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
    
    print("123")
    
//    let latitude = "\(position.target.latitude)"
//    
//    let longitude = "\(position.target.longitude)"
//  
    //
    //    MapManager.shared.getLocation(latitude: latitude, longitude: longitude) { [weak self]result in
    //
    //      guard let strongSelf = self else { return }
    //
    //      switch result {
    //
    //      case .success(let address):
    //
    //        strongSelf.addressFinal = address.results[0].formattedAddress
    //
    //        print(strongSelf.addressFinal)
    //
    //      case .failure:
    //
    //        LKProgressHUD.showFailure(text: "Connection Fail", controller: strongSelf)
    //      }
    //    }
    
  }
}

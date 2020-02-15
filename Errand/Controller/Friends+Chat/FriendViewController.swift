//
//  FriendViewController.swift
//  Errand
//
//  Created by Jim on 2020/2/15.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import CoreLocation

class FriendViewController: UIViewController, CLLocationManagerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

      test.delegate = self
      centerViewOnUserLocation()
      myLocationManager.startUpdatingLocation()
      myLocationManager.delegate = self
      myLocationManager.desiredAccuracy = kCLLocationAccuracyBest
      myLocationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters
    }
    
  @IBOutlet weak var test: GMSMapView!
  
  var position: [CLLocationCoordinate2D] = []
  
  var currentPosition: CLLocationCoordinate2D?
  
  let myLocationManager = CLLocationManager()
  
  func centerViewOnUserLocation() {
    guard let center = myLocationManager.location?.coordinate else { return }
    let myArrange = GMSCameraPosition.camera(withTarget: center, zoom: 17)
    test.camera = myArrange
    currentPosition = center
    let marker = GMSMarker()
       marker.position = CLLocationCoordinate2D(latitude: center.latitude, longitude: center.longitude)
       marker.title = "1"
       marker.map = test
  }
}

extension FriendViewController: GMSMapViewDelegate {
  
  func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
    
    guard let apple = currentPosition else { return }
    
    let outCome = MapManager.shared.getDistance(lat1: apple.latitude, lng1: apple.longitude, lat2: position.target.latitude, lng2: position.target.longitude)
    
    print(position)
    
    if outCome > 0.00001 {
      self.currentPosition = position.target
      self.position.append(position.target)
      let marker = GMSMarker()
      marker.position = CLLocationCoordinate2D(latitude: position.target.latitude, longitude: position.target.longitude)
      marker.title = "1"
      marker.map = test
    } else {
      return
    }
  }
}

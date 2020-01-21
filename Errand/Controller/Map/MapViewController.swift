//
//  MapViewController.swift
//  Errand
//
//  Created by Jim on 2020/1/15.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class CustomPin: NSObject, MKAnnotation {
  
  var coordinate: CLLocationCoordinate2D
  
  var title: String?
  
  var subtitle: String?
  
  init(pinTitle: String, pinSubTitle: String, location: CLLocationCoordinate2D) {
    
    self.title = pinTitle
    
    self.subtitle = pinSubTitle
    
    self.coordinate = location

  }
  
}

class MapViewController: UIViewController, MKMapViewDelegate {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setUpLocationManager()
    
    addAnnotationOnMap()

  }
  @IBOutlet weak var chooseKind: UICollectionView!
  
  @IBOutlet weak var realTimeMap: MKMapView!
  
  let myLocationManager = CLLocationManager()
  
  let latDelta = 0.005
  
  let longDelta = 0.005
  
  override func viewDidAppear(_ animated: Bool) {
    
    super.viewDidAppear(animated)
    
    checkLocationService()
    
  }
  
  func addAnnotationOnMap() {
    
//    let annotation = MKPointAnnotation()
//    annotation.title = "London"
//    annotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(25.033671), longitude: CLLocationDegrees(121.564427))
    
//    realTimeMap.addAnnotation(annotation)
    
    let cor = CLLocationCoordinate2D(latitude: CLLocationDegrees(25.033671), longitude: CLLocationDegrees(121.564427))
    
    let test = CustomPin(pinTitle: "Jim", pinSubTitle: "is", location: cor)
    
    realTimeMap.addAnnotation(test)
  }
  
  func checkLocationService() {
    
    if CLLocationManager.locationServicesEnabled() {
      
      checkLocationAuth()
      
    } else {
      
      alertOpen()
    }
  }
  
  func centerViewOnUserLocation() {
    
    // 地圖預設顯示的範圍大小 (數字越小越精確)
    let currentLocationSpan: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)
    
    guard let center = myLocationManager.location?.coordinate else { return }
    
    let currentRegion: MKCoordinateRegion = MKCoordinateRegion(
      center: center,
      span: currentLocationSpan)
    
    realTimeMap.setRegion(currentRegion, animated: true)
    
  }
  
  func setUpLocationManager() {
    
    myLocationManager.delegate = self
    
    realTimeMap.delegate = self
    
    myLocationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters
    
    myLocationManager.desiredAccuracy = kCLLocationAccuracyBest
    
    realTimeMap.isZoomEnabled = true
    
  }
  
  func checkLocationAuth() {
    
    switch CLLocationManager.authorizationStatus() {
      
    case .authorizedWhenInUse:
      
      realTimeMap.showsUserLocation = true
      
      centerViewOnUserLocation()
      
      myLocationManager.startUpdatingLocation()
      
    case .denied:
      
      alertOpen()
      
    case .notDetermined:
      
      myLocationManager.requestWhenInUseAuthorization()
      
    case .authorizedAlways:
      
      realTimeMap.showsUserLocation = true
      
      centerViewOnUserLocation()
      
      myLocationManager.startUpdatingLocation()
      
    case .restricted:
      
      alertOpen()
      
    default:
      
      break
    }
  }
  
  func alertOpen() {
    
    let alertController = UIAlertController(title: "定位權限已關閉", message: "請至 設定 > 隱私權 > 定位服務 開啟", preferredStyle: .alert)
    
    let okAction = UIAlertAction(title: "確認", style: .default, handler: nil)
    
    alertController.addAction(okAction)
    
    self.present(alertController, animated: true, completion: nil)
  }
}

extension MapViewController: CLLocationManagerDelegate {
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    
    guard let currentLocation = locations.last else { return }
    //總縮放範圍
    let range: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)
    
    //自身
    let myLocation = currentLocation.coordinate
    
    let appearRegion: MKCoordinateRegion = MKCoordinateRegion(center: myLocation, span: range)
    
    //在地圖上顯示
    realTimeMap.setRegion(appearRegion, animated: true)
  }
  
  //  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
  //
  //    checkLocationAuth()
  //
  //  }
  //
  //  func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
  //
  //      self.selectAnnotation = view.annotation as? MKPointAnnotation
  //
  //  }
  //
  ////  func info(sender: UIButton) {
  ////      print(selectAnnotation?.coordinate)
  ////  }
  //
  //  func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
  //
  //    self.selectAnnotation = view.annotation as? MKPointAnnotation
  //
  //  }
  
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    
    if annotation is MKUserLocation {
      
      return nil
    }
    
    var customView = realTimeMap.dequeueReusableAnnotationView(withIdentifier: "custom") as? MKMarkerAnnotationView
    
    if customView == nil {
      
      customView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "custom")
    } else {
      
      customView?.annotation = annotation
    }
    
    customView?.markerTintColor = .green
    
//    customView?.glyphText = "Jim"
    
    customView?.glyphImage = UIImage(named: "Icons_24px_Close")
    
    customView?.selectedGlyphImage =  UIImage(named: "Icons_24px_Close")
    
    customView?.subtitleVisibility = .visible
    
    return customView
  }
}

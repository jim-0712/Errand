//
//  GoogleMapViewController.swift
//  Errand
//
//  Created by Jim on 2020/1/20.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import FirebaseAuth
import GoogleMaps
import CoreLocation

class GoogleMapViewController: UIViewController, CLLocationManagerDelegate {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont(name: "SeToFont", size: 17) as Any]
    
    if UserManager.shared.isTourist {
      
//      refreshBtn.isEnabled = false
      
    } else {
      
//      refreshBtn.isEnabled = true
      
      if let account = Auth.auth().currentUser?.email {
        
        UserManager.shared.readData(account: account) { result in
          
          switch result {
            
          case .success(let dataReturn):
            
            print(dataReturn)
            
            UserManager.shared.isPostTask = dataReturn.onTask
            
            UserManager.shared.currentUserInfo = dataReturn
            
          case .failure:
            
            return
          }
        }
      }
    }
    
    setUpLocation()
    
    checkLocationAuth()
    
    addAnnotation()
  }
  
  var path: GMSMutablePath!
  
  var count = 0
  
  @IBOutlet weak var googleMapView: GMSMapView!
  
  @IBOutlet weak var categoryCollection: UICollectionView!
  
  let myLocationManager = CLLocationManager()
  
  let directionManager = MapManager.shared
  
  let polyline = GMSPolyline()
  
  func setUpLocation() {
    
    myLocationManager.delegate = self
    
    googleMapView.delegate = self
    
    myLocationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters
    
    myLocationManager.desiredAccuracy = kCLLocationAccuracyBest
  }
  
  func checkLocationService() {
    
    if CLLocationManager.locationServicesEnabled() {
      
      checkLocationAuth()
      
    } else {
      
      alertOpen()
    }
  }
  
  func centerViewOnUserLocation() {
    
    guard let center = myLocationManager.location?.coordinate else { return }
    
    let myArrange = GMSCameraPosition.camera(withTarget: center, zoom: 15)
    
    googleMapView.camera = myArrange
    
  }
  
  func checkLocationAuth() {
    
    switch CLLocationManager.authorizationStatus() {
      
    case .authorizedWhenInUse:
      
      googleMapView.isMyLocationEnabled = true
      
      centerViewOnUserLocation()
      
      myLocationManager.startUpdatingLocation()
      
    case .denied:
      
      alertOpen()
      
    case .notDetermined:
      
      myLocationManager.requestWhenInUseAuthorization()
      
    case .authorizedAlways:
      
      googleMapView.isMyLocationEnabled = true
      
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
  
  func addAnnotation() {
    
    let marker1 = GMSMarker()
    marker1.position = CLLocationCoordinate2D(latitude: 25.0326708, longitude: 121.56953640000006)
    marker1.map = googleMapView
    
    //    getDirectionBack(origin: marker.position, destination: marker1.position)
    
//    getDirectionBack(origin: myLocationManager.location!.coordinate, destination: marker1.position)
  }
  
  func getDirectionBack(origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D) {
    
    directionManager.getDirection(origin: origin, destination: destination) { result in
      
      switch result {
        
      case .success(let result):
        
        for count in 0 ..< result.routes[0].legs[0].steps.count {
          
          let seperateDis = result.routes[0].legs[0].steps[count].duration.text.components(separatedBy: " 分鐘")

          guard let baseIntMIn = Int(seperateDis[0]) else { return }
          
          self.directionManager.totalMin += baseIntMIn
          
        }
        
        let routes = result.routes
        
        let routeOverviewPolyline = routes[0].overviewPolyline
        
        let points = routeOverviewPolyline.points
        DispatchQueue.main.async {
          
          let path = GMSPath.init(fromEncodedPath: points)
          
          self.polyline.path = path
          
          self.polyline.strokeWidth = 3
          
          self.polyline.strokeColor = UIColor.blue

          self.polyline.map = self.googleMapView
        }
        
      case .failure(let error):
        
        print(error.localizedDescription)
      }
      
    }
  }
  
}

extension GoogleMapViewController: GMSMapViewDelegate {
  
  func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
    print("Ninn")
  }
  
  func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
    return true
  }
  
//  func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
//  
//    print(position)
//    
//  }
  
}

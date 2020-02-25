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

protocol LocationManager: AnyObject {
  
  func locationReturn(viewController: AddLocationViewController, lat: Double, long: Double)
}

class AddLocationViewController: UIViewController, CLLocationManagerDelegate {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setUp()
    navigationItem.setHidesBackButton(true, animated: true)
    navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Icons_24px_Back02"), style: .plain, target: self, action: #selector(backToList))
    }
  
  @objc func backToList() {
    self.navigationController?.popViewController(animated: true)
    TaskManager.shared.address = ""
  }
  
  let myLocationManager = CLLocationManager()
  
  var addressFinal: String = ""
  
  var finalLat: Double = 0.0
  
  var finalLong: Double = 0.0
  
  @IBOutlet weak var pinImage: UIImageView!
  
  weak var delegate: LocationManager?
  
  @IBOutlet weak var confirmLocation: UIButton!
  
  @IBOutlet weak var addLocationMap: GMSMapView!
  
  @IBAction func checkThePosition(_ sender: Any) {
    
    let lat = "\(finalLat)"
    
    let long = "\(finalLong)"
    
    MapManager.shared.getLocation(latitude: lat, longitude: long) { [weak self](result) in
      
      guard let strongSelf = self else { return }
      
      switch result {
        
      case .success(let address):
        
        strongSelf.addressFinal = address.results[0].formattedAddress
        
        TaskManager.shared.address = address.results[0].formattedAddress
        
        DispatchQueue.main.async {
          
          strongSelf.alertCome(lat: strongSelf.finalLat, long: strongSelf.finalLong)
        }
        
      case .failure:
        
        print("No")
      }
    }
    
  }
  
  func setUp() {
    confirmLocation.layer.cornerRadius = confirmLocation.bounds.height / 2
    addLocationMap.delegate = self
    myLocationManager.delegate = self
    addLocationMap.isMyLocationEnabled = true
    myLocationManager.startUpdatingLocation()
    guard let center = myLocationManager.location?.coordinate else { return }
    let myArrange = GMSCameraPosition.camera(withTarget: center, zoom: 17)
    addLocationMap.camera = myArrange
    addLocationMap.animate(to: myArrange)
    finalLat = center.latitude
    finalLong = center.longitude
  }
  
  func alertCome(lat: Double, long: Double) {
    
    let controller = UIAlertController(title: "是否用以下地址", message: "\(addressFinal)", preferredStyle: .alert)
    
    let okAction = UIAlertAction(title: "好的", style: .default) { [weak self] (_) in
       
      guard let strongSelf = self else { return }
      
      strongSelf.delegate?.locationReturn(viewController: strongSelf, lat: lat, long: long)
      
      strongSelf.navigationController?.popViewController(animated: true)
      strongSelf.dismiss(animated: true, completion: nil)
    }
    
    controller.addAction(okAction)
    let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
    controller.addAction(cancelAction)
    
    present(controller, animated: true, completion: nil)
  }
}

extension AddLocationViewController: GMSMapViewDelegate {
  
  func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
    
    finalLat = position.target.latitude
    finalLong = position.target.longitude
  }
}

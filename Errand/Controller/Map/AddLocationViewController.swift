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
    navigationItem.leftBarButtonItem?.tintColor = .black
    }
  
  let myLocationManager = CLLocationManager()
  
  var addressFinal: String = ""
  
  var destnationLatitude: Double = 0.0
  
  var destinationLongtitude: Double = 0.0
  
  weak var delegate: LocationManager?
  
  @IBOutlet weak var pinImage: UIImageView!
  
  @IBOutlet weak var confirmLocation: UIButton!
  
  @IBOutlet weak var addLocationMap: GMSMapView!
  
  @IBAction func checkThePosition(_ sender: Any) {
    
    let lat = "\(destnationLatitude)"
    
    let long = "\(destinationLongtitude)"
    
    APImanager.shared.getLocation(latitude: lat, longitude: long) { [weak self](result) in
      
      guard let strongSelf = self else { return }
      
      switch result {
        
      case .success(let address):
        
        strongSelf.addressFinal = address.results[0].formattedAddress
        
        TaskManager.shared.address = address.results[0].formattedAddress
        
        DispatchQueue.main.async {
          
          strongSelf.alertCome(lat: strongSelf.destnationLatitude, long: strongSelf.destinationLongtitude)
        }
        
      case .failure:
        
        print("No")
      }
    }
    
  }
  
  @objc func backToList() {
    self.navigationController?.popViewController(animated: true)
    TaskManager.shared.address = ""
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
    destnationLatitude = center.latitude
    destinationLongtitude = center.longitude
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
    destnationLatitude = position.target.latitude
    destinationLongtitude = position.target.longitude
  }
}

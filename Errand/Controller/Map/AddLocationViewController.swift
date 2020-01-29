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

class AddLocationViewController: UIViewController, GMSMapViewDelegate, CLLocationManagerDelegate {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setUp()
  }
  
  let myLocationManager = CLLocationManager()
  
  var addressFinal: String = ""
  
  @IBOutlet weak var pinImage: UIImageView!
  
  weak var delegate: LocationManager?
  
  @IBOutlet weak var confirmLocation: UIButton!
  
  @IBOutlet weak var addLocationMap: GMSMapView!
  
  @IBAction func checkThePosition(_ sender: Any) {
    
    guard let center = myLocationManager.location?.coordinate else { return }
    
    let latitude = "\(center.latitude)"
       
    let longitude = "\(center.longitude)"
    
    MapManager.shared.getLocation(latitude: latitude, longitude: longitude) { [weak self](result) in
      
      guard let strongSelf = self else { return }
      
      switch result {
        
      case .success(let address):
        
        strongSelf.addressFinal = address.results[0].formattedAddress
        
        DispatchQueue.main.async {
          
          strongSelf.alertCome(lat: center.latitude, long: center.longitude)
        }
        
      case .failure:
        
        print("No")
      }
    }
    
  }
  
  func setUp() {
    
    addLocationMap.delegate = self
    
    myLocationManager.delegate = self
    
    guard let center = myLocationManager.location?.coordinate else { return }
    
    let myArrange = GMSCameraPosition.camera(withTarget: center, zoom: 15)
    
    addLocationMap.camera = myArrange
    
  }
  
  func alertCome(lat: Double, long: Double) {
    
    let controller = UIAlertController(title: "是否用以下地址", message: "\(addressFinal)", preferredStyle: .alert)
    
    let okAction = UIAlertAction(title: "好的", style: .default) { [weak self] (_) in
       
      guard let strongSelf = self else { return }
      
      strongSelf.delegate?.locationReturn(viewController: strongSelf, lat: lat, long: long)
      
      strongSelf.dismiss(animated: true, completion: nil)
    }
    
    controller.addAction(okAction)
    
    let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
    
    controller.addAction(cancelAction)
    
    present(controller, animated: true, completion: nil)
  }
}

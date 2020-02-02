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
    
    setupCollectin()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    
    super.viewWillAppear(animated)
    
     getTaskData()
  }
  
  @IBOutlet weak var googleMapView: GMSMapView!
  
  @IBOutlet weak var categoryCollection: UICollectionView!
  
  var path: GMSMutablePath!
  
  var count = 0
  
  let myLocationManager = CLLocationManager()
  
  let directionManager = MapManager.shared
  
  let screenwidth = UIScreen.main.bounds.width
  
  let screenheight = UIScreen.main.bounds.height
  
  var specificData = [TaskInfo]()
  
  var taskDataReturn = [TaskInfo]() {
    
    didSet {
      addAnnotation()
      
    }
  }
  
  let polyline = GMSPolyline()
  
  func getTaskData() {
    
    TaskManager.shared.taskData = []
    
    TaskManager.shared.readData { [weak self] result in
      
      guard let strongSelf = self else { return }
      
      switch result {
        
      case .success(let taskData):
        
        strongSelf.taskDataReturn = taskData
        
        print(strongSelf.taskDataReturn)
        
        LKProgressHUD.dismiss()
        
      case .failure(let error):
        
        LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
      }
    }
  }
  
  func setupCollectin() {
    
    let nibCell = UINib(nibName: "CategoryCollectionViewCell", bundle: nil)
    
    categoryCollection.register(nibCell, forCellWithReuseIdentifier: "category")
    
    categoryCollection.delegate = self
    
    categoryCollection.dataSource = self
  }
  
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
    
    let myArrange = GMSCameraPosition.camera(withTarget: center, zoom: 17)
    
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
    
      taskDataReturn.map { info in
      
      let marker = GMSMarker()
      
      marker.position = CLLocationCoordinate2D(latitude: info.lat, longitude: info.long)
      
      let markerTitle = TaskManager.shared.filterClassified(classified: info.classfied)
      
      marker.title =  markerTitle[0]
      
      marker.snippet = info.nickname
      
      marker.map = googleMapView
      
    }
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
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
    if segue.identifier == "taskDetail" {
      
      guard let detailVC = segue.destination as? MissionDetailViewController else { return }
      
      let time = Date.init(timeIntervalSince1970: TimeInterval((specificData[0].time)))
      
      let dateFormatter = DateFormatter()
      
      dateFormatter.dateFormat = "yyyy-MM-dd hh:mm"
      
      let timeConvert = dateFormatter.string(from: time)
      
      detailVC.modalPresentationStyle = .fullScreen
      
      detailVC.detailData = specificData[0]
      
      detailVC.receiveTime = timeConvert
    }
  }
}

extension GoogleMapViewController: GMSMapViewDelegate {
  
  func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {

    print(marker.title)
    print("Ninn")
  }
  
//  func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
//    
//    guard let nickName = marker.snippet,
//      let classified = marker.title else { return true }
//      var counter = 0
//    
//    for count in 0 ..< TaskManager.shared.taskClassified.count {
//      
//      if TaskManager.shared.taskClassified[count].title == classified {
//        
//        counter = count
//        
//        break
//      } else {
//        continue
//      }
//    }
//    
//    specificData = taskDataReturn.filter { (info) -> Bool in
//      
//      return info.nickname == nickName && info.classfied == counter
//  
//    }
//    
//    self.performSegue(withIdentifier: "taskDetail", sender: nil)
//  
//    return true
//  }
}

extension GoogleMapViewController: UICollectionViewDelegate, UICollectionViewDataSource {
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    
    return TaskManager.shared.taskClassified.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "category", for: indexPath) as? CategoryCollectionViewCell else { return UICollectionViewCell() }
    
    cell.setUpContent(label: TaskManager.shared.taskClassified[indexPath.row].title, color: TaskManager.shared.taskClassified[indexPath.row].color)
    
    return cell
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    
    if indexPath.row == 0 {
      
      self.getTaskData()
    } else {
      
      TaskManager.shared.taskData = []
      
      TaskManager.shared.readSpecificData(classified: indexPath.row - 1) { [weak self] result in
        
        guard let strongSelf = self else { return }
        
        switch result {
          
        case .success(let taskData):
          
          print(taskData.count)
          
          strongSelf.taskDataReturn = taskData
          
          LKProgressHUD.dismiss()
          
        case .failure(let error):
          
          LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
        }
      }
    }
  }
}

extension GoogleMapViewController: UICollectionViewDelegateFlowLayout {
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    
    return CGSize(width: screenwidth / 2.5, height: screenheight / 20)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    
    return UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
  }
}

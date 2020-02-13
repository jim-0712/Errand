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
    
    NotificationCenter.default.addObserver(self, selector: #selector(reGetUserInfo), name: Notification.Name("postMission"), object: nil)
    
    NotificationCenter.default.addObserver(self, selector: #selector(reGetUserInfo), name: Notification.Name("finishTask"), object: nil)
    
    
    if UserManager.shared.isTourist {
      
      //      refreshBtn.isEnabled = false
      
    } else {
      LKProgressHUD.show(controller: self)
      //      refreshBtn.isEnabled = true
    }
    setUpView()
    changeConstraints()
    setUpLocation()
    checkLocationAuth()
    setupCollectin()
    
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    loadUserInfo()
    getTaskData()
  }
  
  func getStatusOne() {
    guard let user = UserManager.shared.currentUserInfo else { return }
    if user.status == 1 {
      TaskManager.shared.readSpecificData(parameter: "uid", parameterString: user.uid) { result in
        switch result {
        case .success(let task):
          TaskManager.shared.statusOneData = task[0]
        case .failure(let error):
          LKProgressHUD.showFailure(text: error.localizedDescription, controller: self)
        }
      }
    }
  }
  
  @objc func reGetUserInfo() {
    loadUserInfo()
  }
  
  func loadUserInfo() {
    
    if let uid = Auth.auth().currentUser?.uid {
      
      UserManager.shared.readData(uid: uid) { result in
        
        switch result {
          
        case .success(let dataReturn):
          
          LKProgressHUD.dismiss()
          UserManager.shared.isPostTask = dataReturn.onTask
          UserManager.shared.currentUserInfo = dataReturn
          self.getStatusOne()
          
        case .failure:
          
          return
        }
      }
    }
  }
  
  @IBOutlet weak var googleMapView: GMSMapView!
  
  @IBOutlet weak var categoryCollection: UICollectionView!
  
  @IBOutlet weak var invisibleView: UIView!
  
  @IBOutlet weak var invisibleBottomCons: NSLayoutConstraint!
  
  @IBOutlet weak var taskPersonPhoto: UIImageView!
  
  @IBOutlet weak var authorLabel: UILabel!
  
  @IBOutlet weak var taskClassifiedLabel: UILabel!
  
  @IBOutlet weak var priceLabel: UILabel!
  
  @IBOutlet weak var distanceLabel: UILabel!
  
  @IBOutlet weak var pageView: UIView!
  
  @IBOutlet weak var checkDetailBtn: UIButton!
  
  @IBOutlet weak var backBtn: UIButton!
  
  @IBOutlet weak var searchView: UIView!
  
  @IBOutlet weak var arrangeLabel: UILabel!
  
  @IBOutlet weak var arrangeTextField: UITextField!
  
  @IBOutlet weak var searchBtn: UIButton!
  
  @IBAction func radarAct(_ sender: Any) {
    isSearch = !isSearch
    searchView.isHidden = isSearch
  }
  
  @IBAction func dismissSearchAct(_ sender: Any) {
    isSearch = !isSearch
    searchView.isHidden = isSearch
  }
  
  @IBAction func searchAct(_ sender: Any) {
    
    guard let kilo = arrangeTextField.text,
      let kiloDouble = Double(kilo) else { return }
    
    googleMapView.clear()
    
    TaskManager.shared.readData { [weak self] result in
      
      guard let strongSelf = self else { return }
      
      switch result {
        
      case .success(let taskData):
        
        TaskManager.shared.taskData = []
        
        strongSelf.taskDataReturn = taskData.filter({ [weak self] info in
          
          guard let strongSelf = self else { return false }
          
          let distance = MapManager.shared.getDistance(lat1: info.lat, lng1: info.long, lat2: strongSelf.finalLat, lng2: strongSelf.finalLong)
          
          if strongSelf.currentClassified == 0 && distance <= kiloDouble {
            
            return true
          } else if distance <= kiloDouble && info.classfied == strongSelf.currentClassified {
            
            return true
          } else {
            
            return false
          }
        })
        
      case .failure(let error):
        
        LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
      }
    }
    addAnnotation()
    isSearch = !isSearch
    searchView.isHidden = isSearch
  }
  
  @IBAction func backAct(_ sender: Any) {
    isTapOnContent = !isTapOnContent
    changeConstraints()
  }
  
  @IBAction func checkDetailAct(_ sender: Any) {
    
    performSegue(withIdentifier: "Mapdetail", sender: nil)
  }

  var currentClassified = 0
  
  var finalLat: Double = 0.0
  
  var finalLong: Double = 0.0
  
  var isSearch: Bool = false
  
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
  //  let polyline = GMSPolyline()
  
  var isTapOnContent: Bool = false
  
  func changeConstraints() {
    
    if isTapOnContent {
      
      let move = UIViewPropertyAnimator(duration: 1.0, curve: .easeInOut) {
        self.invisibleBottomCons.constant = 0
      }
      move.startAnimation()
    } else {
      
      let move = UIViewPropertyAnimator(duration: 1.0, curve: .easeInOut) {
        
        self.invisibleBottomCons.constant = 170
      }
      move.startAnimation()
    }
  }
  
  func getTaskData() {

    TaskManager.shared.readData { [weak self] result in
      
      guard let strongSelf = self else { return }
      
      switch result {
        
      case .success(let taskData):
        
        strongSelf.taskDataReturn = taskData
        TaskManager.shared.taskData = []
        
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
  
  func setUpView() {
    taskPersonPhoto.layer.cornerRadius = taskPersonPhoto.bounds.width / 2
    pageView.layer.cornerRadius = pageView.bounds.height / 10
    pageView.layer.shadowOpacity = 0.2
    pageView.layer.shadowOffset = CGSize(width: 3, height: 3)
    checkDetailBtn.layer.borderWidth = 1.0
    checkDetailBtn.layer.borderColor = UIColor.G1?.cgColor
    checkDetailBtn.layer.cornerRadius = checkDetailBtn.bounds.height / 4
    backBtn.layer.cornerRadius = backBtn.bounds.height / 2
    isSearch = true
    searchView.isHidden = isSearch
    searchView.layer.shadowOpacity = 0.5
    searchView.layer.shadowOffset = CGSize(width: 3, height: 3)
    searchView.layer.cornerRadius = searchView.bounds.height / 10
    searchBtn.layer.cornerRadius = searchBtn.bounds.height / 10
    searchBtn.layer.shadowOpacity = 0.5
    searchBtn.layer.shadowOffset = CGSize(width: 3, height: 3)
    arrangeTextField.layer.shadowOpacity = 0.5
    arrangeTextField.layer.shadowOffset = CGSize(width: 3, height: 3)
  }
  
  @IBAction func reloadLocation(_ sender: Any) {
    guard let center = myLocationManager.location?.coordinate else { return }
    let myArrange = GMSCameraPosition.camera(withTarget: center, zoom: 17)
    googleMapView.camera = myArrange
  }
  
  func setUpLocation() {
//    googleMapView.settings.compassButton = true
//    googleMapView.settings.myLocationButton = true
//    googleMapView.isMyLocationEnabled = true
    myLocationManager.delegate = self
    googleMapView.delegate = self
    myLocationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters
    myLocationManager.desiredAccuracy = kCLLocationAccuracyBest
    
    guard let lat = myLocationManager.location?.coordinate.latitude,
         let long = myLocationManager.location?.coordinate.longitude else { return }
    
    finalLong = long
    finalLat = lat
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
    
    for info in taskDataReturn {
      
      let marker = GMSMarker()
      marker.position = CLLocationCoordinate2D(latitude: info.lat, longitude: info.long)
      let markerTitle = TaskManager.shared.filterClassified(classified: info.classfied + 1)
      marker.title =  markerTitle[0]
      marker.snippet = info.nickname
      marker.map = googleMapView
    }
//    taskDataReturn.map { info in
//
//      let marker = GMSMarker()
//      marker.position = CLLocationCoordinate2D(latitude: info.lat, longitude: info.long)
//      let markerTitle = TaskManager.shared.filterClassified(classified: info.classfied + 1)
//      marker.title =  markerTitle[0]
//      marker.snippet = info.nickname
//      marker.map = googleMapView
//    }
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
    if segue.identifier == "Mapdetail" {
      guard let detailVC = segue.destination as? MissionDetailViewController else { return }
      detailVC.modalPresentationStyle = .fullScreen
      
      detailVC.detailData = specificData[0]
      detailVC.receiveTime =  TaskManager.shared.timeConverter(time: specificData[0].time)
    }
  }
}

extension GoogleMapViewController: GMSMapViewDelegate {
  
  func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
    
//    isTapOnContent = !isTapOnContent
    
    isTapOnContent = true
    
    guard let snippet = marker.snippet,
      let classified = marker.title,
      let lat = myLocationManager.location?.coordinate.latitude,
      let long = myLocationManager.location?.coordinate.longitude else { return }
    
      let classifiedReturn = TaskManager.shared.filterClassifiedToInt(task: classified) - 1
    
    for count in 0 ..< taskDataReturn.count {
      
      let info = taskDataReturn[count]
      
      if info.nickname == snippet && info.classfied == classifiedReturn {
        
        self.specificData = [info]
        
        let distance = MapManager.shared.getDistance(lat1: info.lat, lng1: info.long, lat2: lat, lng2: long)
        
        let returnString = String(format: "%.2f", distance)
        
        taskPersonPhoto.loadImage(info.personPhoto, placeHolder: UIImage(named: "photographer"))
        authorLabel.text = info.nickname
        taskClassifiedLabel.text = classified
        priceLabel.text = "\(info.money)元"
        distanceLabel.text = "\(returnString) km"
      }
    }
    changeConstraints()
  }
  
  func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
    finalLat = position.target.latitude
    finalLong = position.target.longitude
  }
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
    
    googleMapView.clear()
    
    if indexPath.row == 0 {
      
      currentClassified = 0
      
      self.getTaskData()
    } else {
      
      currentClassified = indexPath.row
      TaskManager.shared.taskData = []
      
      TaskManager.shared.readSpecificData(parameter: "classfied", parameterDataInt: indexPath.row - 1) { [weak self] result in
        
        guard let strongSelf = self else { return }
        
        switch result {
          
        case .success(let taskData):
          
          strongSelf.taskDataReturn = taskData
          
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

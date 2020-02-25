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

class GoogleMapViewController: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    NotificationCenter.default.addObserver(self, selector: #selector(loadUser), name: Notification.Name("postMission"), object: nil)
    
    NotificationCenter.default.addObserver(self, selector: #selector(loadUser), name: Notification.Name("reloadUser"), object: nil)
    
    NotificationCenter.default.addObserver(self, selector: #selector(reGetUserInfo), name: Notification.Name("update"), object: nil)
    
    arrangeTextField.delegate = self

    setUpView()
    changeConstraints()
    setUpLocation()
    checkLocationAuth(isRadar: false)
    setupCollectin()
    searchView.isHidden = true
    judge[0] = true
    
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if UserManager.shared.isTourist {
      
    } else {
      loadUserInfo()
    }
    getTaskData()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    guard let tabVC = self.view.window?.rootViewController as? TabBarViewController else { return }
    LKProgressHUD.show(controller: tabVC)
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    taskPersonPhoto.layer.cornerRadius = taskPersonPhoto.bounds.width / 2
  }
  
  @objc func reGetUserInfo() {
    loadUserInfo()
  }
  
  func loadUserInfo() {
    
    if let uid = Auth.auth().currentUser?.uid {
      
      UserManager.shared.readData(uid: uid) { result in
        
        switch result {
          
        case .success(let dataReturn):
          
          UserManager.shared.isPostTask = dataReturn.onTask
          UserManager.shared.currentUserInfo = dataReturn
          LKProgressHUD.dismiss()
        case .failure:
          LKProgressHUD.dismiss()
          return
        }
      }
    }
  }
  
  @objc func loadUser() {
    if let uid = Auth.auth().currentUser?.uid {
      
      UserManager.shared.readData(uid: uid) { result in
        
        switch result {
          
        case .success(let dataReturn):
          
          LKProgressHUD.dismiss()
          UserManager.shared.isPostTask = dataReturn.onTask
          UserManager.shared.currentUserInfo = dataReturn
        case .failure:
          LKProgressHUD.dismiss()
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
  
  @IBOutlet weak var backgroundView: UIView!
  
  @IBOutlet weak var radarBackView: UIView!
  
  @IBOutlet weak var searchView: UIView!
  
  @IBOutlet weak var arrangeLabel: UILabel!
  
  @IBOutlet weak var arrangeTextField: UITextField!
  
  @IBOutlet weak var searchBtn: UIButton!
  
  var isLocation = false
  
  var judge = [Bool](repeating: false, count: 9)
  
  @IBAction func radarAct(_ sender: Any) {
    if CLLocationManager.locationServicesEnabled() {
      checkLocationAuth(isRadar: true)
      
    } else {
      alertOpen()
    }
  }
  
  @IBAction func dismissSearchAct(_ sender: Any) {
    isSearch = !isSearch
    self.view.endEditing(true)
    self.resignFirstResponder()
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
      LKProgressHUD.dismiss()
      addAnnotation()
    }
  }

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
        LKProgressHUD.dismiss()
        LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
      }
    }
  }
  
  func setupCollectin() {
    let nibCell = UINib(nibName: "CategoryCollectionViewCell", bundle: nil)
    categoryCollection.register(nibCell, forCellWithReuseIdentifier: "category")
    categoryCollection.delegate = self
    categoryCollection.dataSource = self
    categoryCollection.backgroundColor = .clear
  }
  
  func setUpView() {
    isSearch = false
    searchView.isHidden = isSearch
    pageView.layer.shadowOpacity = 0.2
    searchBtn.layer.shadowOpacity = 0.5
    searchView.layer.shadowOpacity = 0.5
    backgroundView.layer.shadowOpacity = 0.5
    radarBackView.layer.shadowOpacity = 0.5
    checkDetailBtn.layer.borderWidth = 1.0
    arrangeTextField.layer.shadowOpacity = 0.5
    checkDetailBtn.layer.borderColor = UIColor.G1?.cgColor
    backBtn.layer.cornerRadius = backBtn.bounds.height / 2
    pageView.layer.cornerRadius = pageView.bounds.height / 10
    searchBtn.layer.cornerRadius = searchBtn.bounds.height / 10
    searchView.layer.cornerRadius = searchView.bounds.height / 10
    radarBackView.layer.cornerRadius = radarBackView.bounds.width / 2
    backgroundView.layer.cornerRadius = backgroundView.bounds.width / 2
    pageView.layer.shadowOffset = CGSize(width: 3, height: 3)
    searchBtn.layer.shadowOffset = CGSize(width: 3, height: 3)
    searchView.layer.shadowOffset = CGSize(width: 3, height: 3)
    backgroundView.layer.shadowOffset = .zero
    radarBackView.layer.shadowOffset = .zero
    backgroundView.backgroundColor = .white
    radarBackView.backgroundColor = .white
    checkDetailBtn.layer.cornerRadius = checkDetailBtn.bounds.height / 4
    arrangeTextField.layer.shadowOffset = CGSize(width: 3, height: 3)
    taskPersonPhoto.layer.cornerRadius = taskPersonPhoto.bounds.width / 2
  }
  
  @IBAction func reloadLocation(_ sender: Any) {
    
    if CLLocationManager.locationServicesEnabled() {
      checkLocationAuth(isRadar: false)
      isSearch = !isSearch
      searchView.isHidden = true
    } else {
      alertOpen()
    }
    
    if isLocation {
      guard let center = myLocationManager.location?.coordinate else { return }
      let myArrange = GMSCameraPosition.camera(withTarget: center, zoom: 17)
      googleMapView.camera = myArrange
    }
  }
  
  func setUpLocation() {
    
    guard let lat = myLocationManager.location?.coordinate.latitude,
      let long = myLocationManager.location?.coordinate.longitude else { return }
    
    finalLat = lat
    finalLong = long
    googleMapView.delegate = self
    myLocationManager.delegate = self
    myLocationManager.desiredAccuracy = kCLLocationAccuracyBest
    myLocationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters
  }
  
  func checkLocationService() {
    
    if UserManager.shared.isTourist {
      
    } else {
      if CLLocationManager.locationServicesEnabled() {
        checkLocationAuth(isRadar: false)
      } else {
        alertOpen()
      }
    }
  }
  
  func centerViewOnUserLocation() {
    guard let center = myLocationManager.location?.coordinate else { return }
    let myArrange = GMSCameraPosition.camera(withTarget: center, zoom: 17)
    googleMapView.camera = myArrange
    googleMapView.animate(to: myArrange)
  }
  
  func checkLocationAuth(isRadar: Bool) {
    
    switch CLLocationManager.authorizationStatus() {
      
    case .authorizedWhenInUse:
      
      if !isRadar {
        centerViewOnUserLocation()
      }
      googleMapView.isMyLocationEnabled = true
      myLocationManager.startUpdatingLocation()
      isSearch = !isSearch
      searchView.isHidden = isSearch
      isLocation = true
      
    case .denied:
      
      SwiftMes.shared.showWarningMessage(body: "請至 設定 > 隱私權 > 定位服務 開啟定位服務", seconds: 1.0)
      
    case .notDetermined:
      
      myLocationManager.requestWhenInUseAuthorization()
      
    case .authorizedAlways:
      
      if !isRadar {
        centerViewOnUserLocation()
      }
      myLocationManager.startUpdatingLocation()
      googleMapView.isMyLocationEnabled = true
      isSearch = !isSearch
      searchView.isHidden = isSearch
      isLocation = true
      
    case .restricted:
  
      SwiftMes.shared.showWarningMessage(body: "請至 設定 > 隱私權 > 定位服務 開啟定位服務", seconds: 1.0)
      
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
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
    if segue.identifier == "Mapdetail" {
      guard let detailVC = segue.destination as? MissionDetailViewController else { return }
      detailVC.modalPresentationStyle = .fullScreen
      detailVC.detailData = specificData[0]
      detailVC.isNavi = true
      detailVC.receiveTime =  TaskManager.shared.timeConverter(time: specificData[0].time)
    }
  }
}

extension GoogleMapViewController: GMSMapViewDelegate {
  
  func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
    
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
    
    if judge[indexPath.row] {
      cell.contentView.backgroundColor = UIColor(red: 246.9/255.0, green: 212.0/255.0, blue: 95.0/255.0, alpha: 1.0)
    } else {
      cell.contentView.backgroundColor = UIColor.G1
    }
    
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
    
    judge = [Bool](repeating: false, count: 9)
    judge[indexPath.row] = true
    self.categoryCollection.reloadData()
  }
}

extension GoogleMapViewController: UICollectionViewDelegateFlowLayout {
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(width: screenwidth / 2.5, height: screenheight / 20)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return UIEdgeInsets(top: 5, left: 20, bottom: 0, right: 20)
  }
}

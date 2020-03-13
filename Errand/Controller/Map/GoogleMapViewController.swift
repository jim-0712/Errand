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
import Fabric
import FirebaseAnalytics
import Crashlytics

class GoogleMapViewController: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate {
  
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
  
  let segueMapdetail = "Mapdetail"
  
  var isLocationAuthOn = false
  
  var missionClassifiedIndex = 0
  
  var currentPositionLatitude: Double = 0.0
  
  var currentPositionLongtitude: Double = 0.0
  
  var isOnSearch: Bool = false
  
  let myLocationManager = CLLocationManager()
  
  let directionManager = APImanager.shared
  
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
  
  var preventReuseCellBug = [Bool](repeating: false, count: 9)
  
  override func viewDidLoad() {
    super.viewDidLoad()
    fetchTaskData()
    arrangeTextField.delegate = self
    preSetup()
    changeConstraints()
    setUpLocation()
    checkLocationAuth(isRadar: false)
    searchView.isHidden = true
    preventReuseCellBug[0] = true
  }
  
  func preSetup() {
    setUpBtn()
    setUpView()
    setUpPageView()
    setUpRadarView()
    setupCollectin()
    setUpSearchView()
    setUpArrangeTextField()
  }
  
  @IBAction func tapRadarCheckAuth(_ sender: Any) {
    if CLLocationManager.locationServicesEnabled() {
      checkLocationAuth(isRadar: true)
    } else {
      alertOpen()
    }
  }
  
  @IBAction func dismissSearchAct(_ sender: Any) {
    isOnSearch = !isOnSearch
    self.view.endEditing(true)
    self.resignFirstResponder()
    arrangeTextField.text = ""
    searchView.isHidden = isOnSearch
  }
  
  @IBAction func tapSearchMission(_ sender: Any) {
    
    guard let limit = arrangeTextField.text,
         let limitDistance = Double(limit) else { return }
    
    googleMapView.clear()
    TaskManager.shared.fetchTaskData { [weak self] result in
      guard let strongSelf = self else { return }
      switch result {
        
      case .success(let taskData):
        
        TaskManager.shared.taskData = []
        strongSelf.taskDataReturn = taskData.filter({ [weak self] info in
          guard let strongSelf = self else { return false }
          let distance = APImanager.shared.getDistance(lat1: info.lat, lng1: info.long, lat2: strongSelf.currentPositionLatitude, lng2: strongSelf.currentPositionLongtitude)
          
          if strongSelf.missionClassifiedIndex == 0 && distance <= limitDistance {
            return true
          } else if distance <= limitDistance && info.classfied == strongSelf.missionClassifiedIndex {
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
    isOnSearch = !isOnSearch
    searchView.isHidden = isOnSearch
  }
  
  @IBAction func backAct(_ sender: Any) {
    isTapOnContent = !isTapOnContent
    changeConstraints()
  }
  
  @IBAction func checkDetailAct(_ sender: Any) {
    guard let missionDetailVC = UIStoryboard.init(name: "Mission", bundle: nil).instantiateViewController(withIdentifier: "detailViewController") as? MissionDetailViewController else { return }
         missionDetailVC.isMap = true
         missionDetailVC.detailData = specificData[0]
         missionDetailVC.receiveTime =  TaskManager.shared.timeConverter(time: specificData[0].time)
     
    self.present(missionDetailVC, animated: true, completion: nil)
  }
  
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
  
  func fetchTaskData() {
    
    TaskManager.shared.fetchTaskData { [weak self] result in
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
  
  func setUpSearchView() {
    searchView.isHidden = isOnSearch
    searchView.layer.shadowOpacity = 0.5
    searchView.layer.cornerRadius = searchView.bounds.height / 10
    searchView.layer.shadowOffset = CGSize(width: 3, height: 3)
  }
  
  func setUpRadarView() {
    radarBackView.backgroundColor = .white
    radarBackView.backgroundColor = .white
    radarBackView.layer.shadowOpacity = 0.5
    radarBackView.layer.shadowOffset = .zero
    radarBackView.layer.cornerRadius = radarBackView.bounds.width / 2
  }
  
  func setUpPageView() {
    pageView.layer.shadowOpacity = 0.2
    pageView.layer.cornerRadius = pageView.bounds.height / 10
    pageView.layer.shadowOffset = CGSize(width: 3, height: 3)
  }
  
  func setUpArrangeTextField() {
    arrangeTextField.layer.shadowOpacity = 0.5
    arrangeTextField.layer.shadowOffset = CGSize(width: 3, height: 3)
  }
  
  func setUpBtn() {
    searchBtn.layer.shadowOpacity = 0.5
    searchBtn.layer.cornerRadius = searchBtn.bounds.height / 10
    searchBtn.layer.shadowOffset = CGSize(width: 3, height: 3)
    checkDetailBtn.layer.borderWidth = 1.0
    checkDetailBtn.layer.borderColor = UIColor.G1?.cgColor
    checkDetailBtn.layer.cornerRadius = checkDetailBtn.bounds.height / 4
    backBtn.layer.cornerRadius = backBtn.bounds.height / 2
  }
  
  func setUpView() {
    isOnSearch = false
    backgroundView.backgroundColor = .white
    backgroundView.layer.shadowOpacity = 0.5
    backgroundView.layer.shadowOffset = .zero
    backBtn.layer.cornerRadius = backBtn.bounds.height / 2
    backgroundView.layer.cornerRadius = backgroundView.bounds.width / 2
    taskPersonPhoto.layer.cornerRadius = taskPersonPhoto.bounds.width / 2
  }
  
  @IBAction func reloadLocation(_ sender: Any) {
    if CLLocationManager.locationServicesEnabled() {
      checkLocationAuth(isRadar: false)
      isOnSearch = !isOnSearch
      searchView.isHidden = true
    } else {
      alertOpen()
    }
    
    if isLocationAuthOn {
      guard let center = myLocationManager.location?.coordinate else { return }
      let myArrange = GMSCameraPosition.camera(withTarget: center, zoom: 17)
      googleMapView.camera = myArrange
    }
  }
  
  func setUpLocation() {
    
    guard let lat = myLocationManager.location?.coordinate.latitude,
         let long = myLocationManager.location?.coordinate.longitude else { return }
    
    currentPositionLatitude = lat
    currentPositionLongtitude = long
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
      isOnSearch = !isOnSearch
      searchView.isHidden = isOnSearch
      isLocationAuthOn = true
      
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
      isOnSearch = !isOnSearch
      searchView.isHidden = isOnSearch
      isLocationAuthOn = true
      
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
        
        let distance = APImanager.shared.getDistance(lat1: info.lat, lng1: info.long, lat2: lat, lng2: long)
        
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
    currentPositionLatitude = position.target.latitude
    currentPositionLongtitude = position.target.longitude
  }
}

extension GoogleMapViewController: UICollectionViewDelegate, UICollectionViewDataSource {
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return TaskManager.shared.taskClassified.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "category", for: indexPath) as? CategoryCollectionViewCell else { return UICollectionViewCell() }
    let classified = TaskManager.shared.taskClassified
    cell.setUpContent(label: classified[indexPath.row].title, color: classified[indexPath.row].color)
    cell.contentView.backgroundColor = preventReuseCellBug[indexPath.row] ? UIColor.Y1 : UIColor.LG2
    return cell
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    
    googleMapView.clear()
    
    if indexPath.row == 0 {
      
      missionClassifiedIndex = 0
      
      self.fetchTaskData()
    } else {
      
      missionClassifiedIndex = indexPath.row
      TaskManager.shared.taskData = []
      TaskManager.shared.fetchSpecificData(parameter: "classfied", parameterDataInt: indexPath.row - 1) { [weak self] result in
        guard let strongSelf = self else { return }
        switch result {
        case .success(let taskData):
          strongSelf.taskDataReturn = taskData
          
        case .failure(let error):
          LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
        }
      }
    }
    
    preventReuseCellBug = [Bool](repeating: false, count: 9)
    preventReuseCellBug[indexPath.row] = true
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

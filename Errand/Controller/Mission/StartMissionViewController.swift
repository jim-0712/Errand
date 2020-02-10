//
//  StartMissionViewController.swift
//  Errand
//
//  Created by Jim on 2020/2/7.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import GoogleMaps
import CoreLocation
import FirebaseAuth

class StartMissionViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTable()
//        setUpCamera()
        // Do any additional setup after loading the view.
    }
  
  let myLocationManager = CLLocationManager()
  
  @IBOutlet weak var infoTableView: UITableView!
  
  var receiveTime: String?
  
  var detailData: TaskInfo?
  
  @IBOutlet weak var mapView: GMSMapView!
  
  func setUpTable() {
    
    infoTableView.delegate = self
    infoTableView.dataSource = self
    infoTableView.register(UINib(nibName: "StartMissionTableViewCell", bundle: nil), forCellReuseIdentifier: "startMission")
  }
  
//  func setUpCamera() {
//    guard let center = myLocationManager.location?.coordinate else { return }
//    let myArrange = GMSCameraPosition.camera(withTarget: center, zoom: 17)
//    mapView.camera = myArrange
//  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
    if segue.identifier == "chat" {
      guard let chatroomVC = segue.destination as? ChatViewController,
           let data = detailData else { return }
      
        chatroomVC.modalPresentationStyle = .fullScreen
        chatroomVC.detailData = data

      }
  }

}

extension StartMissionViewController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    guard let cell = tableView.dequeueReusableCell(withIdentifier: "startMission", for: indexPath) as? StartMissionTableViewCell,
         let taskData = detailData  else { return UITableViewCell() }
    
    let classified = TaskManager.shared.filterClassified(classified: taskData.classfied + 1)
    
    cell.setUp(ownerImage: taskData.personPhoto, author: taskData.nickname, classified: classified[0], price: taskData.money)
    
    cell.tapOnButton = { 
      
      self.performSegue(withIdentifier: "chat", sender: nil)
    }
    return cell
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 140
  }
}

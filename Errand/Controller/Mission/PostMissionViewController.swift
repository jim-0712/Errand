//
//  PostMissionViewController.swift
//  Errand
//
//  Created by Jim on 2020/1/23.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import AVKit
import SwiftMessages
import Kingfisher
import MobileCoreServices
import CoreLocation
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import IQKeyboardManager

struct MediaManager {
  
  let type: Int
  
  let mediaURL: String
}

class PostMissionViewController: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate, UITextViewDelegate {
  
  @IBOutlet weak var giveUpBtn: UIButton!
  
  @IBOutlet weak var fixBtn: UIButton!
  
  @IBOutlet weak var editMissionStackView: UIStackView!
  
  @IBOutlet weak var changeAddressBtn: UIButton!
  
  @IBAction func changeAddressAct(_ sender: Any) {
    
    performSegue(withIdentifier: "addlocation", sender: nil)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setUpSetting()
    setUpall()
    judge[0] = true
    navigationItem.setHidesBackButton(true, animated: true)
    navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Icons_24px_Back02"), style: .plain, target: self, action: #selector(backToList))
    navigationItem.leftBarButtonItem?.tintColor = .black
  }
  
  @objc func backToList() {
    self.navigationController?.popViewController(animated: true)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if TaskManager.shared.address == "" {
      changeAddressBtn.isHidden = true
      pinImage.isHidden = false
      plusBtn.isHidden = false
    } else {
      changeAddressBtn.isHidden = false
      pinImage.isHidden = true
      plusBtn.isHidden = true
      addressLabel.text = TaskManager.shared.address
    }
    missionContentTextView.clipsToBounds = true
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    TaskManager.shared.address = ""
  }
  
  func setUpDetail() {
    guard let taskInfo = statusOneData else { return }
    isChange = true
    latitude = taskInfo.lat
    longitude = taskInfo.long
    fileURL = taskInfo.taskPhoto
    fileType = taskInfo.fileType
    priceTextField.text = "\(taskInfo.money)"
    missionContentTextView.text = taskInfo.detail
    
    for count in 0 ..< taskInfo.taskPhoto.count {
      
      let seperate = taskInfo.taskPhoto[count].components(separatedBy: "jpeg")
      
      if seperate.count > 1 {
        guard let url = URL(string: fileURL[count]) else { return }
        guard let data = try? Data(contentsOf: url) else { return }
        guard let image = UIImage(data: data) else { return }
        fileURLmix.append(image)
      } else {
        guard let url = URL(string: fileURL[count]) else { return }
        fileURLmix.append(url as NSURL)
      }
    }
    photoCollectionView.reloadData()
    LKProgressHUD.dismiss()
  }
  
  @IBOutlet weak var pinImage: UIImageView!
  
  @IBOutlet weak var plusBtn: UIButton!
  
  @IBOutlet weak var photoCollectionView: UICollectionView!
  
  @IBOutlet weak var photoUploadText: UILabel!
  
  @IBOutlet weak var chooseGroupText: UILabel!
  
  @IBOutlet weak var missionGroupCollectionView: UICollectionView!
  
  @IBOutlet weak var uploadPhotoBtn: UIButton!
  
  @IBOutlet weak var editBackBtn: UIButton!
  
  @IBOutlet weak var priceLabel: UILabel!
  
  @IBOutlet weak var priceTextField: UITextField!
  
  @IBOutlet weak var missionLabel: UILabel!
  
  @IBOutlet weak var missionContentTextView: UITextView!
  
  @IBOutlet weak var postBtn: UIButton!
  
  @IBOutlet weak var stackNTDView: UIStackView!
  
  @IBOutlet weak var addressLabel: UILabel!
  
  @IBAction func editBackAct(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func postAct(_ sender: Any) {
    postMissionAct(isPost: true)
  }
  
  @IBAction func fixAct(_ sender: Any) {
    postMissionAct(isPost: false)
  }
  
  @IBAction func deleteAct(_ sender: Any) {
    
    guard let uid = Auth.auth().currentUser?.uid else { return }
    
    let group = DispatchGroup()
    
    group.enter()
    group.enter()
    
    TaskManager.shared.deleteTask(uid: uid) { result in
      switch result {
      case .success:
        group.leave()
      case .failure:
        group.leave()
      }
    }
    
    UserManager.shared.updateStatus(uid: uid, status: 0) { result in
      switch result {
      case .success:
        group.leave()
      case .failure:
        group.leave()
        
      }
    }
    
    group.notify(queue: DispatchQueue.main) {
      NotificationCenter.default.post(name: Notification.Name("getMissionList"), object: nil)
      UserManager.shared.currentUserInfo?.status = 0
      LKProgressHUD.dismiss()
      SwiftMes.shared.showSuccessMessage(body: "恭喜刪除 返回任務頁面中", seconds: 1.7)
      DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        self.dismiss(animated: true, completion: nil)
      }
    }
  }
  
  let imagePickerController = UIImagePickerController()
  
  var isChange = false
  
  var fileURL: [String] = []
  
  var fileType: [Int] = []
  
  var fileURLmix: [Any] = []
  
  var selectIndex = 0
  
  var indexRow = 0
  
  var latitude: Double?
  
  var longitude: Double?
  
  let screenwidth = UIScreen.main.bounds.width
  
  let screenheight = UIScreen.main.bounds.height
  
  let myLocationManager = CLLocationManager()
  
  var statusOneData: TaskInfo?
  
  var judge = [Bool](repeating: false, count: 8)
  
  var isEdit = false
  
  func setUpall() {
    setUp()
    setUpBtn()
    setUpTextView()
    setUpCollectionView()
    setUpPhotoCollectionView()
  }
  
  func setUpPhotoCollectionView() {
    photoCollectionView.delegate = self
    photoCollectionView.dataSource = self
  }
  
  func setUpSetting() {
    
    if isEditing {
      editBackBtn.isHidden = false
      postBtn.isHidden = true
      editMissionStackView.isHidden = false
      LKProgressHUD.show(controller: self)
      TaskManager.shared.setUpStatusData { result in
        switch result {
        case .success(let taskInfo):
          self.statusOneData = taskInfo
          self.setUpDetail()
          
        case .failure(let error):
          LKProgressHUD.showFailure(text: error.localizedDescription, controller: self)
        }
      }
    } else {
      editBackBtn.isHidden = true
      postBtn.isHidden = false
      editMissionStackView.isHidden = true
      LKProgressHUD.dismiss()
    }
  }
  
  func preventTap() {
    guard let tabVC = self.view.window?.rootViewController as? TabBarViewController else { return }
    LKProgressHUD.show(controller: tabVC)
  }
  
  func postMissionAct(isPost: Bool) {
    
    guard let money = priceTextField.text,
      let content = missionContentTextView.text,
      let uid = Auth.auth().currentUser?.uid else { return }
    
    if fileType.isEmpty {
      SwiftMes.shared.showErrorMessage(body: "照片不得為空", seconds: 1.0)
    } else if money.isEmpty {
      SwiftMes.shared.showErrorMessage(body: "價錢不得為空", seconds: 1.0)
    } else if addressLabel.text == "" {
      SwiftMes.shared.showErrorMessage(body: "地址不能為空", seconds: 1.0)
    } else if content.isEmpty {
      SwiftMes.shared.showErrorMessage(body: "描述內容不得為空", seconds: 1.0)
    } else {
      
      guard let latitude = latitude,
            let longitude = longitude else { return }
      
      if isPost {
        self.preventTap()
      } else {
        LKProgressHUD.show(controller: self)
      }
      
      self.fileURL = []
      
      let group = DispatchGroup()
      
      if !fileURLmix.isEmpty {
        
        for _ in 0 ..< fileURLmix.count {
          group.enter()
        }
        
        for count in 0 ..< fileURLmix.count {
          let id = UUID().uuidString
          if let image = fileURLmix[count] as? UIImage {
            guard let imageData = image.jpegData(compressionQuality: 0.5) else {
              group.leave()
              return }
            let storageRef = Storage.storage().reference().child("TaskFinder").child("\(id).jpeg")
            
            uploadDataToDB(data: imageData, storageRef: storageRef) {
              group.leave()
            }
            
          } else {
            
            let storageRef = Storage.storage().reference().child("TaskVideo").child("\(id).mov")
            
            guard let videourl = fileURLmix[count] as? NSURL else { return }
            
            let videoTransferUrl = videourl as URL
            
            var movieData: Data?
            do {
              
              movieData = try Data(contentsOf: videoTransferUrl, options: .alwaysMapped)
            } catch {
              movieData = nil
              return
            }
            
            uploadDataToDB(data: movieData!, storageRef: storageRef) {
              group.leave()
            }
          }
        }
      }
      
      group.notify(queue: DispatchQueue.main) {
        TaskManager.shared.address = ""
        self.createDataBase(money: money, content: content, latitude: latitude, longitude: longitude, uid: uid)
      }
    }
  }
  
  func uploadDataToDB(data: Data, storageRef: StorageReference, completion: @escaping (() -> Void)) {
    storageRef.putData(data, metadata: nil ) { (_, error) in
      
      if error != nil {
        LKProgressHUD.dismiss()
        return
      }
      
      storageRef.downloadURL { [weak self](url, error) in
        
        guard let strongSelf = self else { return }
        
        if error != nil {
          LKProgressHUD.dismiss()
          LKProgressHUD.showFailure(text: "Error", controller: strongSelf)
          return }
        
        guard let urlBack = url else { return }
        
        let stringUrl = "\(urlBack)"
        
        strongSelf.fileURL.append(stringUrl)
        
        completion()
        
      }
    }
  }
  
  func createDataBase(money: String, content: String, latitude: Double, longitude: Double, uid: String) {
    
    let finalSelectIndex = selectIndex
    
    let intMoney = Int(money) ?? 0
    
    let now = Int(NSDate().timeIntervalSince1970)
    
    let location = CLLocationCoordinate2DMake(latitude, longitude)
    
    let taskData: [Int] = [now, intMoney, finalSelectIndex, 0]
    
    TaskManager.shared.createMission(taskPhoto: fileURL, coordinate: location, taskData: taskData, detail: content, fileType: self.fileType) { [weak self](result) in
      guard let strongSelf = self else { return }
      
      switch result {
        
      case .failure:
        print("fail")
        
      case .success:
        
        UserManager.shared.updateStatus(uid: uid, status: 1) { result in
          switch result {
            
          case .success:
            UserManager.shared.currentUserInfo?.status = 1
            NotificationCenter.default.post(name: Notification.Name("getMissionList"), object: nil)
            LKProgressHUD.dismiss()
            SwiftMes.shared.showSuccessMessage(body: "返回任務頁面中", seconds: 1.7)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
              strongSelf.navigationController?.popViewController(animated: true)
              strongSelf.dismiss(animated: true, completion: nil)
            }
            
          case .failure(let error):
            
            LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
          }
        }
      }
    }
  }
  
  @IBAction func uploadAction(_ sender: Any) {
    
    let imagePickerAlertController = UIAlertController(title: "上傳圖片", message: "請選擇要上傳的圖片", preferredStyle: .actionSheet)
    
    let imageFromLibAction = UIAlertAction(title: "照片圖庫", style: .default) { (_) in
      if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
        self.imagePickerController.sourceType = .photoLibrary
        self.present(self.imagePickerController, animated: true, completion: nil)
      }
    }
    
    let cancelAction = UIAlertAction(title: "取消", style: .cancel) { (_) in
      imagePickerAlertController.dismiss(animated: true, completion: nil)
    }
    
    imagePickerAlertController.addAction(imageFromLibAction)
    imagePickerAlertController.addAction(cancelAction)
    present(imagePickerAlertController, animated: true, completion: nil)
  }
  
  func setUpCollectionView() {
    missionGroupCollectionView.delegate = self
    missionGroupCollectionView.dataSource = self
    missionGroupCollectionView.layer.shadowOpacity = 0.2
    missionGroupCollectionView.layer.shadowOffset = CGSize(width: 3, height: 3)
  }
  
  func setUpTextView() {
    missionContentTextView.delegate = self
    missionContentTextView.layer.cornerRadius = screenwidth / 40
    missionContentTextView.layer.shadowOpacity = 0.4
    missionContentTextView.layer.shadowColor = UIColor.black.cgColor
    missionContentTextView.clipsToBounds = false
    missionContentTextView.layer.shadowOffset = CGSize(width: 3, height: 3)
  }
  
  func setUpBtn() {
    postBtn.layer.cornerRadius = postBtn.bounds.height / 8
    fixBtn.layer.cornerRadius = postBtn.bounds.height / 8
    giveUpBtn.layer.cornerRadius = postBtn.bounds.height / 8
    if isEditing {
      postBtn.isEnabled = true
      postBtn.setTitle("修改完成", for: .normal)
    }
    postBtn.layer.shadowOpacity = 0.5
    postBtn.layer.shadowOffset = CGSize(width: 3, height: 3)
  }
  
  func setUp() {
    myLocationManager.delegate = self
    imagePickerController.delegate = self
    imagePickerController.allowsEditing = true
    priceTextField.delegate = self
    priceTextField.layer.cornerRadius = screenwidth / 50
    imagePickerController.mediaTypes = [kUTTypeMovie as String, kUTTypeImage as String]
  }
  
  @IBAction func addLocationAct(_ sender: Any) {
    performSegue(withIdentifier: "addlocation", sender: nil)
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
    if segue.identifier == "addlocation" {
      guard let locationVC = segue.destination as? AddLocationViewController else { return }
      locationVC.delegate = self
    }
  }
  
  func showAlert(viewController: UIViewController) {
    
    let controller = UIAlertController(title: "任務上傳成功", message: "返回任務頁面", preferredStyle: .alert)
    let okAction = UIAlertAction(title: "好的", style: .default) { (_) in
      
      viewController.navigationController?.popViewController(animated: true)
    }
    controller.addAction(okAction)
    present(controller, animated: true, completion: nil)
  }
}

extension PostMissionViewController: UICollectionViewDelegate, UICollectionViewDataSource {
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    
    if collectionView == self.missionGroupCollectionView {
      return TaskManager.shared.taskClassified.count - 1
    } else {
      return fileURLmix.count + 1
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    if collectionView == self.missionGroupCollectionView {
      
      guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "group", for: indexPath) as? MissionGroupCollectionViewCell else { return UICollectionViewCell() }
      
      cell.setUpContent(label: TaskManager.shared.taskClassified[indexPath.row + 1].title, color: TaskManager.shared.taskClassified[indexPath.row + 1].color)
      
      cell.contentView.backgroundColor = judge[indexPath.row] ? UIColor(red: 246.9/255.0, green: 212.0/255.0, blue: 95.0/255.0, alpha: 1.0) : .white
      cell.layer.borderWidth = judge[indexPath.row] ? 1.0 : 0.0
      cell.layer.borderColor = judge[indexPath.row] ? UIColor.clear.cgColor : UIColor.white.cgColor
      
      return cell
      
    } else {
      
      guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photo", for: indexPath) as? PhotoCollectionViewCell else { return UICollectionViewCell() }
      
      cell.delegate = self
      removeLayer(cell: cell)
      
      if fileURLmix.isEmpty {
        cell.indexRow = 0
        cell.backgroundColor = .white
        cell.deleteBtn.isHidden = true
        cell.addPhotoBtn.isHidden = false
        cell.photoImageView.isHidden = true
        cell.contentView.backgroundColor = .white
        return cell
        
      } else if indexPath.row != fileURLmix.count && ((fileURLmix[indexPath.row] as? UIImage) != nil) {
        guard let image = fileURLmix[indexPath.row] as? UIImage else { return UICollectionViewCell() }
        cell.backgroundColor = .clear
        cell.deleteBtn.isHidden = false
        cell.indexRow = indexPath.row
        cell.addPhotoBtn.isHidden = true
        cell.photoImageView.image = image
        cell.photoImageView.isHidden = false
        cell.contentView.backgroundColor = .white
        cell.photoImageView.contentMode = .scaleAspectFill
        return cell
        
      } else if indexPath.row != fileURLmix.count && ((fileURLmix[indexPath.row] as? URL) != nil) {
        cell.deleteBtn.isHidden = false
        cell.indexRow = indexPath.row
        cell.photoImageView.isHidden = true
        cell.contentView.backgroundColor = .black
        guard let video = fileURLmix[indexPath.row] as? URL else { return UICollectionViewCell() }
        cell.setUpLooper(video: video)
        return cell
        
      } else {
        cell.deleteBtn.isHidden = true
        cell.indexRow = indexPath.row
        cell.addPhotoBtn.isHidden = false
        cell.photoImageView.isHidden = true
        cell.contentView.backgroundColor = .white
        return cell
      }
    }
  }
  
  func removeLayer(cell: PhotoCollectionViewCell) {
    guard let layers = cell.layer.sublayers else { return }
    for layer in layers {
      if let avPlayerLayer = layer as? AVPlayerLayer {
        avPlayerLayer.removeFromSuperlayer()
      }
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    if collectionView == self.missionGroupCollectionView {
      selectIndex = indexPath.row
      judge = [Bool](repeating: false, count: 8)
      judge[indexPath.row] = true
      missionGroupCollectionView.reloadData()
    }
  }
}

extension PostMissionViewController: UICollectionViewDelegateFlowLayout {
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    if collectionView == self.missionGroupCollectionView {
      return CGSize(width: screenwidth / 2.5, height: screenheight / 20)
    } else {
      return CGSize(width: 120, height: 120)
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
      return UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
  }
}

extension PostMissionViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  func imagePickerController(_ picker: UIImagePickerController,
                             didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
    
    if let pickedImage = info[.originalImage ] as? UIImage {
      fileURLmix.append(pickedImage)
      self.fileType.append(0)
      self.fileURL.append("0")
      LKProgressHUD.dismiss()
    } else {
      if let videoURL = info[.mediaURL ] as? NSURL {
        fileURLmix.append(videoURL)
        self.fileType.append(1)
        self.fileURL.append("0")
        LKProgressHUD.dismiss()
      }      
    }
    photoCollectionView.reloadData()
    dismiss(animated: true, completion: nil)
  }
}

extension PostMissionViewController: LocationManager {
  func locationReturn(viewController: AddLocationViewController, lat: Double, long: Double) {
    self.latitude = lat
    self.longitude = long
  }
}

extension PostMissionViewController: UploadDataManager {
  func tapOnDelete(collectionViewCelll: PhotoCollectionViewCell, indexRow: Int) {
    self.fileURLmix.remove(at: indexRow)
    self.fileType.remove(at: indexRow)
    self.fileURL.remove(at: indexRow)
    photoCollectionView.reloadData()
  }
  
  func tapOnUpload(collectionViewCelll: PhotoCollectionViewCell) {
    
    let imagePickerAlertController = UIAlertController(title: "上傳圖片", message: "請選擇要上傳的圖片", preferredStyle: .actionSheet)
    
    let imageFromLibAction = UIAlertAction(title: "照片圖庫", style: .default) { (_) in
      if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
        self.imagePickerController.sourceType = .photoLibrary
        self.present(self.imagePickerController, animated: true, completion: nil)
      }
    }
    
    let imageFromCameraAction = UIAlertAction(title: "相機", style: .default) { (_) in
      if UIImagePickerController.isSourceTypeAvailable(.camera) {
        self.imagePickerController.sourceType = .camera
        self.present(self.imagePickerController, animated: true, completion: nil)
      }
    }
    
    let cancelAction = UIAlertAction(title: "取消", style: .cancel) { (_) in
      imagePickerAlertController.dismiss(animated: true, completion: nil)
    }
    
    imagePickerAlertController.addAction(imageFromLibAction)
    imagePickerAlertController.addAction(imageFromCameraAction)
    imagePickerAlertController.addAction(cancelAction)
    
    present(imagePickerAlertController, animated: true, completion: nil)
  }
}

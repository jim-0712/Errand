//
//  PostMissionViewController.swift
//  Errand
//
//  Created by Jim on 2020/1/23.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import AVKit
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

class PostMissionViewController: UIViewController, CLLocationManagerDelegate {
  
  let myLocationManager = CLLocationManager()
  
  var statusOneData: TaskInfo?
  
  var isEdit = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    LKProgressHUD.show(controller: self)
    setUpSetting()
    setUpall()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if TaskManager.shared.address == "" {
      pinImage.isHidden = true
      plusBtn.isHidden = true
    } else {
      pinImage.isHidden = false
      pinImage.isHidden = true
    }
  }

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
      LKProgressHUD.dismiss()
    }
  }
  
  func setUpDetail() {
       guard let taskInfo = statusOneData else { return }
       isChange = true
       lat = taskInfo.lat
       long = taskInfo.long
       fileURL = taskInfo.taskPhoto
       fileType = taskInfo.fileType
       priceTextField.text = "\(taskInfo.money)"
       missionContentTextView.text = taskInfo.detail
    
       for count in 0 ..< taskInfo.taskPhoto.count {
         if fileType[count] == 0 {
           guard let url = URL(string: fileURL[count]) else { return }
           guard let data = try? Data(contentsOf: url) else { return }
           guard let image = UIImage(data: data) else { return }
           luke.append(image)
         } else if fileType[count] == 1 {
           guard let url = URL(string: fileURL[count]) else { return }
           luke.append(url as NSURL)
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
  
  let imagePickerController = UIImagePickerController()
  
  let backgroundManager = BackgroundManager.shared
  
  var isChange = false
  
  var fileURL: [String] = []
  
  var fileType: [Int] = []
  
  var luke: [Any] = []
  
  var selectIndex = 0
  
  var indexRow = 0
  
  var lat: Double?
  
  var long: Double?
  
  let screenwidth = UIScreen.main.bounds.width
  
  let screenheight = UIScreen.main.bounds.height
  
  @IBAction func editBackAct(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func postAct(_ sender: Any) {
    
    LKProgressHUD.show(controller: self)
    
    let group: DispatchGroup = DispatchGroup()
    
    if luke.count == 0 {
      
    } else {
      
      for count in 0 ..< luke.count {
        group.enter()
        let id = UUID().uuidString
        if let image = luke[count] as? UIImage {
          guard let imageData = image.pngData() else {
            group.leave()
            return }
          let storageRef = Storage.storage().reference().child("TaskFinder").child("\(id).png")
          
          storageRef.putData(imageData, metadata: nil, completion: { [weak self] (_, error) in
            
            guard let strongSelf = self else { return }
            
            if error != nil {
              return
            }
            
            storageRef.downloadURL { (url, error) in
              
              if error != nil {
                
                LKProgressHUD.dismiss()
                LKProgressHUD.showFailure(text: "Error", controller: strongSelf)
                return }
              
              guard let urlBack = url else { return }
              
              let stringUrl = "\(urlBack)"
              
              strongSelf.fileURL.append(stringUrl)
              
              group.leave()
              
            }
          })
          
        } else {
        group.enter()
        
        let id = UUID().uuidString
        
        let storageRef = Storage.storage().reference().child("TaskVideo").child("\(id).mov")
          
        guard let videourl = luke[count] as? NSURL else { return }
        
        let videoTransferUrl = videourl as URL
        
        var movieData: Data?
        do {
          
          movieData = try Data(contentsOf: videoTransferUrl, options: .alwaysMapped)
        } catch {
          movieData = nil
          return
        }
        
        storageRef.putData(movieData!, metadata: nil ) { (_, error) in
          
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
            
            group.leave()
          }
        }
      }
    }
  }
  group.notify(queue: DispatchQueue.main) {
  print("ya")
  LKProgressHUD.dismiss()
  self.createDataBase()
  }
}

func createDataBase() {
  guard let money = priceTextField.text,
    let content = missionContentTextView.text,
    let lat = lat,
    let long = long else { return }
  
  let indexfinal = selectIndex
  
  let intMoney = Int(money) ?? 0
  
  let now = NSDate()
  
  let currentTimeS = Int(now.timeIntervalSince1970)
  
  let location = CLLocationCoordinate2DMake(lat, long)
  
  let taskData: [Int] = [currentTimeS, intMoney, indexfinal, 0]
  
  TaskManager.shared.createMission(taskPhoto: fileURL, coordinate: location, taskData: taskData, detail: content, fileType: self.fileType) { [weak self](result) in
    
    guard let strongSelf = self else { return }
    
    switch result {
      
    case .failure:
      
      print("fail")
      
    case .success:
      
      UserManager.shared.updateData(status: 1) { result in
        
        switch result {
          
        case .success:
          
          NotificationCenter.default.post(name: Notification.Name("postMission"), object: nil)
          UserManager.shared.currentUserInfo?.status = 1
          strongSelf.showAlert(viewController: strongSelf)
          
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
  if isEditing {
    postBtn.isEnabled = true
  } else {
    postBtn.isEnabled = false
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
      print(luke.count + 1)
      return luke.count + 1
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    if collectionView == self.missionGroupCollectionView {
      
      guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "group", for: indexPath) as? MissionGroupCollectionViewCell else { return UICollectionViewCell() }
      
      cell.setUpContent(label: TaskManager.shared.taskClassified[indexPath.row + 1].title, color: TaskManager.shared.taskClassified[indexPath.row + 1].color)
      
      if indexPath.row == 0 {
        cell.isSelected = true
      }
      return cell
      
    } else {
      
      guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photo", for: indexPath) as? PhotoCollectionViewCell else { return UICollectionViewCell() }
      
      cell.delegate = self
      if luke.count == 0 {
        cell.indexRow = 0
        cell.deleteBtn.isHidden = true
        cell.backgroundColor = .white
        cell.addPhotoBtn.isHidden = false
        cell.photoImageView.isHidden = true
        return cell
        
      } else if indexPath.row != luke.count && ((luke[indexPath.row] as? UIImage) != nil) {
        
        cell.photoImageView.isHidden = false
        cell.indexRow = indexPath.row
        guard let layers = cell.layer.sublayers else { return UICollectionViewCell() }
        for layer in layers {
          if let avPlayerLayer = layer as? AVPlayerLayer {
            avPlayerLayer.removeFromSuperlayer()
          }
        }
        
        guard let image = luke[indexPath.row] as? UIImage else { return UICollectionViewCell() }
        cell.addPhotoBtn.isHidden = true
        cell.deleteBtn.isHidden = false
        cell.backgroundColor = .clear
        cell.photoImageView.image = image
        return cell
        
      } else if indexPath.row != luke.count && ((luke[indexPath.row] as? URL) != nil) {
        cell.indexRow = indexPath.row
        cell.deleteBtn.isHidden = false
        cell.photoImageView.isHidden = true
        guard let video = luke[indexPath.row] as? URL else { return UICollectionViewCell() }
        let player = AVPlayer(url: video)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = cell.contentView.bounds
        cell.layer.addSublayer(playerLayer)
        
        player.play()
        return cell
        
      } else {
        cell.indexRow = indexPath.row
        cell.deleteBtn.isHidden = true
        cell.addPhotoBtn.isHidden = false
        cell.photoImageView.isHidden = true
        return cell
      }
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    
    if collectionView == self.missionGroupCollectionView {
      selectIndex = indexPath.row
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
    
    if collectionView == self.missionGroupCollectionView {
      return UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    } else {
      return UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    }
  }
}

extension PostMissionViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    
    if let pickedImage = info[.originalImage ] as? UIImage {
      luke.append(pickedImage)
      self.fileType.append(0)
      LKProgressHUD.dismiss()
    } else {
      if let videoURL = info[.mediaURL ] as? NSURL {
        luke.append(videoURL)
        self.fileType.append(1)
        LKProgressHUD.dismiss()
      }      
    }
    photoCollectionView.reloadData()
    dismiss(animated: true, completion: nil)
  }
}

extension PostMissionViewController: UITextFieldDelegate, UITextViewDelegate {
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    
    if priceTextField.text != nil && missionContentTextView.text != nil && fileURL.count > 0 {
      postBtn.isEnabled = true
    } else {
      postBtn.isEnabled = false
    }
  }
  
  func textViewDidEndEditing(_ textView: UITextView) {
    
    if priceTextField.text != nil && missionContentTextView.text != nil {
      postBtn.isEnabled = true
    } else {
      postBtn.isEnabled = false
    }
  }
}

extension PostMissionViewController: LocationManager {
  func locationReturn(viewController: AddLocationViewController, lat: Double, long: Double) {
    
    self.lat = lat
    self.long = long
  }
}

extension PostMissionViewController: UploadDataManager {
  func tapOnDelete(collectionViewCelll: PhotoCollectionViewCell, indexRow: Int) {
    self.luke.remove(at: indexRow)
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

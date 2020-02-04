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

class PostMissionViewController: UIViewController, CLLocationManagerDelegate {
  
  let myLocationManager = CLLocationManager()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
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
  @IBOutlet weak var photoCollectionView: UICollectionView!
  
  @IBOutlet weak var photoUploadText: UILabel!
  
  @IBOutlet weak var chooseGroupText: UILabel!
  
  @IBOutlet weak var missionGroupCollectionView: UICollectionView!
  
  @IBOutlet weak var uploadPhotoBtn: UIButton!
  
  @IBOutlet var backgroundVisibleView: [UIView]!
  
  @IBOutlet var uploadImageVisibleView: [UIImageView]!
  
  @IBOutlet var videoView: [UIView]!
  
  @IBOutlet weak var priceLabel: UILabel!
  
  @IBOutlet weak var priceTextField: UITextField!
  
  @IBOutlet weak var missionLabel: UILabel!
  
  @IBOutlet weak var missionContentTextView: UITextView!
  
  @IBOutlet weak var postBtn: UIButton!
  
  @IBOutlet weak var stackNTDView: UIStackView!
  
  let imagePickerController = UIImagePickerController()
  
  let backgroundManager = BackgroundManager.shared
  
  var imageReady: [UIImage] = []
  
  var videoReady: [NSURL] = []
  
  var fileURL: [String] = []
  
  var fileType: [Int] = []
  
  var selectIndex: Int?
  
  var lat: Double?
  
  var long: Double?
  
  let screenwidth = UIScreen.main.bounds.width
  
  let screenheight = UIScreen.main.bounds.height
  
  @IBAction func postAct(_ sender: Any) {
    print("post")
    
    LKProgressHUD.show(controller: self)
    
    let group: DispatchGroup = DispatchGroup()
    
    let photoQueue = DispatchQueue(label: "photo", attributes: .concurrent)
    
    let videoQueue = DispatchQueue(label: "video", attributes: .concurrent)
    
    group.enter()
    
    photoQueue.async(group: group) {
      
      if self.imageReady.count == 0 {
        
        group.leave()
      } else {
        
        for count in 0 ..< self.imageReady.count {
          
          let id = UUID().uuidString
          
          guard let imageData = self.imageReady[count].pngData() else { return }
          
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
        }
      }
    }
    
    group.enter()
    
    videoQueue.async(group: group) {
      
      if self.videoReady.count == 0 {
        
        group.leave()
      } else {
        
        for count in 0 ..< self.videoReady.count {
          
          let id = UUID().uuidString
          
          let storageRef = Storage.storage().reference().child("TaskVideo").child("\(id).mov")
          
          let videoTransferUrl = self.videoReady[count] as URL
          
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
      let indexfinal = selectIndex,
      let lat = lat,
      let long = long else { return }
    
    let intMoney = Int(money) ?? 0
    
    let now = NSDate()
    
    let currentTimeS = Int(now.timeIntervalSince1970)
    
    let location = CLLocationCoordinate2DMake(lat, long)
    
    let taskData: [Int] = [currentTimeS, intMoney, indexfinal, 0]
    
    TaskManager.shared.createMission(taskPhoto: fileURL, coordinate: location, taskData: taskData, detail: content, fileType: self.fileType) { [weak self](result) in
      
      guard let strongSelf = self else { return }
      
      switch result {
        
      case .success:
        
        UserManager.shared.updateData { result in
          
          switch result {
            
          case .success:
            
            NotificationCenter.default.post(name: Notification.Name("postMission"), object: nil)
            
            strongSelf.showAlert(viewController: strongSelf)
            
          case .failure(let error):
            
            LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
          }
        }
      case .failure:
        
        print("fail")
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
    
    postBtn.layer.cornerRadius = screenwidth / 40
  
    postBtn.isEnabled = false
    
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
    
    for count in 0 ..< uploadImageVisibleView.count {
      
      uploadImageVisibleView[count].isHidden = true
    }
    
    for count in 0 ..< videoView.count {
      
      videoView[count].isHidden = true
    }
    
    for count in 0 ..< videoView.count {
      
      backgroundVisibleView[count].layer.shadowOpacity = 0.2
      
      backgroundVisibleView[count].layer.shadowOffset = CGSize(width: 3, height: 3)
    }
    
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
      
      if fileType.count == 0 {
        
        return 1
      } else {
        
        return fileType.count + 1
      }
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    if collectionView == self.missionGroupCollectionView {
      
      guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "group", for: indexPath) as? MissionGroupCollectionViewCell else { return UICollectionViewCell() }
      
      cell.setUpContent(label: TaskManager.shared.taskClassified[indexPath.row + 1].title, color: TaskManager.shared.taskClassified[indexPath.row + 1].color)
      
      return cell
      
    } else {
      
      var photoCounter = 0
      
      var videoCounter = 0
      
      guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photo", for: indexPath) as? PhotoCollectionViewCell else { return UICollectionViewCell() }
      
      cell.delegate = self
      
      if fileType.count == 0 {
        
        cell.backgroundColor = .green
        
        cell.addPhotoBtn.isHidden = false
        
        cell.photoImageView.isHidden = true
        
        return cell
      } else if indexPath.row != fileType.count && fileType[indexPath.row] == 0 {
        
        cell.addPhotoBtn.isHidden = true
        
        cell.photoImageView.image = imageReady[photoCounter]
        
        photoCounter += 1
        
        return cell
      } else if indexPath.row != fileType.count && fileType[indexPath.row] == 1 {
        
        cell.photoImageView.isHidden = true

        let player = AVPlayer(url: videoReady[videoCounter] as URL)
        
        let playerLayer = AVPlayerLayer(player: player)
        
        playerLayer.frame = cell.contentView.bounds
        
        cell.layer.addSublayer(playerLayer)
        
        videoCounter += 1

        player.play()
        
        return cell
      } else {
        
        cell.backgroundColor = .red
        
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
      
      return CGSize(width: 100, height: 100)
    }
     
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    
    if collectionView == self.missionGroupCollectionView {
      return UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    } else {
      
       return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
  }
}

extension PostMissionViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    
    if let pickedImage = info[.originalImage ] as? UIImage {
      
      imageReady.append(pickedImage)
      
      self.fileType.append(0)
      
      photoCollectionView.reloadData()
      
      self.uploadImageVisibleView[self.fileType.count - 1].isHidden = false
      
      self.uploadImageVisibleView[self.fileType.count - 1].image = pickedImage
      
      self.backgroundVisibleView[self.fileType.count - 1].backgroundColor = .clear
      
    } else {
      
      if let videoURL = info[.mediaURL ] as? NSURL {
        
        let videoTransferUrl = videoURL as URL
        
        self.videoReady.append(videoURL)
        
        self.fileType.append(1)
        
        photoCollectionView.reloadData()
        
        self.uploadImageVisibleView[self.fileType.count - 1].backgroundColor = .clear
        
        self.backgroundVisibleView[self.fileType.count - 1].backgroundColor = .clear
        
        self.videoView[self.fileType.count - 1].isHidden = false
        
        LKProgressHUD.dismiss()
        
        let player = AVPlayer(url: videoTransferUrl)
        
        let playerLayer = AVPlayerLayer(player: player)
        
        playerLayer.frame = self.videoView[self.fileURL.count].bounds
        
        self.videoView[self.fileURL.count].layer.addSublayer(playerLayer)
        
        player.play()
      }      
    }
    dismiss(animated: true, completion: nil)
  }
}

extension PostMissionViewController: UITextFieldDelegate, UITextViewDelegate {
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    
    if priceTextField.text != nil && missionContentTextView.text != nil && fileURL.count > 0 && selectIndex != nil {
      postBtn.isEnabled = true
    } else {
      postBtn.isEnabled = false
    }
  }
  
  func textViewDidEndEditing(_ textView: UITextView) {
    
    if priceTextField.text != nil && missionContentTextView.text != nil && selectIndex != nil {
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

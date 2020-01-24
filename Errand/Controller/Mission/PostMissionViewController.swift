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
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class PostMissionViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setUp()
    
  }
  
  @IBOutlet weak var photoUploadText: UILabel!
  
  @IBOutlet weak var chooseGroupText: UILabel!
  
  @IBOutlet weak var missionGroupCollectionView: UICollectionView!
  
  @IBOutlet weak var uploadPhotoBtn: UIButton!
  
  @IBOutlet var backgroundVisibleView: [UIView]!
  
  @IBOutlet var uploadImageVisibleView: [UIImageView]!
  
  @IBOutlet var videoView: [UIView]!
  
  let imagePickerController = UIImagePickerController()
  
  let backgroundManager = BackgroundManager.shared
  
  var fileURL: [URL] = []
  
  var startToUpload = 0
  
  var selectIndex: Int?
  
  let missionGroup = ["搬運物品", "清潔打掃", "水電維修", "科技維修", "驅趕害蟲", "一日陪伴", "交通接送", "其他種類"]
  
  let missionColor: [UIColor] = [.red, .orange, .themeColor, .yellow, .pink, .lightPurple, .lightBlue, .gray]
  
  let screenwidth = UIScreen.main.bounds.width
  
  let screenheight = UIScreen.main.bounds.height
  
  @IBAction func uploadAction(_ sender: Any) {
    
    if fileURL.count > 3 {
      
      print("error")
    } else {
      
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
      
      // 新增一個取消動作，讓使用者可以跳出 UIAlertController
      let cancelAction = UIAlertAction(title: "取消", style: .cancel) { (_) in
        
        imagePickerAlertController.dismiss(animated: true, completion: nil)
      }
      
      imagePickerAlertController.addAction(imageFromLibAction)
      imagePickerAlertController.addAction(imageFromCameraAction)
      imagePickerAlertController.addAction(cancelAction)
      
      present(imagePickerAlertController, animated: true, completion: nil)
      
    }
  }
  
  func setUp() {
    
    let backView = backgroundManager.setUpView(view: self.view)
    
    self.view.layer.insertSublayer(backView, at: 0)
    
    missionGroupCollectionView.delegate = self
    
    missionGroupCollectionView.dataSource = self
    
    imagePickerController.delegate = self
    
    imagePickerController.allowsEditing = true
    
    imagePickerController.mediaTypes = [kUTTypeMovie as String, kUTTypeImage as String]
    
    for count in 0 ..< uploadImageVisibleView.count {
      
      uploadImageVisibleView[count].isHidden = true
    }
    
    for count in 0 ..< videoView.count {
      
      videoView[count].isHidden = true
    }
    
    //    NSLayoutConstraint.activate([
    //      missionGroupCollectionView.heightAnchor.constraint(equalToConstant: screenheight/15)
    //    ])
    
  }
}

extension PostMissionViewController: UICollectionViewDelegate, UICollectionViewDataSource {
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    
    return 8
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "group", for: indexPath) as? MissionGroupCollectionViewCell else { return UICollectionViewCell() }
    
    cell.setUpContent(label: missionGroup[indexPath.row], color: missionColor[indexPath.row])
    
    return cell
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    
    selectIndex = indexPath.row
  }
  
}

extension PostMissionViewController: UICollectionViewDelegateFlowLayout {
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    
    return CGSize(width: screenwidth / 2.5, height: screenheight / 20)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    
    return UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
  }
}

extension PostMissionViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    
    LKProgressHUD.show(controller: self)
    
    guard let userName = Auth.auth().currentUser?.email else { return }
    
    var selectedImageFromPicker: UIImage?
    
    if let pickedImage = info[.originalImage ] as? UIImage {
      
      selectedImageFromPicker = pickedImage
      
      if let selectedImage = selectedImageFromPicker {
        
        let storageRef = Storage.storage().reference().child("TaskFinder").child("\(userName).png")
        
        if let uploadData = selectedImage.pngData() {
          
          storageRef.putData(uploadData, metadata: nil, completion: { [weak self](_, error) in
            
            guard let strongSelf = self else { return }
            
            if error != nil {
              
              LKProgressHUD.dismiss()
              
              return
            }
            
            storageRef.downloadURL { (url, error) in
              
              if error != nil {
                
                LKProgressHUD.dismiss()
                
                LKProgressHUD.showFailure(text: "Error", controller: strongSelf)
                
                return }
              
              strongSelf.uploadImageVisibleView[strongSelf.fileURL.count].isHidden = false
              
              strongSelf.uploadImageVisibleView[strongSelf.fileURL.count].image = selectedImage
              
              strongSelf.backgroundVisibleView[strongSelf.fileURL.count].backgroundColor = .clear
              
              LKProgressHUD.dismiss()
              
              guard let urlBack = url else { return }
              
              strongSelf.fileURL.append(urlBack)
              
            }
          })
        }
      }
      
    } else {
      
      if let videoURL = info[.mediaURL ] as? NSURL {
        
        let id = UUID().uuidString
        
        let storageRef = Storage.storage().reference().child("TaskVideo").child("\(id).mov")
        
        let videoTransferUrl = videoURL as URL
        
        var movieData: Data?
        do {
          
          movieData = try Data(contentsOf: videoTransferUrl, options: .alwaysMapped)
        } catch {
          print(error)
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
            
            strongSelf.uploadImageVisibleView[strongSelf.fileURL.count].backgroundColor = .clear
            
            strongSelf.backgroundVisibleView[strongSelf.fileURL.count].backgroundColor = .clear
            //            strongSelf.photoVisibleView.backgroundColor = .clear
            strongSelf.videoView[strongSelf.fileURL.count].isHidden = false
            //            strongSelf.videoView.isHidden = false
            
            LKProgressHUD.dismiss()
            
            let player = AVPlayer(url: videoTransferUrl)
            
            let playerLayer = AVPlayerLayer(player: player)
            
            playerLayer.frame = strongSelf.videoView[strongSelf.fileURL.count].bounds
            
            strongSelf.videoView[strongSelf.fileURL.count].layer.addSublayer(playerLayer)
            
            player.play()
            
            guard let urlBack = url else { return }
            
            strongSelf.fileURL.append(urlBack)

          }
        }
      }
      
    }
    
    dismiss(animated: true, completion: nil)
  }
  
}

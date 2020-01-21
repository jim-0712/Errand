//
//  PersonalViewController.swift
//  Errand
//
//  Created by Jim on 2020/1/21.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import Kingfisher
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class PersonalViewController: UIViewController {
  
  let imagePickerController = UIImagePickerController()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setUpView()
    // 委任代理
    imagePickerController.delegate = self
    
    imagePickerController.allowsEditing = true
    // Do any additional setup after loading the view.
  }
  @IBOutlet weak var upLoadBtn: UIButton!
  
  @IBOutlet weak var personPhoto: UIImageView!
  
  func setUpView() {
    
    guard let personImage = UserDefaults.standard.value(forKey: "personPhoto") as? URL else {
      
      personPhoto.image = UIImage(named: "user-2")
      
      return }
    
    personPhoto.kf.setImage(with: personImage)
  }
  
  @IBAction func upLoadAct(_ sender: Any) {
  
    // 建立一個 UIAlertController 的實體
    // 設定 UIAlertController 的標題與樣式為 動作清單 (actionSheet)
    let imagePickerAlertController = UIAlertController(title: "上傳圖片", message: "請選擇要上傳的圖片", preferredStyle: .actionSheet)
    
    // 建立三個 UIAlertAction 的實體
    // 新增 UIAlertAction 在 UIAlertController actionSheet 的 動作 (action) 與標題
    let imageFromLibAction = UIAlertAction(title: "照片圖庫", style: .default) { (_) in
      
      // 判斷是否可以從照片圖庫取得照片來源
      if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
        
        // 如果可以，指定 UIImagePickerController 的照片來源為 照片圖庫 (.photoLibrary)，並 present UIImagePickerController
        self.imagePickerController.sourceType = .photoLibrary
        self.present(self.imagePickerController, animated: true, completion: nil)
      }
    }
    let imageFromCameraAction = UIAlertAction(title: "相機", style: .default) { (_) in
      
      // 判斷是否可以從相機取得照片來源
      if UIImagePickerController.isSourceTypeAvailable(.camera) {
        // 如果可以，指定 UIImagePickerController 的照片來源為 照片圖庫 (.camera)，並 present UIImagePickerController
        self.imagePickerController.sourceType = .camera
        self.present(self.imagePickerController, animated: true, completion: nil)
      }
    }
    
    // 新增一個取消動作，讓使用者可以跳出 UIAlertController
    let cancelAction = UIAlertAction(title: "取消", style: .cancel) { (_) in
      
      imagePickerAlertController.dismiss(animated: true, completion: nil)
    }
    
    // 將上面三個 UIAlertAction 動作加入 UIAlertController
    imagePickerAlertController.addAction(imageFromLibAction)
    imagePickerAlertController.addAction(imageFromCameraAction)
    imagePickerAlertController.addAction(cancelAction)
    
    // 當使用者按下 uploadBtnAction 時會 present 剛剛建立好的三個 UIAlertAction 動作與
    present(imagePickerAlertController, animated: true, completion: nil)
  }
}

extension PersonalViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    
    LKProgressHUD.show(controller: self)
    
    var selectedImageFromPicker: UIImage?
    
    if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
      
      selectedImageFromPicker = pickedImage
    }
    
    guard let userName = Auth.auth().currentUser?.email else { return }
    
    if let selectedImage = selectedImageFromPicker {
      
      let storageRef = Storage.storage().reference().child("UserPhoto").child("\(userName).png")
      
      if let uploadData = selectedImage.pngData() {
        
        // 這行就是 FirebaseStroge 關鍵的存取方法。
        storageRef.putData(uploadData, metadata: nil, completion: { (_, error) in
          
          if error != nil {
            
            LKProgressHUD.dismiss()
            
            return
          }
          
          storageRef.downloadURL { (url, error) in
            
            if error != nil {
              
              LKProgressHUD.dismiss()
              
              print("1")
              
              LKProgressHUD.showFailure(text: "Error", controller: self)
              
              return }
            
            UserDefaults.standard.set(url, forKey: "personPhoto")
            
            self.personPhoto.image = selectedImage
            
            guard let urlBack = url else { return }
            
            UserManager.shared.updatePhotoData(photo: urlBack) { result in
              
              switch result {
                
              case .success:
                
                LKProgressHUD.dismiss()
                
                print("2")
                
                LKProgressHUD.showSuccess(text: "Success", controller: self)
                
              case .failure(let error):
                
                LKProgressHUD.dismiss()
                
                 print("3")
                
                LKProgressHUD.showFailure(text: error.localizedDescription, controller: self)
              }
            }
            
          }
        })
      }
    }
  
    dismiss(animated: true, completion: nil)
  }
  
}

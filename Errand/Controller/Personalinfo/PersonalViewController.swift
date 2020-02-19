//
//  PersonalViewController.swift
//  Errand
//
//  Created by Jim on 2020/1/21.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import Kingfisher
import MobileCoreServices
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import MarqueeLabel

class PersonalViewController: UIViewController {
  
  let imagePickerController = UIImagePickerController()
  
  var personPhoto = ""
  
  var isSetting = false
  
  var isName = false
  
  var isAbout = false
  
  var isUpload = true
  
  var name = ""
  
  var about = ""
  
  var averageStar = 0.0
  
  var totaltaskCount = 0
  
  var totalStar = 0.0
  
  var trigger = false
  
  let profileDetail = ["暱稱", "歷史評分", "關於我"]
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if UserManager.shared.isTourist {
      UserManager.shared.goToSign(viewController: self)
    } else {
      setUpTableView()
      self.navigationController?.navigationBar.prefersLargeTitles = true
      guard let photoNow = UserManager.shared.currentUserInfo?.photo else { return }
      personPhoto = photoNow
      imagePickerController.delegate = self
      imagePickerController.allowsEditing = true
      imagePickerController.mediaTypes = [kUTTypeImage as String]
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    readJudge()
    totalStar = 0
    totaltaskCount = 0
    NotificationCenter.default.post(name: Notification.Name("onTask"), object: nil)
  }
  
  func readJudge() {
    
    guard let uid = UserManager.shared.currentUserInfo?.uid else { return }
    
    TaskManager.shared.readJudgeData(uid: uid) { result in
      
      switch result {
      case .success(let judgeData):
        
        for count in 0 ..< judgeData.count {
          
          self.totalStar += judgeData[count].star
        }
        
        self.totaltaskCount = judgeData.count
        
        self.infoTableView.reloadData()
        
      case .failure:
        print("error")
      }
    }
  }
  
  @IBOutlet weak var settingBtn: UIButton!
  
  @IBOutlet weak var infoTableView: UITableView!
  
  @IBAction func tapSetting(_ sender: Any) {
    
    if !isSetting {
      
      settingBtn.setImage(UIImage(named: "checked"), for: .normal)
      isSetting = !isSetting
      infoTableView.reloadData()
      
    } else {
      
      settingBtn.setImage(UIImage(named: "wheel-2"), for: .normal)
      
      if isName && isAbout {
        
        isUpload = true
        UserManager.shared.currentUserInfo?.nickname = name
        UserManager.shared.currentUserInfo?.about = about
      } else if isName {
        
        isUpload = true
        UserManager.shared.currentUserInfo?.nickname = name
      } else if isAbout {
        
        isUpload = true
        UserManager.shared.currentUserInfo?.about = about
      } else {
        
        isSetting = !isSetting
        isUpload = false
        infoTableView.reloadData()
      }
      
      if isUpload {
        
        LKProgressHUD.show(controller: self)
        
        UserManager.shared.updateUserInfo { [weak self] result in
          
          guard let strongSelf = self else { return }
          
          switch result {
            
          case .success:
            
            LKProgressHUD.dismiss()
            
            strongSelf.isSetting = false
            strongSelf.isName = false
            strongSelf.isAbout = false
            strongSelf.isUpload = false
            strongSelf.infoTableView.reloadData()
            
          case .failure(let error):
            
            LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
          }
        }
      }
    }
    
  }
  
  func setUpTableView() {
    infoTableView.delegate = self
    infoTableView.dataSource = self
    infoTableView.separatorStyle = .none
    infoTableView.rowHeight = UITableView.automaticDimension
    infoTableView.register(UINib(nibName: "PhotoTableViewCell", bundle: nil), forCellReuseIdentifier: "personPhoto")
    infoTableView.register(UINib(nibName: "PersonDetailTableViewCell", bundle: nil), forCellReuseIdentifier: "personDetail")
    infoTableView.register(UINib(nibName: "PersonAboutTableViewCell", bundle: nil), forCellReuseIdentifier: "personAbout")
  }
  
  func showAlert() {
    let controller = UIAlertController(title: "錯誤", message: "姓名不能有空白", preferredStyle: .alert)
    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
    controller.addAction(okAction)
    self.present(controller, animated: true, completion: nil)
  }
  
  func logoutAlert() {
    let controller = UIAlertController(title: "注意", message: "您真的要登出嗎？", preferredStyle: .alert)
    let okAction = UIAlertAction(title: "ok", style: .default) { _ in
      
      do {
        try Auth.auth().signOut()
        
      } catch {
        print("Error")
      }
      let signInVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "main") as? ViewController
      
      UserManager.shared.isTourist = true
      
      UserDefaults.standard.removeObject(forKey: "login")
      
      self.view.window?.rootViewController = signInVC
    }
    
    let cancelAction = UIAlertAction(title: "cancal", style: .cancel, handler: nil)
    controller.addAction(okAction)
    controller.addAction(cancelAction)
    self.present(controller, animated: true, completion: nil)
  }
}

extension PersonalViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    
    LKProgressHUD.show(controller: self)
    
    let id = UUID().uuidString
    
    var selectedImageFromPicker: UIImage?
    
    if let pickedImage = info[.originalImage ] as? UIImage {
      
      selectedImageFromPicker = pickedImage
      
      if let selectedImage = selectedImageFromPicker {
        
        let storageRef = Storage.storage().reference().child("UserPhoto").child("\(id).jpeg")
        
        if let uploadData = selectedImage.jpegData(compressionQuality: 0.5) {
          
          storageRef.putData(uploadData, metadata: nil, completion: { [weak self] (_, error) in
            
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
              
              guard let urlBack = url else { return }
              
              UserManager.shared.updatePhotoData(photo: urlBack) { result in
                
                switch result {
                  
                case .success:
                  strongSelf.personPhoto = urlBack.absoluteString
                  NotificationCenter.default.post(name: Notification.Name("update"), object: nil)
                  strongSelf.infoTableView.reloadData()
                  LKProgressHUD.dismiss()
                  LKProgressHUD.showSuccess(text: "Success", controller: strongSelf)
                  
                case .failure(let error):
                  LKProgressHUD.dismiss()
                  LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
                }
              }
            }
          })
        }
      }
    }
    dismiss(animated: true, completion: nil)
  }
}

extension PersonalViewController: UITableViewDataSource, UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    return 5
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    guard let name = UserManager.shared.currentUserInfo?.nickname,
      let email = UserManager.shared.currentUserInfo?.email,
      let aboutMe = UserManager.shared.currentUserInfo?.about,
      let star = UserManager.shared.currentUserInfo?.totalStar else { return UITableViewCell() }
    
    let data = [name, aboutMe]
    
    if indexPath.row == 0 {
      
      guard let cell = tableView.dequeueReusableCell(withIdentifier: "personPhoto", for: indexPath) as? PhotoTableViewCell else { return UITableViewCell() }
      
      cell.setUpView(personPhoto: personPhoto, nickName: name, email: email)
      cell.choosePhotoBtn.addTarget(self, action: #selector(pickImage), for: .touchUpInside)
      
      return cell
    } else if indexPath.row == 1 {
      
      guard let cell = tableView.dequeueReusableCell(withIdentifier: "personDetail", for: indexPath) as? PersonDetailTableViewCell else { return UITableViewCell() }
      
      cell.delegate = self
      cell.setUpView(isSetting: isSetting, detailTitle: profileDetail[0], content: data[0])
      
      return cell
    } else if indexPath.row == 2 {
      
      guard let cell = tableView.dequeueReusableCell(withIdentifier: "personRate", for: indexPath) as? PersonRateTableViewCell else { return UITableViewCell() }
      
      cell.newUserLabel.isHidden = true
    
      if totaltaskCount == 0 {
        
        cell.setUp(isFirst: true, averageStar: averageStar, titleLabel: profileDetail[1])
        
      } else {
        averageStar = (totalStar - star) / Double(totaltaskCount)
        cell.setUp(isFirst: false, averageStar: averageStar, titleLabel: profileDetail[1])
      }

      return cell
    } else if indexPath.row == 3 {
      
      guard let cell = tableView.dequeueReusableCell(withIdentifier: "personAbout", for: indexPath) as? PersonAboutTableViewCell else { return UITableViewCell() }
      
      cell.delegate = self
      cell.setUpView(isSetting: isSetting, titleLabel: profileDetail[2], content: data[1])
      
      return cell
    } else {
      
      guard let cell = tableView.dequeueReusableCell(withIdentifier: "signOut", for: indexPath) as? SignOutTableViewCell else { return UITableViewCell()  }
      
      cell.taponSignOut = {
        self.logoutAlert()
      }
      return cell
    }
  }
  
  @objc func pickImage() {
    
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
}

extension PersonalViewController: ProfileManager {
  func changeName(tableViewCell: PersonDetailTableViewCell, name: String?, isEdit: Bool) {
    
    guard let name = name else {
      self.isName = false
      self.showAlert()
      return }
    if name.isEmptyOrWhitespace() {
      self.isName = false
      showAlert()
    }
    self.name = name
    self.isName = true
  }
}

extension PersonalViewController: ProfileAboutManager {
  
  func changeAbout(tableViewCell: PersonAboutTableViewCell, about: String?, isEdit: Bool) {
    
    guard let about = about else {
      self.isAbout = false
      return }
    self.about = about
    self.isAbout = true
    
  }
}

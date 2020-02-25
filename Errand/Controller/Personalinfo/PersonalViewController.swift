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
  
  var name = "遊客"
  
  var about = "無"
  
  var minusStar = 0.0
  
  var averageStar = 0.0
  
  var totaltaskCount = 0
  
  var email = "遊客"
  
  var totalStar = 0.0
  
  var trigger = false
  
  let profileDetail = ["暱稱", "歷史評分", "關於我"]
  
  var settingOn: UIBarButtonItem!
  
  var settingOff: UIBarButtonItem!
  
  @IBOutlet weak var cornerView: UIView!
  
  @IBOutlet weak var backgroundImageView: UIImageView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if UserManager.shared.isTourist {
      
      setUpTableView()
    } else {
      setUpNavigationItem()
      setUpTableView()
      guard let photoNow = UserManager.shared.currentUserInfo?.photo else { return }
      personPhoto = photoNow
      imagePickerController.delegate = self
      imagePickerController.allowsEditing = true
      imagePickerController.mediaTypes = [kUTTypeImage as String]
      readJudge()
      totalStar = 0
      totaltaskCount = 0
    }
  }
  
  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    NotificationCenter.default.post(name: Notification.Name("hide"), object: nil)
    cornerView.frame = CGRect(x: UIScreen.main.bounds.width / 2 - 500, y: 340, width: 1000, height: 2000)
    cornerView.backgroundColor = UIColor.white
    backgroundImageView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 1000)
    backgroundImageView.image = UIImage(named: "Ice")
    backgroundImageView.contentMode = .scaleAspectFill
    cornerView.layer.cornerRadius = cornerView.bounds.width / 2
  }
  
  func preventTap() {
    guard let tabVC = self.view.window?.rootViewController as? TabBarViewController else { return }
    LKProgressHUD.show(controller: tabVC)
  }
  
  func setUpNavigationItem() {
    settingOff = UIBarButtonItem(title: "編輯", style: .plain, target: self, action: #selector(tapSet))
    settingOn = UIBarButtonItem(image: UIImage(named: "tick-2"), style: .plain, target: self, action: #selector(tapSet))
    settingOn.tintColor = .black
    settingOff.tintColor = .black
    self.navigationItem.rightBarButtonItems = [self.settingOff]
  }
  
  @objc func tapSet() {
    
    if !isSetting {
      self.navigationItem.setRightBarButtonItems([self.settingOn], animated: false)
      isSetting = !isSetting
      infoTableView.reloadData()
      
    } else {
      self.navigationItem.setRightBarButtonItems([self.settingOff], animated: false)

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
        
        self.preventTap()
        
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
            LKProgressHUD.dismiss()
            LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
          }
        }
      }
    }
    
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
        
        LKProgressHUD.dismiss()
        
        self.infoTableView.reloadData()
        
      case .failure:
        print("error")
      }
    }
  }
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    cornerView.frame.origin.y = 340 - scrollView.contentOffset.y
  }

  @IBOutlet weak var infoTableView: UITableView!
  
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
    let okAction = UIAlertAction(title: "ok", style: .default) { [weak self] _ in
      
      guard let strongSelf = self else { return }
      
      do {
        try Auth.auth().signOut()
        
      } catch {
        print("Error")
      }
      let signInVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "main") as? ViewController
      
      UserManager.shared.isTourist = true
      
      UserManager.shared.currentUserInfo = nil
      
      UserDefaults.standard.removeObject(forKey: "login")
      
      strongSelf.view.window?.rootViewController = signInVC
    }
    
    let cancelAction = UIAlertAction(title: "cancal", style: .cancel, handler: nil)
    controller.addAction(okAction)
    controller.addAction(cancelAction)
    self.present(controller, animated: true, completion: nil)
  }
}

extension PersonalViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    
    preventTap()
    
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
    
    let tourist = UserManager.shared.isTourist
    
    if !tourist {
      
      guard let name = UserManager.shared.currentUserInfo?.nickname,
           let email = UserManager.shared.currentUserInfo?.email,
           let aboutMe = UserManager.shared.currentUserInfo?.about,
           let star = UserManager.shared.currentUserInfo?.totalStar else { return UITableViewCell() }
      
      self.name = name
      self.about = aboutMe
      self.email = email
      self.minusStar = star
    }
      
    LKProgressHUD.dismiss()
    let data = [name, self.about]
    
    if indexPath.row == 0 {
      
      guard let cell = tableView.dequeueReusableCell(withIdentifier: "personPhoto", for: indexPath) as? PhotoTableViewCell else { return UITableViewCell() }
      
      if tourist {
        cell.choosePhotoBtn.isHidden = true
      } else {
        cell.choosePhotoBtn.isHidden = false
      }
      
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
        averageStar = (totalStar - minusStar) / Double(totaltaskCount)
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
      
      if tourist {
        cell.signOutBtn.setTitle("登入", for: .normal)
      } else {
        cell.signOutBtn.setTitle("登出", for: .normal)
      }
      
      cell.taponSignOut = { [weak self] in
        guard let strongSelf = self else { return }
        
        if tourist {
          
          let signInVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "main") as? ViewController
          
          strongSelf.view.window?.rootViewController = signInVC
          
        } else {
          strongSelf.logoutAlert()
        }
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

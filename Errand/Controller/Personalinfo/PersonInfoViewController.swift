//
//  PersonInfoViewController.swift
//  Errand
//
//  Created by Jim on 2020/2/24.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import Firebase
import MobileCoreServices

class PersonInfoViewController: UIViewController {
  
  @IBOutlet weak var backgroundImage: UIImageView!
  
  @IBOutlet weak var photoTableView: UITableView!
  
  let imagePickerController = UIImagePickerController()
  
  let indicatorView = UIView()
  
  var indicatorCon: NSLayoutConstraint?
  
  var isSetting = false
  
  var photo = ""
  
  var settingOn: UIBarButtonItem!
  
  var settingOff: UIBarButtonItem!
  
  @IBOutlet weak var btnStack: UIStackView!
  
  @IBOutlet weak var personInfoBtn: UIButton!
  
  @IBOutlet weak var historyMissionBtn: UIButton!
  
  @IBOutlet weak var historyContainer: UIView!
  
  @IBOutlet weak var userContainer: UIView!
  
  @IBAction func personInfoAct(_ sender: UIButton) {
    historyContainer.alpha = 0.0
    userContainer.alpha = 1.0
    startAnimate(sender: sender)
  }
  
  @IBAction func historyMissionAct(_ sender: UIButton) {
    historyContainer.alpha = 1.0
    userContainer.alpha = 0.0
    startAnimate(sender: sender)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    UserManager.shared.isEditNameEmpty = true
    setUpTableView()
    setUpBackPhoto()
    setUpImagePicker()
    setUpIndicatorView()
    setUpNavigationItem()
    historyContainer.alpha = 0.0
    NotificationCenter.default.addObserver(self, selector: #selector(backToEdit), name: Notification.Name("CompleteEdit"), object: nil)
  }
  
  @objc func backToEdit() {
    self.navigationItem.setRightBarButtonItems([self.settingOff], animated: false)
    isSetting = false
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    guard let user = UserManager.shared.currentUserInfo else { return }
    photo = user.photo
  }
  
  func setUpBackPhoto() {
    backgroundImage.contentMode = .scaleAspectFill
//    backgroundImage.image = UIImage(named: "Space-Expedition")
//    37670
  }
  
  func setUpNavigationItem() {
    settingOff = UIBarButtonItem(title: "編輯", style: .plain, target: self, action: #selector(tapSet))
    settingOn = UIBarButtonItem(image: UIImage(named: "tick-2"), style: .plain, target: self, action: #selector(tapSet))
    settingOn.tintColor = .black
    settingOff.tintColor = .black
    self.navigationItem.rightBarButtonItems = [self.settingOff]
  }
  
  @objc func tapSet() {
    
    self.resignFirstResponder()
    if !isSetting {
      if UserManager.shared.isEditNameEmpty {
        self.navigationItem.setRightBarButtonItems([self.settingOn], animated: false)
        NotificationCenter.default.post(name: Notification.Name("editing"), object: nil)
      } else {
        self.navigationItem.setRightBarButtonItems([self.settingOff], animated: false)
        NotificationCenter.default.post(name: Notification.Name("editing"), object: nil)
        isSetting = !isSetting
      }
    } else {
      if UserManager.shared.isEditNameEmpty {
        self.navigationItem.setRightBarButtonItems([self.settingOn], animated: false)
        NotificationCenter.default.post(name: Notification.Name("editing"), object: nil)
      } else {
      self.navigationItem.setRightBarButtonItems([self.settingOff], animated: false)
        NotificationCenter.default.post(name: Notification.Name("editing"), object: nil)
        isSetting = !isSetting
      }
    }
  }
  
  func setUpTableView() {
    photoTableView.delegate = self
    photoTableView.dataSource = self
    photoTableView.backgroundColor = .clear
    photoTableView.separatorStyle = .none
    photoTableView.rowHeight = UITableView.automaticDimension
    photoTableView.register(UINib(nibName: "PhotoTableViewCell", bundle: nil), forCellReuseIdentifier: "personPhoto")
  }
  
  func setUpImagePicker() {
    imagePickerController.delegate = self
    imagePickerController.allowsEditing = true
    imagePickerController.mediaTypes = [kUTTypeImage as String]
  }
  
  func preventTap() {
    guard let tabVC = self.view.window?.rootViewController as? TabBarViewController else { return }
    LKProgressHUD.show(controller: tabVC)
  }
  
  func startAnimate(sender: UIButton) {
    let move = UIViewPropertyAnimator(duration: 0.2, curve: .easeInOut) {
      self.indicatorCon?.isActive = false
      self.indicatorCon = self.indicatorView.centerXAnchor.constraint(equalTo: sender.centerXAnchor)
      self.indicatorCon?.isActive = true
      self.view.layoutIfNeeded()
    }
    move.startAnimation()
  }
  
  func setUpIndicatorView() {
    self.view.addSubview(indicatorView)
    indicatorView.backgroundColor = .G1
    indicatorView.translatesAutoresizingMaskIntoConstraints = false
    indicatorCon = indicatorView.centerXAnchor.constraint(equalTo: personInfoBtn.centerXAnchor)
    
    NSLayoutConstraint.activate([
      indicatorView.topAnchor.constraint(equalTo: btnStack.bottomAnchor, constant: 0),
      indicatorView.widthAnchor.constraint(equalToConstant: personInfoBtn.bounds.width * 0.7),
      indicatorView.heightAnchor.constraint(equalToConstant: 2),
      indicatorCon!
    ])
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
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "userInfo" {
      guard let userInfoVC = segue.destination as? ChildInfoViewController else { return }
      userInfoVC.view.backgroundColor = .red
    }
    if segue.identifier == "history" {
      guard let historyVC = segue.destination as? ChildhistroyViewController else { return }
      historyVC.view.backgroundColor = .green
    }
  }
}

extension PersonInfoViewController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: "personPhoto", for: indexPath) as? PhotoTableViewCell,
      let userInfo = UserManager.shared.currentUserInfo else { return UITableViewCell() }
    
    cell.setUpView(personPhoto: photo, nickName: userInfo.nickname, email: userInfo.email)
    cell.choosePhotoBtn.addTarget(self, action: #selector(pickImage), for: .touchUpInside)
    cell.backgroundColor = .clear
    return cell
  }
}

extension PersonInfoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
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
                  strongSelf.photo = urlBack.absoluteString
                  NotificationCenter.default.post(name: Notification.Name("update"), object: nil)
                  strongSelf.photoTableView.reloadData()
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

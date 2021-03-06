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
  
  var observation: NSKeyValueObservation?
  
  let imagePickerController = UIImagePickerController()
  
  let indicatorView = UIView()
  
  var indicatorCon: NSLayoutConstraint?
  
  var requester: AccountInfo?
  
  var taskInfo: TaskInfo?
  
  var isSetting = false
  
  var isRequester = false
  
  var photo = ""
  
  var settingOn: UIBarButtonItem!
  
  var settingOff: UIBarButtonItem!
  
  @IBOutlet weak var photoTableView: UITableView!
  
  @IBOutlet weak var cornerView: UIView!
  
  @IBOutlet weak var btnStack: UIStackView!
  
  @IBOutlet weak var personInfoBtn: UIButton!
  
  @IBOutlet weak var historyMissionBtn: UIButton!
  
  @IBOutlet weak var historyContainer: UIView!
  
  @IBOutlet weak var userContainer: UIView!
  
  @IBOutlet weak var btnBackgroundView: UIView!
  
  @IBOutlet weak var backViewHeight: NSLayoutConstraint!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    UserManager.shared.isEditNameEmpty = true
//    personInfoBtn.backgroundColor = UIColor.lightGray
//    historyMissionBtn.backgroundColor = UIColor.lightGray
    setUpTableView()
    setUpImagePicker()
    setUpIndicatorView()
    setUpNavigationItem()
    historyContainer.alpha = 0.0
    observation = UserManager.shared.observe(\.isChange) { [weak self] (_, _) in
      guard let strongSelf = self else { return }
      strongSelf.photoTableView.reloadData()
    }
  }
  
  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    self.navigationController?.navigationItem.title = "個人頁面"
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    if UserManager.shared.isRequester {
      fetchTask()
    }
    
    btnBackgroundView.isHidden = !UserManager.shared.isRequester
    UserManager.shared.isRequester = isRequester
    btnBackgroundView.isHidden = !isRequester
    
    if isRequester {
      guard let requester = UserManager.shared.requesterInfo else { return }
      photo = requester.photo
    } else {
      guard let user = UserManager.shared.currentUserInfo else { return }
      photo = user.photo
    }
    
    NotificationCenter.default.post(name: Notification.Name("hideLog"), object: nil)
  }
  
  @IBAction func personInfoAct(_ sender: UIButton) {
    historyContainer.alpha = 0.0
    userContainer.alpha = 1.0
    startAnimate(sender: sender)
  }
  
  @IBAction func historyMissionAct(_ sender: UIButton) {
    if UserManager.shared.isTourist {
      SwiftMes.shared.showWarningMessage(body: "當前沒有登入", seconds: 0.8)
      
    } else {
      historyContainer.alpha = 1.0
      userContainer.alpha = 0.0
      startAnimate(sender: sender)
    }
  }
  
  @IBAction func acceptAct(_ sender: Any) {
    guard let user = requester,
         var taskInfo = taskInfo else { return }
    
    let chatRoomID = UUID().uuidString
    
    taskInfo.missionTaker = user.uid
    taskInfo.requester = []
    taskInfo.status = 1
    taskInfo.chatRoom = chatRoomID
    
    TaskManager.shared.createChatRoom(chatRoomID: chatRoomID) { result in
      
      switch result {
        
      case .success:
        
        UserManager.shared.updateStatus(uid: user.uid, status: 2) { result in
          
          switch result {
            
          case .success:
            
            guard let uid = UserManager.shared.currentUserInfo?.uid else { return }
            
            TaskManager.shared.updateWholeTask(task: taskInfo, uid: uid) { [weak self] result in
              
              guard let strongSelf = self else { return }
              
              switch result {
                
              case .success:

                APImanager.shared.postNotification(to: user.fcmToken, body: "任務接受成功")
                
                NotificationCenter.default.post(name: Notification.Name("requester"), object: nil)
                strongSelf.navigationController?.popViewController(animated: false)
                
              case .failure:
                
                TaskManager.shared.showAlert(title: "失敗", message: "請重新接受", viewController: strongSelf)
              }
            }
          case .failure(let error):
            
            print(error.localizedDescription)
          }
        }
        
      case .failure(let error):
        
        print(error.localizedDescription)
      }
    }
  }
  
  @IBAction func refuseAct(_ sender: Any) {
    guard let user = requester,
      var taskInfo = taskInfo else { return }
    
    taskInfo.requester = taskInfo.requester.filter({ info in
      
      if info != user.uid {
        return true
      } else {
        return false
      }
    })
    
    taskInfo.refuse.append(user.uid)
    guard let uid = UserManager.shared.currentUserInfo?.uid else { return }
    
    TaskManager.shared.updateWholeTask(task: taskInfo, uid: uid) { [weak self] result in
      
      guard let strongSelf = self else { return }
      
      switch result {
        
      case .success:
        
        NotificationCenter.default.post(name: Notification.Name("refuseRequester"), object: nil)
        APImanager.shared.postNotification(to: user.fcmToken, body: "您已被拒絕")
        NotificationCenter.default.post(name: Notification.Name("requester"), object: nil)
        strongSelf.navigationController?.popViewController(animated: false)
        
      case .failure:
        
        TaskManager.shared.showAlert(title: "失敗", message: "請重新接受", viewController: strongSelf)
      }
    }
  }
  
  @objc func back() {
    self.navigationController?.popViewController(animated: false)
  }
  
  @objc func backToEdit() {
    self.navigationItem.setRightBarButtonItems([self.settingOff], animated: false)
    isSetting = false
  }
  
  func setUpNavigationItem() {
    
    if UserManager.shared.isTourist {
      
    } else if !UserManager.shared.isRequester {
      settingOff = UIBarButtonItem(title: "編輯", style: .plain, target: self, action: #selector(tapSet))
      settingOn = UIBarButtonItem(image: UIImage(named: "tick-2"), style: .plain, target: self, action: #selector(tapSet))
      settingOn.tintColor = .white
      settingOff.tintColor = .white
      self.navigationItem.rightBarButtonItems = [self.settingOff]
    } else {
      navigationItem.setHidesBackButton(true, animated: true)
      NotificationCenter.default.addObserver(self, selector: #selector(backToEdit), name: Notification.Name("CompleteEdit"), object: nil)
      navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Icons_24px_Back02"), style: .plain, target: self, action: #selector(back))
      navigationItem.leftBarButtonItem?.tintColor = .white
    }
  }
  
  func fetchTask() {
    
    guard let uid = Auth.auth().currentUser?.uid else { return }
    
    TaskManager.shared.fetchSpecificParameterData(parameter: "uid", parameterString: uid) { result in
      switch result {
        
      case .success(let data):
        
        if !data.isEmpty {
          self.taskInfo = data[0]
        }
        
      case .failure(let error):
        
        print(error.localizedDescription)
      }
    }
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
    UserManager.shared.isEditNameEmpty = false
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
    indicatorView.backgroundColor = .BB1
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
}

extension PersonInfoViewController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    var name = ""
    var email = ""
    
    guard let cell = tableView.dequeueReusableCell(withIdentifier: "personPhoto", for: indexPath) as? PhotoTableViewCell else { return UITableViewCell() }
    
    if UserManager.shared.isTourist {
      name = "遊客"
    } else if isRequester {
      guard let requester = UserManager.shared.requesterInfo else { return UITableViewCell() }
      name = requester.nickname
      email = requester.email
    } else {
      guard let userInfo = UserManager.shared.currentUserInfo else { return UITableViewCell() }
      name = userInfo.nickname
      email = userInfo.email
    }
    
    cell.setUpView(isRequester: isRequester, personPhoto: photo, nickName: name, email: email)
    cell.choosePhotoBtn.addTarget(self, action: #selector(pickImage), for: .touchUpInside)
    cell.backgroundColor = .clear
    return cell
  }
}

extension PersonInfoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
    
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
              UserManager.shared.updatePersonPhotoURL(photo: urlBack) { result in
                
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

//
//  ChildInfoViewController.swift
//  Errand
//
//  Created by Jim on 2020/2/24.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import FirebaseAuth

class ChildInfoViewController: UIViewController {
  
  var categorys: [CellContent] = [CellContent(type: .detail, title: "暱稱"),
                          CellContent(type: .rate, title: "歷史評分"),
                          CellContent(type: .about, title: "關於我"),
                          CellContent(type: .logout, title: "登出")]
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setUpTableView()
    readJudge()
    UserManager.shared.isEditNameEmpty = false
    NotificationCenter.default.addObserver(self, selector: #selector(changeEdit), name: Notification.Name("editing"), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Notification.Name("hideLog"), object: nil)
  }
  
  @objc func reload() {
    infoTableView.reloadData()
  }
  
  @objc func changeEdit() {
    
    self.view.endEditing(true)
    
    if isSetting {
      if !isName {
        SwiftMes.shared.showErrorMessage(body: "姓名不得為空", seconds: 1.0)
      } else {
        isSetting = !isSetting
        UserManager.shared.preventTap(viewController: self)
        uploadData()
      }
    } else {
      isSetting = !isSetting
      infoTableView.reloadData()
    }
  }
  
  @IBOutlet weak var infoTableView: UITableView!
  
  var isSetting = false
  
  var isName = true
  
  var isUpload = true
  
  var isFirstTap = true
  
  var name = "遊客"
  
  var about = "無"
  
  var aboutHide = ""
  
  var minusStar = 0.0
  
  var averageStar = 0.0
  
  var totaltaskCount = 0
  
  var noJudge = 0
  
  var email = "遊客"
  
  var totalStar = 0.0
  
  let profileDetail = ["暱稱", "歷史評分", "關於我"]
  
  func setUpTableView() {
    infoTableView.delegate = self
    infoTableView.dataSource = self
    infoTableView.separatorStyle = .none
    infoTableView.rowHeight = UITableView.automaticDimension
    infoTableView.register(UINib(nibName: "LogoutTableViewCell", bundle: nil), forCellReuseIdentifier: "logout")
    infoTableView.register(UINib(nibName: "PersonStarTableViewCell", bundle: nil), forCellReuseIdentifier: "rate")
    infoTableView.register(UINib(nibName: "PersonAboutTableViewCell", bundle: nil), forCellReuseIdentifier: "personAbout")
    infoTableView.register(UINib(nibName: "PersonDetailTableViewCell", bundle: nil), forCellReuseIdentifier: "personDetail")
  }
  
  func uploadData() {
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      
      UserManager.shared.currentUserInfo?.nickname = self.name
      UserManager.shared.currentUserInfo?.about = self.aboutHide
      guard let userInfo = UserManager.shared.currentUserInfo else { return }
      
      UserManager.shared.updateOppoInfo(userInfo: userInfo) { [weak self] result in
        guard let strongSelf = self else { return }
        
        switch result {
        case .success:
          LKProgressHUD.dismiss()
          UserManager.shared.isEditNameEmpty = true
          NotificationCenter.default.post(name: Notification.Name("CompleteEdit"), object: nil)
          strongSelf.infoTableView.reloadData()
        case .failure:
          print("error")
        }
      }
    }
  }
  
  func readJudge() {
    
    guard let uid = UserManager.shared.currentUserInfo?.uid else { return }
    TaskManager.shared.readJudgeData(uid: uid) {[weak self] result in
      guard let strongSelf = self else { return }
      switch result {
      case .success(let judgeData):
        
        judgeData.forEach { data in
          strongSelf.totalStar += data.star
        }
        
        strongSelf.totaltaskCount = judgeData.count
        LKProgressHUD.dismiss()
        strongSelf.infoTableView.reloadData()
        
      case .failure:
        print("error")
      }
    }
  }
  
  func logIn() {
    let signInVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "main") as? ViewController
    self.view.window?.rootViewController = signInVC
  }
  
  func logout() {
    
    let alertControl = UIAlertController(title: "注意", message: "您真的要登出嗎？", preferredStyle: .alert)
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
    alertControl.addAction(okAction)
    alertControl.addAction(cancelAction)
    self.present(alertControl, animated: true, completion: nil)
  }
}

extension ChildInfoViewController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return UserManager.shared.isRequester ? 3 : 4
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let tourist = UserManager.shared.isTourist
    var containerUserInfo: AccountInfo?
    
    if UserManager.shared.isTourist {
      
    } else if !tourist && !UserManager.shared.isRequester {
      containerUserInfo = UserManager.shared.currentUserInfo
    } else {
      containerUserInfo = UserManager.shared.requesterInfo
    }
    
    if !UserManager.shared.isTourist {
      guard let container = containerUserInfo else { return UITableViewCell() }
      self.name = container.nickname
      self.about = container.about
      self.email = container.email
      self.totalStar = container.totalStar
      self.minusStar = container.minusStar
      self.noJudge = container.noJudgeCount
      self.totaltaskCount = container.taskCount
    }

    LKProgressHUD.dismiss()
    let data = [name, self.about]
    
    let category = categorys[indexPath.item]
    
    switch categorys[indexPath.item].type {
      
    case .detail:
      guard let cell = tableView.dequeueReusableCell(withIdentifier: "personDetail", for: indexPath) as? PersonDetailTableViewCell else { return UITableViewCell() }
      
      cell.setUpView(isSetting: isSetting, detailTitle: category.title, content: data[0])
      cell.delegate = self
      return cell
      
    case .rate:
      guard let cell = tableView.dequeueReusableCell(withIdentifier: "rate", for: indexPath) as? PersonStarTableViewCell else { return UITableViewCell() }
      
      cell.newUserLabel.isHidden = true
      
      if totaltaskCount == 0 || totaltaskCount == noJudge {
        
        cell.setUp(isFirst: true, averageStar: averageStar, titleLabel: category.title)
        
      } else {
        averageStar = ((totalStar) / Double(totaltaskCount - noJudge)) - minusStar
        cell.setUp(isFirst: false, averageStar: averageStar, titleLabel: category.title)
      }
      return cell
      
    case .about:
      guard let cell = tableView.dequeueReusableCell(withIdentifier: "personAbout", for: indexPath) as? PersonAboutTableViewCell else { return UITableViewCell() }
      
      cell.delegate = self
      cell.setUpView(isSetting: isSetting, titleLabel: category.title, content: data[1])
      return cell
      
    case .logout:
      guard let cell = tableView.dequeueReusableCell(withIdentifier: "logout", for: indexPath) as? LogoutTableViewCell else { return UITableViewCell() }
      
      cell.setUp(isTourist: UserManager.shared.isTourist)
      
      cell.touchHandler = { [weak self] in
        guard let strongSelf = self else { return }
        if UserManager.shared.isTourist {
          strongSelf.logIn()
        } else {
          strongSelf.logout()
        }
      }
      return cell
    default:
      return UITableViewCell()
    }
  }
}

extension ChildInfoViewController: ProfileManager {
  func changeName(tableViewCell: PersonDetailTableViewCell, name: String?, isEdit: Bool) {
    guard let name = name else { return }
    if !name.isEmpty {
      UserManager.shared.isEditNameEmpty = false
      self.name = name
      isName = true
    } else {
      UserManager.shared.isEditNameEmpty = true
      isName = false
    }
  }
}

extension ChildInfoViewController: ProfileAboutManager {
  func changeAbout(tableViewCell: PersonAboutTableViewCell, about: String?, isEdit: Bool) {
    guard let about = about else { return }
    if !about.isEmpty {
      self.about = about
      self.aboutHide = about
      UserManager.shared.isEditNameEmpty = false
    }
  }
}

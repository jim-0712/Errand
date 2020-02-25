//
//  ChildInfoViewController.swift
//  Errand
//
//  Created by Jim on 2020/2/24.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit

class ChildInfoViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        readJudge()
        UserManager.shared.isEditNameEmpty = false
        NotificationCenter.default.addObserver(self, selector: #selector(changeEdit), name: Notification.Name("editing"), object: nil)
        // Do any additional setup after loading the view.
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
  
  var isAbout = false
  
  var isUpload = true
  
  var isFirstTap = true
  
  var name = "遊客"
  
  var about = "無"
  
  var minusStar = 0.0
  
  var averageStar = 0.0
  
  var totaltaskCount = 0
  
  var email = "遊客"
  
  var totalStar = 0.0
  
  let profileDetail = ["暱稱", "歷史評分", "關於我"]
  
  func setUpTableView() {
    infoTableView.delegate = self
    infoTableView.dataSource = self
    infoTableView.separatorStyle = .none
    infoTableView.register(UINib(nibName: "PersonDetailTableViewCell", bundle: nil), forCellReuseIdentifier: "personDetail")
    infoTableView.register(UINib(nibName: "PersonAboutTableViewCell", bundle: nil), forCellReuseIdentifier: "personAbout")
    infoTableView.register(UINib(nibName: "PersonStarTableViewCell", bundle: nil), forCellReuseIdentifier: "rate")
  }
  
  func uploadData() {
    UserManager.shared.currentUserInfo?.nickname = self.name
    UserManager.shared.currentUserInfo?.about = self.about
    UserManager.shared.updateUserInfo { [weak self] result in
      guard let strongSelf = self else { return }
      
      switch result {
      case .success:
        LKProgressHUD.dismiss()
        UserManager.shared.isEditNameEmpty = true
        strongSelf.infoTableView.reloadData()
      case .failure:
        print("error")
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
  
}

extension ChildInfoViewController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 3
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
      
      guard let cell = tableView.dequeueReusableCell(withIdentifier: "personDetail", for: indexPath) as? PersonDetailTableViewCell else { return UITableViewCell() }
 
      cell.setUpView(isSetting: isSetting, detailTitle: profileDetail[0], content: data[0])
      cell.delegate = self
      
      return cell
    } else if indexPath.row == 1 {
      
      guard let cell = tableView.dequeueReusableCell(withIdentifier: "rate", for: indexPath) as? PersonStarTableViewCell else { return UITableViewCell() }
      
      cell.newUserLabel.isHidden = true
    
      if totaltaskCount == 0 {

        cell.setUp(isFirst: true, averageStar: averageStar, titleLabel: profileDetail[1])

      } else {
        averageStar = (totalStar - minusStar) / Double(totaltaskCount)
        cell.setUp(isFirst: false, averageStar: averageStar, titleLabel: profileDetail[1])
      }

      return cell
    } else {
      
      guard let cell = tableView.dequeueReusableCell(withIdentifier: "personAbout", for: indexPath) as? PersonAboutTableViewCell else { return UITableViewCell() }
      
      cell.setUpView(isSetting: isSetting, titleLabel: profileDetail[2], content: data[1])
      cell.delegate = self
      
      return cell
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
    }
  }
}

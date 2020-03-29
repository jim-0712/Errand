//
//  BlacklistViewController.swift
//  Errand
//
//  Created by Jim on 2020/3/1.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit

class BlacklistViewController: UIViewController {
  
  @IBOutlet weak var blackListTable: UITableView!
  
  var blacklistinfo: [AccountInfo] = [] {
    didSet {
      if blacklistinfo.isEmpty {
        LKProgressHUD.dismiss()
      } else {
        LKProgressHUD.dismiss()
        blackListTable.reloadData()
      }
    }
  }
  
  var blackuid: [String] = []
  
  var removeBlack: [String] = []
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setUpTable()
    readBlackData()
    setUpNavigation()
    if UserDefaults.standard.value(forKey: "black") as? Bool == nil {
      showAlert()
    }
    guard let blackList = UserManager.shared.currentUserInfo?.blacklist else { return }
    blackuid = blackList
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    UserManager.shared.currentUserInfo?.blacklist = blackuid
    
    guard let userInfo = UserManager.shared.currentUserInfo else { return }
    
    UserManager.shared.updateOppoInfo(userInfo: userInfo) { result in
      switch result {
      case .success:
        print("Success on update userInfo")
      case .failure:
        print("Fail on update userInfo")
      }
    }
  }
  
  @objc func back() {
    self.navigationController?.popViewController(animated: false)
  }
  
  func showAlert() {
    let alert = UIAlertController(title: "溫馨小提醒", message: "左滑可以移除黑名單", preferredStyle: .alert)
    let okAction = UIAlertAction(title: "ok", style: .default) { _ in
      UserDefaults.standard.set(false, forKey: "black")
    }
    alert.addAction(okAction)
    present(alert, animated: true, completion: nil)
  }
  
  func setUpNavigation() {
    navigationItem.setHidesBackButton(true, animated: true)
    navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Icons_24px_Back02"), style: .plain, target: self, action: #selector(back))
    navigationItem.leftBarButtonItem?.tintColor = .white
  }

  func setUpTable() {
    blackListTable.delegate = self
    blackListTable.dataSource = self
    blackListTable.separatorStyle = .none
    blackListTable.rowHeight = UITableView.automaticDimension
    let black = UINib(nibName: "BlackTableViewCell", bundle: nil)
    blackListTable.register(black, forCellReuseIdentifier: "BlackTableViewCell")
  }
  
  func readBlackData() {
    guard let blackList = UserManager.shared.currentUserInfo?.blacklist else { return }
    var blacklistCounter: [AccountInfo] = []
    
    blackList.forEach { uid in
      
      UserManager.shared.readUserInfo(uid: uid, isSelf: false) { [weak self] result in
        guard let strongSelf = self else { return }
        switch result {
        case .success(let accountInfo):
          blacklistCounter.append(accountInfo)
          if blacklistCounter.count == blackList.count {
            strongSelf.blacklistinfo = blacklistCounter
          }
        case .failure:
          print("error")
        }
      }
    }
  }
}

extension BlacklistViewController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    return blacklistinfo.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    guard let cell = tableView.dequeueReusableCell(withIdentifier: "BlackTableViewCell", for: indexPath) as? BlackTableViewCell else { return UITableViewCell() }
    
    let blackPeople = blacklistinfo[indexPath.row]
    
    cell.setUpcell(image: blackPeople.photo, nickname: blackPeople.nickname, email: blackPeople.email)
    
    return cell
  }
  
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
  
    if editingStyle == .delete {
      
      UserManager.shared.readUserInfo(uid: blackuid[indexPath.item], isSelf: false) { [weak self] result in
        guard let strongSelf = self,
             let currentUser = UserManager.shared.currentUserInfo?.uid else { return }
        
        switch result {
        case .success(var accountInfo):
          
          accountInfo.oppoBlacklist = accountInfo.oppoBlacklist.filter({ $0 != currentUser})
          
          UserManager.shared.updateOppoInfo(userInfo: accountInfo) { result in
            switch result {
            case .success:
              print("Success update Blacklist")
            case .failure:
              print("Error on update Blacklist")
            }
          }
          
        case .failure(let error):
          LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
        }
      }
      blacklistinfo.remove(at: indexPath.item)
      blackuid.remove(at: indexPath.item)
      blackListTable.deleteRows(at: [indexPath], with: .automatic)
    }
  }
  
  func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
    return "移除"
  }
  
  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
}

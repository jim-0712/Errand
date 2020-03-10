//
//  FriendViewController.swift
//  Errand
//
//  Created by Jim on 2020/2/15.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import Firebase

class FriendViewController: UIViewController {
  
  var refreshControl: UIRefreshControl!
  
  var friend = [Friends]()
  
  var friendsPhoto: [String] = []
  
  var friendsData = [AccountInfo]()
  
  var indexRow = 0
  
  var friendInfo = [AccountInfo]() {
    didSet {
      if friend.isEmpty {
        refreshControl.endRefreshing()
        LKProgressHUD.dismiss()
        noFreindsLabel.text = "您目前沒有好友"
        friendListTable.backgroundColor = .clear
      } else {
        LKProgressHUD.dismiss()
        friendListTable.backgroundColor = .LG1
        noFreindsLabel.text = ""
        refreshControl.endRefreshing()
        friendListTable.reloadData()
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = .LG1
    
    if UserManager.shared.isTourist {
      noFreindsLabel.text = "請先去個人頁登入享有好友"
      friendListTable.backgroundColor = .clear
    } else {
      noFreindsLabel.text = "搜尋好友中"
      setUpTable()
      getFriend()
      
      self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "ban"), style: .plain, target: self, action: #selector(enterBlacklist))
      self.navigationItem.rightBarButtonItem?.tintColor = .red
      
    }
  }
  
  @IBOutlet weak var friendListTable: UITableView!
  
  @IBOutlet weak var noFreindsLabel: UILabel!
  
  @objc func getFriend() {
    
    self.friendsData = []
    
    UserManager.shared.fetchFriends { result in
      switch result {
      case .success(let friends):
        
        if friends.isEmpty {
          self.friendInfo = []
          LKProgressHUD.dismiss()
        }
        
        friends.forEach { friend in
          UserManager.shared.fetchPersonPhoto(nameRef: friend.nameREF) { result in
            switch result {
            case .success(let info):
              self.friendsPhoto.append(info.photo)
              self.friendsData.append(info)
              if self.friendsData.count == friends.count {
                self.friendInfo = self.friendsData
              }
              LKProgressHUD.dismiss()
            case .failure:
              LKProgressHUD.dismiss()
              print("Error on fetchPhoto")
            }
          }
        }
        self.friend = friends
      case .failure:
        LKProgressHUD.dismiss()
        print("Error on Fetch Friends")
      }
    }
  }
  
  @objc func enterBlacklist() {
    guard let userInfo = UserManager.shared.currentUserInfo else { return }
    if userInfo.blacklist.isEmpty {
      SwiftMes.shared.showWarningMessage(body: "當前黑名單人員為空", seconds: 0.75)
    } else {
      performSegue(withIdentifier: "blackList", sender: nil)
    }
  }
  
  func setUpTable() {
    friendListTable.isHidden = false
    friendListTable.delegate = self
    friendListTable.dataSource = self
    friendListTable.separatorStyle = .none
    refreshControl = UIRefreshControl()
    friendListTable.addSubview(refreshControl)
    refreshControl.addTarget(self, action: #selector(getFriend), for: .valueChanged)
    friendListTable.rowHeight = UITableView.automaticDimension
    friendListTable.register(UINib(nibName: "FriendsTableViewCell", bundle: nil), forCellReuseIdentifier: "friends")
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "friendChat" {
      guard let chatVC = segue.destination as? FriendChatViewController else { return }
      chatVC.chatRoom = friend[indexRow]
      chatVC.reverseUID = friendsData[indexRow].uid
      chatVC.reversePhoto = friendsData[indexRow].photo
    }
  }
}

extension FriendViewController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return friendInfo.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    guard let cell = tableView.dequeueReusableCell(withIdentifier: "friends", for: indexPath) as? FriendsTableViewCell else { return UITableViewCell() }
    
    cell.setUpCell(image: friendsPhoto[indexPath.row], nickName: friendInfo[indexPath.row].nickname, account: friendInfo[indexPath.row].email)
    
    cell.tapOnButton = { [weak self] in
      guard let strongSelf = self else { return }
      strongSelf.indexRow = indexPath.row
      strongSelf.performSegue(withIdentifier: "friendChat", sender: nil)
    }
    return cell
  }
  
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    
    if editingStyle == .delete {
      guard let uid = Auth.auth().currentUser?.uid else { return }
      let path = friendsData[indexPath.item]
      friend[indexPath.item].nameREF.collection("Friends").document(uid).delete()
      Firestore.firestore().collection("Users").document(uid).collection("Friends").document(path.uid).delete()
      friendsData.remove(at: indexPath.item)
      friendInfo.remove(at: indexPath.item)
      friendsPhoto.remove(at: indexPath.item)
      friendListTable.reloadData()
    }
  }
  
  func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
    return "移除"
  }
  
  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
}

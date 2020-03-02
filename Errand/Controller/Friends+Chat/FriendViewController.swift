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

    override func viewDidLoad() {
        super.viewDidLoad()
      self.view.backgroundColor = .LG1
      
      if UserManager.shared.isTourist {
        noFreindsLabel.text = "請先去個人頁登入享有好友"
        friendListTable.backgroundColor = .clear
      } else {
        noFreindsLabel.text = "搜尋好友中"
        setUpTable()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "ban"), style: .plain, target: self, action: #selector(enterBlacklist))
        self.navigationItem.rightBarButtonItem?.tintColor = .red
        
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
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if UserManager.shared.isTourist {
      friendListTable.backgroundColor = .clear
    } else {
      preventTap()
      getFriend()
    }
  }
  
  func preventTap() {
    guard let tabVC = self.view.window?.rootViewController as? TabBarViewController else { return }
    LKProgressHUD.show(controller: tabVC)
  }
  
  var refreshControl: UIRefreshControl!
  
  var friend = [Friends]()
  
//  var deleteUID: [String] = []
  
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
  
  @IBOutlet weak var friendListTable: UITableView!
  
  @IBOutlet weak var noFreindsLabel: UILabel!
  
  func setUpTable() {
    NotificationCenter.default.post(name: Notification.Name("hide"), object: nil)
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
  
  @objc func getFriend() {
    
    self.friendsData = []
    
    UserManager.shared.getFriends { result in
      switch result {
      case .success(let friends):
        
        if friends.count == 0 {
          self.friendInfo = []
          LKProgressHUD.dismiss()
        }
        for count in 0 ..< friends.count {
          UserManager.shared.getPhoto(nameRef: friends[count].nameREF) { result in
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
              print("error")
            }
          }
        }
        self.friend = friends
      case .failure:
        LKProgressHUD.dismiss()
        print("error")
      }
    }
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
      friendListTable.deleteRows(at: [indexPath], with: .automatic)
    }
  }
  
  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
}

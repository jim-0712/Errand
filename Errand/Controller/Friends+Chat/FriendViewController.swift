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
      
      if UserManager.shared.isTourist {
        UserManager.shared.goToSign(viewController: self)
      } else {
        setUpTable()
      }
    }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    friendListTable.backgroundColor = .clear
    
    getFriend()
  }
  
  var refreshControl: UIRefreshControl!
  
  var friend = [Friends]()
  
  var friendsPhoto: [String] = []
  
  var friendsData = [AccountInfo]()
  
  var indexRow = 0
  
  var friendInfo = [AccountInfo]() {
     didSet {
       if friend.isEmpty {
        refreshControl.endRefreshing()
        noFreindsLabel.text = "您目前沒有好友                    請趕快完成第一個任務加好友吧"
        friendListTable.backgroundColor = .clear
         } else {
         friendListTable.backgroundColor = .white
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
    
    UserManager.shared.getFriends { result in
      switch result {
      case .success(let friends):
        
        if friends.count == 0 {
          self.friendInfo = []
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
            case .failure:
              print("error")
            }
          }
        }
        self.friend = friends
      case .failure:
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
    
    cell.tapOnButton = {
      self.indexRow = indexPath.row
      self.performSegue(withIdentifier: "friendChat", sender: nil)
    }
    return cell
  }
}

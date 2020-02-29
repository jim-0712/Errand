//
//  ChildhistroyViewController.swift
//  Errand
//
//  Created by Jim on 2020/2/24.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import Firebase

class ChildhistroyViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    setUpTable()
    readJudge()
  }
    
  @IBOutlet weak var historyTableView: UITableView!
  
  var judgeData: [JudgeInfo] = [] {
    
    didSet {
      if judgeData.isEmpty {
        
      } else {
        LKProgressHUD.dismiss()
        historyTableView.reloadData()
      }
    }
  }
  
  func readJudge() {
    guard let uid = Auth.auth().currentUser?.uid else { return }
    TaskManager.shared.readJudgeData(uid: uid) {[weak self] result in
      guard let strongSelf = self else { return }
      switch result {
      case .success(let judge):
        strongSelf.judgeData = judge
      case .failure:
        print("error")
      }
    }
  }
  
//  TaskManager.shared.filterClassified(classified: data.classfied + 1)
  
  func setUpTable() {
    historyTableView.delegate = self
    historyTableView.dataSource = self
    historyTableView.allowsSelection = false
    historyTableView.rowHeight = UITableView.automaticDimension
    let historyCell = UINib(nibName: "HistoryJudgeTableViewCell", bundle: nil)
    historyTableView.register(historyCell, forCellReuseIdentifier: "historyJudge")
  }
}

extension ChildhistroyViewController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return judgeData.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    guard let cell = tableView.dequeueReusableCell(withIdentifier: "historyJudge", for: indexPath) as? HistoryJudgeTableViewCell else { return UITableViewCell() }
    
    let groupImage = TaskManager.shared.filterClassified(classified: judgeData[indexPath.row].classified + 1)
    let data = judgeData[indexPath.row]
    
    cell.setUp(starCount: data.star, judge: data.judge, classified: groupImage[1])
    return cell
  }
}


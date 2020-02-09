//
//  StartMissionViewController.swift
//  Errand
//
//  Created by Jim on 2020/2/7.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import FirebaseAuth

class StartMissionViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
  var receiveTime: String?
  
  var detailData: TaskInfo?
  
  @IBAction func enterChatroomAct(_ sender: Any) {
    
    performSegue(withIdentifier: "chat", sender: nil)
    
   }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
    if segue.identifier == "chat" {
      guard let chatroomVC = segue.destination as? ChatViewController,
           let data = detailData else { return }
      
        chatroomVC.modalPresentationStyle = .fullScreen
        chatroomVC.detailData = data

      }
  }

}

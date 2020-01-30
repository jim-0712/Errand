//
//  PostTaskViewController.swift
//  Errand
//
//  Created by Jim on 2020/1/16.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit

class MissionListViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

  @IBOutlet weak var postMissionBtn: UIButton!
  
  @IBAction func postMissionBtn(_ sender: Any) {
    
    performSegue(withIdentifier: "post", sender: nil)
    
  }
  
}

//
//  TabBarViewController.swift
//  Errand
//
//  Created by Jim on 2020/1/31.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

      setupViewController()
        // Do any additional setup after loading the view.
    }
  
  func setupViewController() {
          viewControllers = [
            
            GoogleMapViewController(), MissionListViewController(), PersonalViewController()
//              generateNavigationController(for: GoogleMapViewController(), title: "Home", image: #imageLiteral(resourceName: "develop")),
//              generateNavigationController(for: MissionListViewController(), title: "Search", image: #imageLiteral(resourceName: "compass")),
//              generateNavigationController(for: PersonalViewController(), title: "Library", image: #imageLiteral(resourceName: "broom"))
          ]
      }
  
  fileprivate func generateNavigationController(for rootViewConroller: UIViewController, title: String, image: UIImage) -> UIViewController {
          let navController = UINavigationController(rootViewController: rootViewConroller)
          //        navController.navigationBar.prefersLargeTitles = true
          rootViewConroller.navigationItem.title = title
          navController.tabBarItem.title = title
          navController.tabBarItem.image = image
          return navController
      }

}

//import UIKit
//class  MainTabBarController: UITabBarController {
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        UINavigationBar.appearance().prefersLargeTitles = true
//        tabBar.tintColor = .systemTeal
//        setupViewController()
//    }
//    //MARK:- Setup Functions
//    func setupViewController() {
//        viewControllers = [
//            generateNavigationController(for: HomeViewController(), title: "Home", image: #imageLiteral(resourceName: "home")),
//            generateNavigationController(for: SearchController(), title: "Search", image: #imageLiteral(resourceName: "search-2")),
//            generateNavigationController(for: ViewController(), title: "Library", image: #imageLiteral(resourceName: "playlist-3")),
//            generateNavigationController(for: ViewController(), title: "Profile", image: #imageLiteral(resourceName: "musician"))
//        ]
//    }
//    //MARK:- Helper Functions
//    fileprivate func generateNavigationController(for rootViewConroller: UIViewController, title: String, image: UIImage) -> UIViewController {
//        let navController = UINavigationController(rootViewController: rootViewConroller)
//        //        navController.navigationBar.prefersLargeTitles = true
//        rootViewConroller.navigationItem.title = title
//        navController.tabBarItem.title = title
//        navController.tabBarItem.image = image
//        return navController
//    }
//}

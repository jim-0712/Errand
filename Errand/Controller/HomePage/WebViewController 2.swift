//
//  WebViewController.swift
//  Errand
//
//  Created by Jim on 2020/3/2.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
        // Do any additional setup after loading the view.
    }
  
  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    dismissBtn.layer.cornerRadius = dismissBtn.bounds.width / 2
  }
  
  var url: String = "https://github.com/jim-0712/ErrandBee/blob/master/README.md"
    
  lazy var webView: WKWebView = {
    let view = WKWebView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    return view
  }()
  
  lazy var dismissBtn: UIButton = {
    let btn = UIButton()
    btn.translatesAutoresizingMaskIntoConstraints = false
    btn.setImage(UIImage(named: "close"), for: .normal)
    btn.backgroundColor = .red
    btn.addTarget(self, action: #selector(goBack), for: .touchUpInside)
    return btn
  }()
  
  @objc func goBack() {
    self.dismiss(animated: true, completion: nil)
  }
  
  func setUp() {
    LKProgressHUD.show(controller: self)
    
    self.view.addSubview(webView)
    
    NSLayoutConstraint.activate([
      webView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
      webView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
      webView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
      webView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0)
    ])
    
    self.view.addSubview(dismissBtn)
    
    NSLayoutConstraint.activate([
      dismissBtn.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
      dismissBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
      dismissBtn.widthAnchor.constraint(equalToConstant: 40),
      dismissBtn.heightAnchor.constraint(equalToConstant: 40)
    ])
    
    guard let privacyUrl = URL(string: url) else { return }
    let request = URLRequest(url: privacyUrl)
    webView.load(request)
    
  }
}

//
//  ViewController.swift
//  Errand
//
//  Created by Jim on 2020/1/15.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import CryptoKit
import GoogleSignIn
import FirebaseAuth
import FBSDKLoginKit
import IQKeyboardManager
import AuthenticationServices

class ViewController: UIViewController {
  
  var isEmail = false
  
  var photo = ""
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setUpBtn()
    setUpAppleBtn()
    IQKeyboardManager.shared().isEnabled = true
    
    NotificationCenter.default.addObserver(self, selector: #selector(goToUserInfo), name: Notification.Name("userInfo"), object: nil)
  }
  
  let backgroundManager = BackgroundManager.shared
  
  @IBOutlet weak var logoLabel: UILabel!
  
  @IBOutlet weak var fbLoginBtn: UIButton!
  
  @IBOutlet weak var googleLoginBtn: UIButton!
  
  @IBOutlet weak var visitorBtn: UIButton!
  
  @IBOutlet weak var appleView: UIView!
  
  @IBAction func visitorAct(_ sender: Any) {
    UserManager.shared.isTourist = true
    gotoMap(viewController: self)
  }
  
  @IBAction func googleLoginAct(_ sender: Any) {
    GIDSignIn.sharedInstance()?.signIn()
  }
  
  @IBAction func fbLoginAct(_ sender: Any) {
    
    UserManager.shared.fbLogin(controller: self) { result in
      
      switch result {
        
      case .success(let accessToken):
        
        UserManager.shared.loginFireBaseWithFB(accesstoken: accessToken, controller: self) { result in
          
          switch result {
            
          case .success:
            
            LKProgressHUD.show(controller: self)
            
            UserManager.shared.loadFBProfile(controller: self) { [weak self] result in
              
              guard let strongSelf = self else { return }
              
              switch result {
                
              case .success:
                
                UserManager.shared.isTourist = false
                
                strongSelf.createDataBase(isApple: false) { result in
                  
                  switch result {
                    
                  case .success(let success):
                    
                    LKProgressHUD.dismiss()
                    UserManager.shared.isTourist = false
                    UserManager.shared.updatefcmToken()
                    
                    LKProgressHUD.showSuccess(text: success, controller: strongSelf)
                    
                    strongSelf.gotoMap(viewController: strongSelf)
                    
                  case .failure(let error):
                    
                    LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
                    
                  }
                }
                
              case .failure(let error):
                
                LKProgressHUD.dismiss()
                LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
              }
            }
            
          case .failure(let error):
            
            LKProgressHUD.showFailure(text: error.localizedDescription, controller: self)
          }
        }
      case .failure(let error):
        
        LKProgressHUD.showFailure(text: error.localizedDescription, controller: self)
      }
    }
  }
  
  let appleButton: ASAuthorizationAppleIDButton = {
    let button = ASAuthorizationAppleIDButton()
    button.addTarget(self, action: #selector(startSignInWithAppleFlow), for: .touchUpInside)
    button.layer.cornerRadius = button.bounds.height / 2
    return button
  }()
  
  func setUpBtn() {
    fbLoginBtn.layer.cornerRadius = fbLoginBtn.bounds.height / 2
    googleLoginBtn.layer.cornerRadius = googleLoginBtn.bounds.height / 2
    visitorBtn.layer.cornerRadius = visitorBtn.bounds.height / 2
    GIDSignIn.sharedInstance()?.presentingViewController = self
    logoLabel.transform = CGAffineTransform(a: 1.0, b: -0.15, c: 0, d: 0.7, tx: 0, ty: 10)
    let backView = backgroundManager.setUpView(view: self.view)
    self.view.layer.insertSublayer(backView, at: 0)
    
  }
  
  func setUpAppleBtn() {
    appleView.backgroundColor = .clear
    appleView.addSubview(appleButton)
    appleButton.translatesAutoresizingMaskIntoConstraints = false
    
    NSLayoutConstraint.activate([
      appleButton.topAnchor.constraint(equalTo: appleView.topAnchor, constant: 0),
      appleButton.bottomAnchor.constraint(equalTo: appleView.bottomAnchor, constant: 0),
      appleButton.leadingAnchor.constraint(equalTo: appleView.leadingAnchor, constant: 0),
      appleButton.trailingAnchor.constraint(equalTo: appleView.trailingAnchor, constant: 0)
      ])
  }
  
  @objc func goToUserInfo () {
    
    UserManager.shared.isTourist = false
    
    self.createDataBase(isApple: false) { [weak self] result in
        
        guard let strongSelf = self else { return }
        
        switch result {
          
        case .success(let success):
          
          UserManager.shared.isTourist = false
          UserManager.shared.updatefcmToken()
          LKProgressHUD.showSuccess(text: success, controller: strongSelf)
    
          strongSelf.gotoMap(viewController: strongSelf)
          
        case .failure(let error):
          
          LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
          
        }
      }
  }
  
  func createDataBase(isApple: Bool, completion: @escaping (Result<String, Error>) -> Void) {
    
    if isApple {
      self.photo = ""
    } else {
      guard let photoBack = Auth.auth().currentUser?.photoURL?.absoluteString else { return }
      self.photo = photoBack
    }
    
    guard let email = Auth.auth().currentUser?.email else { return }
    
    UserManager.shared.createDataBase(classification: "Users", nickName: "使用者", email: email, photo: self.photo) { result in
      
      switch result {
        
      case .success:
        
        completion(.success("good"))
        
      case .failure:
        
        completion(.failure(RegiError.registFailed))
      }
    }
  }
  
  private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: Array<Character> =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length

    while remainingLength > 0 {
      let randoms: [UInt8] = (0 ..< 16).map { _ in
        var random: UInt8 = 0
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
        if errorCode != errSecSuccess {
          fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        return random
      }

      randoms.forEach { random in
        if length == 0 {
          return
        }

        if random < charset.count {
          result.append(charset[Int(random)])
          remainingLength -= 1
        }
      }
    }

    return result
  }
  
  fileprivate var currentNonce: String?
  
 @objc func startSignInWithAppleFlow() {
    let nonce = randomNonceString()
    currentNonce = nonce
    let appleIDProvider = ASAuthorizationAppleIDProvider()
    let request = appleIDProvider.createRequest()
    request.requestedScopes = [.fullName, .email]
    request.nonce = sha256(nonce)

    let authorizationController = ASAuthorizationController(authorizationRequests: [request])
    authorizationController.delegate = self
    authorizationController.presentationContextProvider = self
    authorizationController.performRequests()
  }

  private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    let hashString = hashedData.compactMap {
      return String(format: "%02x", $0)
    }.joined()

    return hashString
  }
}

extension ViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    
    return self.view.window!
  }
  
  func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
      guard let nonce = currentNonce else {
        fatalError("Invalid state: A login callback was received, but no login request was sent.")
      }
      guard let appleIDToken = appleIDCredential.identityToken else {
        print("Unable to fetch identity token")
        return
      }
      guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
        print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
        return
      }
   
      let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                idToken: idTokenString,
                                                rawNonce: nonce)
      // Sign in with Firebase.
      Auth.auth().signIn(with: credential) { (_, error) in

        if let error = error {
          print(error)
          return
        }
        
        self.createDataBase(isApple: true) { [weak self] result in
            
            guard let strongSelf = self else { return }
            
            switch result {
              
            case .success(let success):
              
              UserManager.shared.isTourist = false
              UserManager.shared.updatefcmToken()
              LKProgressHUD.showSuccess(text: success, controller: strongSelf)
        
              strongSelf.gotoMap(viewController: strongSelf)
              
            case .failure(let error):
              
              LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
              
            }
          }
      }
    }
  }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    // Handle error.
    print("Sign in with Apple errored: \(error)")
  }

  func gotoMap(viewController: UIViewController) {
    
    guard let mapVc  = UIStoryboard(name: "Content", bundle: nil).instantiateViewController(identifier: "tab") as? TabBarViewController else { return }
        viewController.present(mapVc, animated: true, completion: nil)
    }
  
}

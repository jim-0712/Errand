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
  
  let backgroundManager = BackgroundManager.shared
  
  @IBOutlet weak var logoLabel: UILabel!
  
  @IBOutlet weak var fbLoginBtn: UIButton!
  
  @IBOutlet weak var googleLoginBtn: UIButton!
  
  @IBOutlet weak var visitorBtn: UIButton!
  
  @IBOutlet weak var appleView: UIView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setUpBtn()
    setUpAppleBtn()
    IQKeyboardManager.shared().isEnabled = true
    NotificationCenter.default.addObserver(self, selector: #selector(goToUserInfo), name: Notification.Name("userInfo"), object: nil)
  }
  
  func preventTap() {
    guard let rootVC = self.view.window?.rootViewController else { return }
    LKProgressHUD.show(controller: rootVC)
  }
  
  @IBAction func visitorAct(_ sender: Any) {
    UserManager.shared.isTourist = true
    gotoMap(viewController: self)
  }
  
  @IBAction func googleLoginAct(_ sender: Any) {
    GIDSignIn.sharedInstance()?.signIn()
  }
  
  @IBAction func privacyAct(_ sender: Any) {
    guard let webView = storyboard?.instantiateViewController(identifier: "WebViewController") as? WebViewController else { return }
    self.present(webView, animated: true, completion: nil)
    
  }
  
  @IBAction func fbLoginAct(_ sender: Any) {
    UserManager.shared.fbLogin(controller: self) { [weak self] result in
      guard let strongSelf = self else { return }
      switch result {
      case .success(let accessToken):
        
        strongSelf.loginDBwithFB(accessToken: accessToken, viewController: strongSelf)

      case .failure(let error):
        
        LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
      }
    }
  }
  
  func loginDBwithFB(accessToken: String, viewController: UIViewController) {
    UserManager.shared.loginFireBaseWithFB(accesstoken: accessToken, controller: viewController) { [weak self] result in
      guard let strongSelf = self else { return }
      strongSelf.preventTap()
      switch result {
      case .success:
        strongSelf.getFBprofile(controller: strongSelf)
        
      case .failure(let error):
        LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
      }
    }
  }
  
  func getFBprofile(controller: UIViewController) {
    UserManager.shared.loadFBProfile(controller: controller) { [ weak self] result in
      guard let strongSelf = self else { return }
      strongSelf.preventTap()
      switch result {
      case .success:
        
        UserManager.shared.isTourist = false
        guard let uid = Auth.auth().currentUser?.uid else { return }
        UserDefaults.standard.set(uid, forKey: "uid")
        strongSelf.readData(uid: uid, isApple: false, isFB: true)
        
      case .failure(let error):
        
        LKProgressHUD.dismiss()
        LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
      }
    }
  }
  
  func readData(uid: String, isApple: Bool, isFB: Bool) {
    UserManager.shared.readData(uid: uid) { [weak self] result in
      guard let strongSelf = self else { return }
      switch result {
      case .success:
        
        UserDefaults.standard.set(true, forKey: "login")
        LKProgressHUD.dismiss()
        strongSelf.gotoMap(viewController: strongSelf)
        
      case .failure(let error):
        
        if error.localizedDescription == "The operation couldn’t be completed. (Errand.RegiError error 3.)" {
          strongSelf.setUpDataBase(isApple: isApple, isFB: isFB)
        } else {
          print("error")
        }
      }
    }
  }
  
  func setUpDataBase(isApple: Bool, isFB: Bool) {
    createDataBase(isApple: isApple, isFB: isFB) { [weak self] result in
      guard let strongSelf = self else { return }
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
  }
  
  let appleButton: ASAuthorizationAppleIDButton = {
    let button = ASAuthorizationAppleIDButton()
    button.addTarget(self, action: #selector(startSignInWithAppleFlow), for: .touchUpInside)
    button.layer.cornerRadius = button.bounds.height / 2
    return button
  }()
  
  func setUpBtn() {
    fbLoginBtn.layer.cornerRadius = fbLoginBtn.bounds.height / 10
    googleLoginBtn.layer.cornerRadius = googleLoginBtn.bounds.height / 10
    visitorBtn.layer.cornerRadius = visitorBtn.bounds.height / 10
    GIDSignIn.sharedInstance()?.presentingViewController = self
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
    preventTap()
    UserManager.shared.isTourist = false
    guard let uid = Auth.auth().currentUser?.uid else { return }
    readData(uid: uid, isApple: false, isFB: false)
  }
  
  func createDataBase(isApple: Bool, isFB: Bool, completion: @escaping (Result<String, Error>) -> Void) {
    
    var photo = ""
    var userName = "使用者"
    let size = "?width=400&height=400"
    
    if isApple {  } else if isFB {
      guard let photoBack = UserManager.shared.FBData?.image,
           let name = UserManager.shared.FBData?.name else { return }

      photo = "\(photoBack)\(size)"
      userName = name
    } else {
      guard let userImage = Auth.auth().currentUser?.photoURL?.absoluteString else { return }
      photo = "\(userImage + size)"
      userName = "使用者"
    }
    
    guard let email = Auth.auth().currentUser?.email,
         let uid = Auth.auth().currentUser?.uid else { return }
    
    UserManager.shared.readData(uid: uid) {result in
      switch result {
      case .success:
        completion(.success("good"))
      case .failure(let error):
        
        if error.localizedDescription == "The operation couldn’t be completed. (Errand.RegiError error 3.)" {
          DataBaseManager.shared.createDataBase(classification: "Users", nickName: userName, email: email, photo: photo) { result in
            switch result {
            case .success:
              
              completion(.success("good"))
              
            case .failure:
              
              completion(.failure(RegiError.registFailed))
            }
          }
        } else { print(error.localizedDescription)}
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
        if length == 0 { return  }
        
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
        
        self.createDataBase(isApple: true, isFB: false) { [weak self] result in
          guard let strongSelf = self else { return }
          switch result {
            
          case .success(let success):
            
            UserManager.shared.isTourist = false
            UserManager.shared.updatefcmToken()
            LKProgressHUD.dismiss()
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
    print("Sign in with Apple errored: \(error)")
  }
  
  func gotoMap(viewController: UIViewController) {
    guard let mapVc  = UIStoryboard(name: "Content", bundle: nil).instantiateViewController(identifier: "tab") as? TabBarViewController else { return }
    self.view.window?.rootViewController = mapVc
  }
}

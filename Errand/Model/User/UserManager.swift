//
//  UserManager.swift
//  Errand
//
//  Created by Jim on 2020/1/15.
//  Copyright © 2020 Jim. All rights reserved.
//
import UIKit
import Foundation
import FBSDKLoginKit
import Firebase
import FirebaseAuth

class UserManager {
  
  static let shared = UserManager()
  
  let dbF = Firestore.firestore()
  
  var FBData: FbData?
  
  private init() { }
  
  func registAccount(account: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
    
    Auth.auth().createUser(withEmail: account, password: password) { (_, error) in
      
      if error != nil {
        
        completion(Result.failure(RegiError.registFailed))
      }
      
      completion(.success("ok"))
    }
  }
    
  func createDataBase(classification: String, gender: Int, nickName: String, email: String, completion: @escaping (Result<String, Error>) -> Void) {
    
    let friends: [String] = []
    
    let task: [String] = []
    
    let userId = Auth.auth().currentUser?.uid
    
    let info = AccountInfo(email: email, nickname: nickName, gender: gender, task: task, friends: friends)
    
    self.dbF.collection(classification).document(email).setData(info.toDict) { error in
      
      if error != nil {
        
        completion(Result.failure(RegiError.registFailed))
        
      } else {
        
        UserDefaults.standard.set(gender, forKey: "gender")
        
        UserDefaults.standard.set(nickName, forKey: "nickname")
        
        UserDefaults.standard.set(email, forKey: "email")
        
        UserDefaults.standard.set(true, forKey: "login")
        
        UserDefaults.standard.set(userId, forKey: "userid")
        
        completion(Result.success("Success"))
        
      }
    }
  }
  
  func fbLogin(controller: UIViewController, completion: @escaping (Result<String, Error>) -> Void) {
    
    let manager = LoginManager()
    
    manager.logIn(permissions: ["email"], from: controller) { (result, _) in
      
      guard let response = result else {
        
        completion(Result.failure(FbMessage.fbloginError))
        
        return }
      
      guard let accessToken = response.token?.tokenString else {
        
        completion(Result.failure(FbMessage.emptyToken))
        
        return
        
      }
      
      completion(Result.success(accessToken))
      
    }
  }
  
  func loadFBProfile(controller: UIViewController, completion: @escaping (Result<String, Error>) -> Void) {
    
    Profile.loadCurrentProfile { [weak self](profile, error) in
      
      if error != nil {
        
        completion(Result.failure(FireBaseMessage.fireBaseLoginError))
        
        return
        
      } else {
        
        guard let profile = profile,
          let profileName = profile.name,
          let profilePicture = profile.imageURL(forMode: .normal, size: CGSize(width: 300, height: 300)) else {
            
            completion(Result.failure(FireBaseMessage.fireBaseLoginError))
            
            return }
        
        self?.FBData = FbData(name: profileName, image: profilePicture)
        
        completion(Result.success("Success"))
        
      }
    }
  }
  
  func loginFireBaseWithFB(accesstoken: String, controller: UIViewController, completion: @escaping (Result<String, Error>) -> Void) {
    
    let credit = FacebookAuthProvider.credential(withAccessToken: accesstoken)
    
    Auth.auth().signIn(with: credit) { (user, error) in
      
      if error != nil {
        
        completion(Result.failure(FireBaseMessage.fireBaseLoginError))
        
      } else {
        
        guard let _ = user else { return }
        
        completion(Result.success("Success"))
        
      }
    }
  }
}

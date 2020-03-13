//
//  UserManagerTests.swift
//  UserManagerTests
//
//  Created by Jim on 2020/3/9.
//  Copyright © 2020 Jim. All rights reserved.
//

import XCTest
import Firebase

@testable import Errand

class FakeFirebaseManager: FirebaseManager {
  
  override func fetchData(uid: String, completion: @escaping (Result<AccountInfo, Error>) -> Void) {
    completion(.success(AccountInfo(email: "", nickname: "", noJudgeCount: 0, task: [], minusStar: 0.0, photo: "", report: 0, blacklist: [], oppoBlacklist: [], onTask: false, fcmToken: "", status: 0, about: "", taskCount: 0, totalStar: 0.0, uid: "")))
  }
  
}

class UserManagerTests: XCTestCase {
  
  var sut: UserManager!
  var fake: FakeFirebaseManager!
  
    override func setUp() {
      super.setUp()
      sut = UserManager(firebaseManager: FakeFirebaseManager())
      
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
      
      sut = nil
      super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
  
  func test_readUserInfo_SuccessFetchUserInfo() {
    
    let uid = UUID().uuidString
    
    var isFetch = false
    
    let promise = expectation(description: "Correct uid and fetch correct userInfo")
    
    sut.readUserInfo(uid: uid, isSelf: false) { result in
      
      switch result {
        
      case .success:
        
        isFetch = true
        promise.fulfill()
      
      case .failure:
        
        isFetch = false
        
      }
    }
    
    wait(for: [promise], timeout: 5)
    XCTAssert(isFetch, "match the expectation")
    
  }

}

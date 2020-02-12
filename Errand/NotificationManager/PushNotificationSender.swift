//
//  PushNotificationSender.swift
//  Errand
//
//  Created by Jim on 2020/2/5.
//  Copyright © 2020 Jim. All rights reserved.
//

import Foundation
import UIKit

class PushNotificationSender {
  func sendPushNotification(to token: String, body: String) {
    
    guard let requester = UserManager.shared.currentUserInfo?.nickname else { return } 
        let urlString = "https://fcm.googleapis.com/fcm/send"
        let url = NSURL(string: urlString)!
        let paramString: [String: Any] = ["to": token,
                  "notification": ["title": "任務通知", "body": body],
                                        "data": ["user": "test_id"]
        ]
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: paramString, options: [.prettyPrinted])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=AAAAY-GQkaQ:APA91bGnEGseSWOnzukgSP4M6AfWadP3fUqPYiMCHHRkK28WoRBkeqhOmfkH1tDRetPZ58OGV2KzTG3tkNwG3IY9kQmUgVtPMuat7qV47uoZlKS7i5QAFB8VDgS24u6KHBnzNx_rS5_y", forHTTPHeaderField: "Authorization")
        let task =  URLSession.shared.dataTask(with: request as URLRequest) {(data, _, _) in
            do {
                if let jsonData = data {
                    if let jsonDataDict  = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
                        NSLog("Received data:\n\(jsonDataDict))")
                    }
                }
            } catch let err as NSError {
                print(err.debugDescription)
            }
        }
        task.resume()
    }
}

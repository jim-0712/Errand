//
//  UserDataItem.swift
//  Errand
//
//  Created by Jim on 2020/1/21.
//  Copyright © 2020 Jim. All rights reserved.
//

import Foundation

enum FireBaseUpdateError: Error {
  
  case updateError
}

enum FireBaseDownloadError: Error {
  
  case downloadError
}

enum MissionError: Error {
  
  case completeMission
}

enum CellType {
  case detail
  case rate
  case about
  case logout
  case miniPhoto
  case startMission
  case normal
  case purpose
  case blacklist
}

struct CellContent {
  var type: CellType
  var title: String
}

//
//  Background.swift
//  Errand
//
//  Created by Jim on 2020/1/20.
//  Copyright © 2020 Jim. All rights reserved.
//

import Foundation
import UIKit

class BackgroundManager {
  
  static let shared = BackgroundManager()
  
  func setUpView(view: UIView) -> CAGradientLayer {
      
      let topColor = UIColor(red: 0xff/255, green: 0xff/255, blue: 0xff/255, alpha: 1)
    
      let buttomColor = UIColor(red: 0x87/255, green: 0xce/255, blue: 0xeb/255, alpha: 1)
    
      let gradientColors = [topColor.cgColor, buttomColor.cgColor]
       
      //定义每种颜色所在的位置
      let gradientLocations: [NSNumber] = [0.0, 1.0]
       
      //创建CAGradientLayer对象并设置参数
      let gradientLayer = CAGradientLayer()
    
      gradientLayer.colors = gradientColors
    
      gradientLayer.locations = gradientLocations
       
      gradientLayer.frame = view.frame
    
      return gradientLayer
    }
}

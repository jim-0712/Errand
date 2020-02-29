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
      
    let topColor = UIColor.white
    
    let buttomColor = UIColor.Y1
    
    let gradientColors = [topColor.cgColor, buttomColor?.cgColor]
       
      //定义每种颜色所在的位置
      let gradientLocations: [NSNumber] = [0.0, 1.0]

      //创建CAGradientLayer对象并设置参数
      let gradientLayer = CAGradientLayer()
    
    gradientLayer.colors = gradientColors as [Any]
    
      gradientLayer.locations = gradientLocations
       
      gradientLayer.frame = view.frame
    
      return gradientLayer
    }
}

//
//  CustomTransitioningManager.swift
//  Errand
//
//  Created by Jim on 2020/3/6.
//  Copyright © 2020 Jim. All rights reserved.
//
import UIKit
import Foundation

class CircularTransition: NSObject {
    var circle: UIView = UIView()
    var startingPoint = CGPoint.zero
    var circleColor: UIColor?
    var duration = 0.6
    enum PresentMode: Int {
        case present, dismiss
    }
    var transitionMode: PresentMode = .present
}

extension CircularTransition: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        if transitionMode == .present {
          guard let toVC = transitionContext.viewController(forKey: .to) else {
                    transitionContext.completeTransition(false)
                    return
            }
            let viewCenter = toVC.view.center
            let viewSize = toVC.view.frame.size
            circle.frame = frameForCircle(withViewCenter: viewCenter, size: viewSize, startPoint: startingPoint)
            circle.layer.cornerRadius = circle.frame.size.width / 2
            circle.center = startingPoint
            circle.backgroundColor = circleColor
            circle.alpha = 1
            circle.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
            containerView.addSubview(circle)
            toVC.view.center = startingPoint
            toVC.view.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
            toVC.view.alpha = 0
            containerView.addSubview(toVC.view)
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
                self.circle.transform = CGAffineTransform.identity
                toVC.view.transform = CGAffineTransform.identity
                toVC.view.alpha = 1
                toVC.view.center = viewCenter
            }, completion: { success in
                transitionContext.completeTransition(success)
            })
        } else {
            guard let returningVC = transitionContext.viewController(forKey: .from) else {
                transitionContext.completeTransition(false)
                return
            }
            let viewCenter = returningVC.view.center
            circle.alpha = 0
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
                returningVC.view.center = CGPoint(x: returningVC.view.center.x, y: returningVC.view.center.y * 3)
            }, completion: { (success: Bool) in
                returningVC.view.center = viewCenter
                returningVC.view.removeFromSuperview()
                self.circle.removeFromSuperview()
                transitionContext.completeTransition(success)
            })
        }
    }
  
    func frameForCircle (withViewCenter viewCenter: CGPoint, size viewSize: CGSize, startPoint: CGPoint) -> CGRect {
        let xLength = fmax(startPoint.x, viewSize.width - startPoint.x)
        let yLength = fmax(startPoint.y, viewSize.height - startPoint.y)
        let offsetVector = sqrt(xLength * xLength + yLength * yLength) * 2
        let size = CGSize(width: offsetVector, height: offsetVector)
        return CGRect(origin: CGPoint.zero, size: size)
    }
}

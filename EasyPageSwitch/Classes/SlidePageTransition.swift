//
//  SlidePageTransition.swift
//  EasyPageSwitch
//
//  Created by danqin chu on 2019/6/21.
//

import Foundation

public class SlidePageTransition: UIPercentDrivenInteractiveTransition, EasyPageTransition {
    
    public enum SlideDirection {
        case null
        case up
        case left
        case down
        case right
    }
    
    public enum InteractionType {
        case null
        case panEdge
        case panPage
    }
    
    public let presentAnimation = SlideInAnimation()
    
    public lazy var dismissAnimation = SlideOutAnimation()
    
    private var interacting = false
    
    private var interactionComplete = false
    
    public var interactionType: InteractionType = .panEdge
    
    public var interactionDirection: SlideDirection?
    
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return presentAnimation
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return dismissAnimation
    }
    
    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if interactionType == .null {
            return nil
        }
        return interacting ? self : nil
    }
}


// MARK: - Slide-in Animation And Slide-out Animation
extension SlidePageTransition {
    
    public class SlideAnimation: NSObject, UIViewControllerAnimatedTransitioning {
        
        static fileprivate let shadowViewTag = 10241024
        
        public var direction: SlideDirection = .null
        
        public var duration = 0.3
        
        public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
            return duration
        }
        
        public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {}
        
    }
    
    public class SlideInAnimation: SlideAnimation {
        
        override init() {
            super.init()
            direction = .left
        }
        
        override public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
            guard let toVC = transitionContext.viewController(forKey: .to) else {
                return
            }
            
            let bounds = transitionContext.containerView.bounds
            
            var offsetX: CGFloat
            var offsetY: CGFloat
            switch direction {
            case .up:
                offsetX = 0.0
                offsetY = bounds.size.height
            case .left:
                offsetX = bounds.size.width
                offsetY = 0.0
            case .down:
                offsetX = 0.0
                offsetY = -bounds.size.height
            case .right:
                offsetX = -bounds.size.width
                offsetY = 0.0
            default:
                offsetX = 0.0
                offsetY = 0.0
            }
            
            let shadowView = UIView(frame: bounds)
            shadowView.backgroundColor = UIColor.black
            shadowView.tag = SlideAnimation.shadowViewTag
            shadowView.alpha = 0.0
            transitionContext.containerView.addSubview(shadowView)
            
            let endFrame = transitionContext.finalFrame(for: toVC)
            let startFrame = endFrame.offsetBy(dx: offsetX, dy: offsetY)
            toVC.view.frame = startFrame
            transitionContext.containerView.addSubview(toVC.view)
            
            UIView.animate(withDuration: duration, delay: 0.0, options: .curveEaseInOut, animations: {
                toVC.view.frame = endFrame
                if let fromView = transitionContext.view(forKey: .from) {
                    fromView.frame = endFrame.offsetBy(dx: -offsetX / 4, dy: -offsetY / 4)
                }
                shadowView.alpha = 0.1
            }) { (finished: Bool) in
                transitionContext.completeTransition(true)
            }
        }
    }
    
    public class SlideOutAnimation: SlideAnimation {
        
        override init() {
            super.init()
            direction = .right
        }
        
        override public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
            guard let toVC = transitionContext.viewController(forKey: .to) else {
                return
            }
            guard let fromVC = transitionContext.viewController(forKey: .from) else {
                return
            }
            
            let bounds = transitionContext.containerView.bounds
            
            var offsetX: CGFloat
            var offsetY: CGFloat
            switch direction {
            case .up:
                offsetX = 0.0
                offsetY = -bounds.size.height
            case .left:
                offsetX = -bounds.size.width
                offsetY = 0.0
            case .down:
                offsetX = 0.0
                offsetY = bounds.size.height
            case .right:
                offsetX = bounds.size.width
                offsetY = 0.0
            default:
                offsetX = 0.0
                offsetY = 0.0
            }
            
            let startFrame = transitionContext.initialFrame(for: fromVC)
            let endFrame = startFrame.offsetBy(dx: offsetX, dy: offsetY)
            
            transitionContext.containerView.addSubview(toVC.view)
            transitionContext.containerView.sendSubviewToBack(toVC.view)
            
            UIView.animate(withDuration: duration, delay: 0.0, options: .curveEaseInOut, animations: {
                fromVC.view.frame = endFrame
                if let toView = transitionContext.view(forKey: .to) {
                    toView.frame = bounds
                }
                if let shadowView = transitionContext.containerView.viewWithTag(SlideAnimation.shadowViewTag) {
                    shadowView.alpha = 0.0
                }
            }) { (finished: Bool) in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
    }
}


// MARK: - Pan Guesture
extension SlidePageTransition {
    private func _interactionDirection() -> SlideDirection {
        return interactionDirection ?? dismissAnimation.direction
    }
    
    public func didFinishPresenting(_ viewController: UIViewController) {
        switch interactionType {
        case .panEdge:
            let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
            let direction = _interactionDirection()
            switch direction {
            case .null:
                // not work?
                gesture.edges = .all
            case .up:
                gesture.edges = .bottom
            case .left:
                gesture.edges = .right
            case .down:
                gesture.edges = .top
            case .right:
                gesture.edges = .left
            }
            viewController.view.addGestureRecognizer(gesture)
        case .panPage:
            let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
            viewController.view.addGestureRecognizer(gesture)
        default:
            break
        }
    }
    
    override open var completionSpeed: CGFloat {
        get {
            return 1 - percentComplete
        }
        set {
            super.completionSpeed = newValue
        }
    }
    
    @objc func handleGesture(_ gr: UIPanGestureRecognizer) {
        switch gr.state {
        case .began:
            interacting = true
            EasyPageSwitch.hostViewController(for: gr.view)?.dismiss(animated: true, completion: nil)
        case .changed:
            if let view = gr.view {
                var percent: CGFloat = 0.0
                let translation = gr.translation(in: view.superview)
                switch self._interactionDirection() {
                case .up:
                    percent = -translation.y / view.bounds.size.height
                case .down:
                    percent = translation.y / view.bounds.size.height
                case .left:
                    percent = -translation.x / view.bounds.size.width
                case .right:
                    percent = translation.x / view.bounds.size.width
                default:
                    percent = 1.0
                }
                if (interactionType == .panEdge) {
                    percent = abs(percent)
                }
                percent = max(percent, 0.0)
                percent = min(percent, 1.0)
                interactionComplete = percent > 0.5
                self.update(percent)
            }
        case .cancelled:
            interacting = false
            self.cancel()
        case .ended:
            interacting = false
            if interactionComplete {
                self.finish()
            } else {
                self.cancel()
            }
        default:
            break
        }
    }
    
}

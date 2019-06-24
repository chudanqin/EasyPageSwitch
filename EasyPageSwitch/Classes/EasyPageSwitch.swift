//
//  EasyPageSwitch.swift
//  EasyPageSwitch
//
//  Created by danqin chu on 2019/6/21.
//

import Foundation

//public struct EasyPageSwitchWrapper<Base> {
//    public let base: Base
//    public init(_ base: Base) {
//        self.base = base
//    }
//}
//
//public protocol EasyPageSwitchCompatible {
//}
//
//extension EasyPageSwitchCompatible {
//    public var eps: EasyPageSwitchWrapper<Self> {
//        return EasyPageSwitchWrapper(self)
//    }
//}
//
//extension UIWindow: EasyPageSwitchCompatible {
//}

private var kPageTransition: Void?

private func saveTransition(object: Any, transition: UIViewControllerTransitioningDelegate?) {
    objc_setAssociatedObject(object, &kPageTransition, transition, .OBJC_ASSOCIATION_RETAIN)
}

public protocol EasyPageSwitchable: UIViewControllerTransitioningDelegate {
    func didFinishPresenting(_ viewController: UIViewController)
//    func didFinishDismissing(_ viewController: UIViewController)
}

//public extension EasyPageSwitchWrapper where Base: UIWindow {
public class EasyPageSwitch {
    
    public static let current = EasyPageSwitch(windowClosure: UIApplication.shared.keyWindow)
    
    var windowClosure: (() -> UIWindow?)?
    weak var window: UIWindow?
    
    init(windowClosure: @escaping @autoclosure () -> UIWindow?) {
        self.windowClosure = windowClosure
    }
    
    init(_ window: UIWindow?) {
        self.window = window
    }
    
    public func rootViewController() -> UIViewController? {
        if windowClosure != nil, let win = windowClosure!() {
            return win.rootViewController
        }
        if let win = window {
            return win.rootViewController
        }
        return nil
    }

    public func topViewController() -> UIViewController? {
        guard let rootVC = self.rootViewController() else {
            return nil
        }
        var vc: UIViewController = rootVC
        while vc.presentedViewController != nil {
            vc = vc.presentedViewController!
        }
        return vc
    }
    
    public func show(_ viewController: UIViewController,
              transition: EasyPageSwitchable? = SlidePageTransition(),
                 completion: (() -> Void)? = nil) {
        guard let topVC = self.topViewController() else {
            return
        }
        if !topVC.isReady() {
            return
        }
        if let t = transition {
            saveTransition(object: viewController, transition: transition)
            viewController.transitioningDelegate = t
            topVC.present(viewController, animated: true, completion: {
                (t as! SlidePageTransition).didFinishPresenting(viewController)
                if let c = completion {
                    c()
                }
            })
        } else {
            topVC.present(viewController, animated: false, completion: completion)
        }
    }
    
    public func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let topVC = self.topViewController() else {
            return
        }
        guard let pvc = topVC.presentingViewController else {
            return
        }
        if pvc.isReady() {
            pvc.dismiss(animated: animated, completion: completion)
        }
    }
    
    public func slideIn(_ viewController: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        show(viewController, transition: animated ? SlidePageTransition() : nil, completion: completion)
    }
    
}

extension UIViewController {
    
    func isReady() -> Bool {
        return !(self.isBeingDismissed || self.isMovingFromParent || self.isBeingPresented || self.isMovingToParent)
    }
    
}

extension UIView {
    
    func hostViewController() -> UIViewController? {
        var n: UIResponder? = self
        repeat {
            n = n?.next
            if let vc = n as? UIViewController {
                return vc
            }
        } while n != nil
        return nil
    }
    
}

//
//  EasyPageSwitch.swift
//  EasyPageSwitch
//
//  Created by danqin chu on 2019/6/21.
//

import Foundation

public protocol EasyPageTransition: UIViewControllerTransitioningDelegate {
    func didFinishPresenting(_ viewController: UIViewController)
    //    func didFinishDismissing(_ viewController: UIViewController)
}

//public extension EasyPageSwitchWrapper where Base: UIWindow {
open class EasyPageSwitch {
    
    public struct PageOptions: OptionSet {
        public let rawValue: UInt
        
        public static let null = PageOptions(rawValue: 0x0)
        public static let withNavigationBar = PageOptions(rawValue: 0x1)
        public static let withNavigationBackButton = PageOptions(rawValue: 0x2)
        
        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }
    }
    
    public static let current = EasyPageSwitch(rootViewControllerClosure: UIApplication.shared.keyWindow?.rootViewController)
    
    public static var defaultNavigationBackButtonClosure: ((UIViewController) -> UIBarButtonItem?)? = { vc in
        return UIBarButtonItem(title: NSLocalizedString("Back", comment: "返回"), style: .plain, target: vc, action: #selector(UIViewController.eps_navigationBackButtonClicked(sender:)))
    }
    
    var rootViewControllerClosure: (() -> UIViewController?)?
    weak var rootViewController: UIViewController?
    
    init(rootViewControllerClosure: @escaping @autoclosure () -> UIViewController?) {
        self.rootViewControllerClosure = rootViewControllerClosure
    }
    
    init(_ rootViewController: UIViewController?) {
        self.rootViewController = rootViewController
    }
    
    public func rootPage() -> UIViewController? {
        if rootViewControllerClosure != nil, let page = rootViewControllerClosure!() {
            return page
        }
        return rootViewController
    }
    
    public func topPage() -> UIViewController? {
        guard let rootVC = self.rootPage() else {
            return nil
        }
        var vc: UIViewController = rootVC
        while vc.presentedViewController != nil {
            vc = vc.presentedViewController!
        }
        return vc
    }
    
    public func show(_ viewController: UIViewController,
                     options: PageOptions?,
                     transition: EasyPageTransition? = SlidePageTransition(),
                     completion: (() -> Void)? = nil) {
        guard let topVC = self.topPage() else {
            return
        }
        if !topVC.eps_isReady() {
            return
        }
        var vc: UIViewController = viewController
        if let _options = options {
            if _options.contains(.withNavigationBar) {
                vc = UINavigationController(rootViewController: viewController)
            }
            if (_options.contains(.withNavigationBackButton)) {
                viewController.navigationItem.leftBarButtonItem = viewController.eps_navigationBackButton()
            }
        }
        if let t = transition {
            objc_setPageTransition(object: vc, transition: transition)
            vc.transitioningDelegate = t
            topVC.present(vc, animated: true, completion: {
                t.didFinishPresenting(vc)
                if let c = completion {
                    c()
                }
            })
        } else {
            topVC.present(viewController, animated: false, completion: completion)
        }
    }
    
    public func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let topVC = self.topPage() else {
            return
        }
        topVC.eps_dismiss(animated: true, completion: completion)
    }
    
    public func slideIn(_ viewController: UIViewController,
                        options: PageOptions? = [PageOptions.withNavigationBar, PageOptions.withNavigationBackButton],
                        animated: Bool = true,
                        completion: (() -> Void)? = nil) {
        show(viewController, options: options, transition: animated ? SlidePageTransition() : nil, completion: completion)
    }
    
    static public func hostViewController(for view: UIView?) -> UIViewController? {
        var n: UIResponder? = view
        repeat {
            n = n?.next
            if let vc = n as? UIViewController {
                return vc
            }
        } while n != nil
        return nil
    }
}

// MARK: Override If Necessary
@objc extension UIViewController {
    open func eps_navigationBackButton() -> UIBarButtonItem? {
        if let c = EasyPageSwitch.defaultNavigationBackButtonClosure {
            return c(self)
        }
        return nil
    }
    
    open func eps_navigationBackButtonClicked(sender: AnyObject) {
        eps_dismiss(animated: true)
    }
    
    public func eps_isReady() -> Bool {
        return !(self.isBeingDismissed || self.isMovingFromParent || self.isBeingPresented || self.isMovingToParent)
    }
    
    @discardableResult public func eps_dismiss(animated: Bool = true, completion: (() -> ())? = nil) -> Bool {
        if let pvc = self.presentingViewController {
            if eps_isReady() && pvc.eps_isReady() {
                pvc.dismiss(animated: animated, completion: completion)
                return true
            }
        }
        return false
    }
    
    @discardableResult public func eps_popOrDismiss(animated: Bool = true, completion: (() -> ())? = nil) -> Bool {
        if let nc = self.navigationController {
            let children = nc.viewControllers
            if children.count > 1 && children.last == self && eps_isReady() && nc.eps_isReady() {
                nc.popViewController(animated: animated)
                return true
            }
        }
        return eps_dismiss(animated: animated, completion: completion)
    }
}

extension UINavigationController {
    
    @discardableResult override public func eps_popOrDismiss(animated: Bool = true, completion: (() -> ())? = nil) -> Bool {
        let children = self.viewControllers
        if children.count > 1 && eps_isReady() && children.last!.eps_isReady(){
            self.popViewController(animated: animated)
            return true
        }
        return eps_dismiss(animated: animated, completion: completion)
    }
    
}

private var kPageTransition: Void?

private func objc_setPageTransition(object: Any, transition: EasyPageTransition?) {
    objc_setAssociatedObject(object, &kPageTransition, transition, .OBJC_ASSOCIATION_RETAIN)
}

private func objc_getPageTransition(object: Any) -> EasyPageTransition? {
    return objc_getAssociatedObject(object, &kPageTransition) as? EasyPageTransition
}

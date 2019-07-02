//
//  ViewController.swift
//  EasyPageSwitch
//
//  Created by chudanqin on 06/21/2019.
//  Copyright (c) 2019 chudanqin. All rights reserved.
//

import UIKit
import EasyPageSwitch

private var counter = 0

class ViewController: UIViewController {
    
    var i: Int?

    @IBAction func presnt(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Test")
//        self.view.window?.eps.slideIn(vc)
        EasyPageSwitch.defaultNavigationBackButtonClosure = { vc in
            return UIBarButtonItem(title: "youmeiyou", style: .plain, target: vc, action: #selector(UIViewController.eps_navigationBackButtonClicked(sender:)))
        }
        let t = SlidePageTransition()
        t.presentAnimation.direction = .left
        t.dismissAnimation.direction = .right
        t.interactionType = .panPage
        //EasyPageSwitch.current.show(vc, options: [.withNavigationBar, .withNavigationBackButton], transition: t)
        EasyPageSwitch.current.slideIn(vc)
    }
    
//    override public func eps_navigationBackButton() -> UIBarButtonItem? {
//
//    }
    
    
    @IBAction func dismiss(_ sender: Any) {
        EasyPageSwitch.current.dismiss()
    }
    
    override func viewDidLoad() {
        counter += 1
        i = counter
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var description: String {
        return String(i == nil ? -1 : i!)
    }

}


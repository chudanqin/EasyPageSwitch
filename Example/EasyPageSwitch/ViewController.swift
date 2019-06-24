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
        let t = SlidePageTransition()
        t.presentAnimation.direction = .down
        t.dismissAnimation.direction = .up
        EasyPageSwitch.current.show(vc, transition: t)
    }
    
    
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


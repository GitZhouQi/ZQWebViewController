//
//  ViewController.swift
//  ZQWebView
//
//  Created by zhouqi on 2019/5/15.
//  Copyright © 2019 zhouqi. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let button = UIButton(frame: CGRect(x: 100, y: 100, width: 100, height: 100))
        button.addTarget(self, action: #selector(openWebView), for: .touchUpInside)
        button.setTitle("跳转网页", for: .normal)
        view.addSubview(button)
    }
    
    @objc func openWebView() {
        let webVC = ZQWebViewController()
        webVC.url = "https://www.baidu.com"
        self.navigationController?.pushViewController(webVC, animated: true)
    }
}


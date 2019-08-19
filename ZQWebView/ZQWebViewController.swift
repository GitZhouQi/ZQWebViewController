//
//  ZQWebViewController.swift
//  ZQWebView
//
//  Created by zhouqi on 2019/5/15.
//  Copyright © 2019 zhouqi. All rights reserved.
//

import UIKit
import WebKit


public protocol ZQWebViewDelegate: class {
    func didStartLoading()
    func didFinishLoading(success: Bool)
}

public class ZQWebViewController: UIViewController {

    var delegate: ZQWebViewDelegate? = nil
    var url: String = ""
    var storedStatusColor: UIBarStyle?
    var buttonColor: UIColor? = nil
    var titleColor: UIColor? = nil
    var closing: Bool! = false
    
    internal lazy var webView: WKWebView = {
        var webView = WKWebView(frame: UIScreen.main.bounds)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        return webView;
    }()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        view.addSubview(webView)
        let request = URLRequest(url: URL(string: url)!)
        webView.load(request)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.addSubview(progressView)
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let items = self.navigationController?.toolbarItems, items.count > 0 {
            self.navigationController?.setToolbarHidden(false, animated: false)
        }
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        self.navigationController?.setToolbarHidden(true, animated: true)
    }
    
    lazy var backBarButtonItem: UIBarButtonItem =  {
        var tempBackBarButtonItem = UIBarButtonItem(image: UIImage(named: "webViewBack"),
                                                    style: .plain,
                                                    target: self,
                                                    action: #selector(goBackTapped(_:)))
        tempBackBarButtonItem.width = 18.0
        tempBackBarButtonItem.tintColor = self.buttonColor
        return tempBackBarButtonItem
    }()
    
    lazy var forwardBarButtonItem: UIBarButtonItem =  {
        var tempForwardBarButtonItem = UIBarButtonItem(image: UIImage(named: "webViewForward"),
                                                       style: .plain,
                                                       target: self,
                                                       action: #selector(goForwardTapped(_:)))
        tempForwardBarButtonItem.width = 18.0
        tempForwardBarButtonItem.tintColor = self.buttonColor
        return tempForwardBarButtonItem
    }()
    
    lazy var progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        let progressViewY = self.navigationController?.navigationBar.bounds.size.height ?? 0
        progressView.frame = CGRect(x: 0, y: progressViewY+20, width: UIScreen.main.bounds.size.width, height: 3)
        progressView.trackTintColor = UIColor.clear
        progressView.progressTintColor = UIColor.blue
        return progressView
    }()
    
    func initWebView() {
        
    }
    
    @objc func goBackTapped(_ sender: UIBarButtonItem) {
        webView.goBack()
        updateToolbarItems()
    }
    
    @objc func goForwardTapped(_ sender: UIBarButtonItem) {
        webView.goForward()
        updateToolbarItems()
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            progressView.alpha = 1.0
            print(Float(webView.estimatedProgress))
            let animated = Float(webView.estimatedProgress) > progressView.progress;
            progressView .setProgress(Float(webView.estimatedProgress), animated: animated)
            self.progressView.setProgress(Float(webView.estimatedProgress), animated: true)
            if Float(webView.estimatedProgress) >= 1.0 {
                updateToolbarItems()
                UIView.animate(withDuration: 1, delay:0.01,options:UIView.AnimationOptions.curveEaseOut, animations:{()-> Void in
                    self.progressView.alpha = 0.0
                },completion:{(finished:Bool) -> Void in
                    self.progressView.setProgress(0.0, animated: false)
                })
            }
        }
    }
    
    func updateToolbarItems() {
        backBarButtonItem.isEnabled = webView.canGoBack
        forwardBarButtonItem.isEnabled = webView.canGoForward
        if !backBarButtonItem.isEnabled, !forwardBarButtonItem.isEnabled {
            self.navigationController?.setToolbarHidden(true, animated: true)
            return
        }
        self.navigationController?.setToolbarHidden(false, animated: true)
        let fixedSpace: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.fixedSpace, target: nil, action: nil)
        let flexibleSpace: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        fixedSpace.width = 50
        let items: NSArray =  [flexibleSpace, backBarButtonItem, fixedSpace, forwardBarButtonItem, flexibleSpace]
        
        if let navigationController = navigationController {
            if presentingViewController == nil {
                navigationController.toolbar.barTintColor = navigationController.navigationBar.barTintColor
            } else {
                navigationController.toolbar.barStyle = navigationController.navigationBar.barStyle
            }
            navigationController.toolbar.tintColor = navigationController.navigationBar.tintColor
            toolbarItems = items as? [UIBarButtonItem]
        }
    }
    
    deinit {
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
    }
}

extension ZQWebViewController: WKUIDelegate {
    
}

extension ZQWebViewController: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.delegate?.didStartLoading()
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        updateToolbarItems()
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.delegate?.didFinishLoading(success: true)
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        webView.evaluateJavaScript("document.title", completionHandler: {(response, error) in
            self.title = response as? String
        })
        updateToolbarItems()
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.delegate?.didFinishLoading(success: false)
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        updateToolbarItems()
    }
    
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        updateToolbarItems()
        
        if let reqUrl = navigationAction.request.url?.absoluteString {
            if reqUrl.hasPrefix("alipays://") || reqUrl.hasPrefix("alipay://") {
                let bSucc = UIApplication.shared.openURL(navigationAction.request.url!)
                if !bSucc {
                    let alertController = UIAlertController(title: "提示", message: "未检测到支付宝客户端，请安装后重试。", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "确定", style: .cancel, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                    decisionHandler(.cancel)
                } else {
                    decisionHandler(.allow)
                }
                return
            }
            if reqUrl.contains("weixin://wap/pay?") {
                let bSucc = UIApplication.shared.openURL(navigationAction.request.url!)
                if !bSucc {
                    let alertController = UIAlertController(title: "提示", message: "未检测到微信客户端，请安装后重试。", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "确定", style: .cancel, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                    decisionHandler(.cancel)
                } else {
                    decisionHandler(.allow)
                }
                return
            }
            let wxRedirectURL = "xdx.m.baidu.com://"//微信后台注册的回调地址
            if reqUrl.hasPrefix("https://wx.tenpay.com/cgi-bin/mmpayweb-bin/checkmweb"), !reqUrl.hasSuffix("redirect_url=\(wxRedirectURL)") {
                decisionHandler(.cancel)
                if !reqUrl.contains("redirect_url") {
                    let newURLStr = reqUrl+"&redirect_url=\(wxRedirectURL)"
                    let newRequest = NSMutableURLRequest(url: URL(string: newURLStr)!)
                    newRequest.allHTTPHeaderFields = navigationAction.request.allHTTPHeaderFields
                    newRequest.url = URL(string: newURLStr)
                    webView.load(newRequest as URLRequest)
                }
                return
            }
        }
        
        if let urlStr = navigationAction.request.url?.absoluteString, urlStr.hasPrefix("https://itunes.apple.com") {
            decisionHandler(.cancel)
            if let u = URL(string: urlStr) {
                let alert = UIAlertController(title: nil, message: "即将离开APP\r\n打开\"App Store\"", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "允许", style: .destructive, handler: { (action) in
                    UIApplication.shared.openURL(u)
                }))
                present(alert, animated: true, completion: nil)
            }
            return
        }
    
        let elements = navigationAction.request.url!.absoluteString.components(separatedBy: ":")
        
        switch elements[0] {
        case "tel":
            openCustomApp(urlScheme: "telprompt://", additional_info: elements[1])
            decisionHandler(.cancel)
            
        case "sms":
            openCustomApp(urlScheme: "sms://", additional_info: elements[1])
            decisionHandler(.cancel)
            
        case "mailto":
            openCustomApp(urlScheme: "mailto://", additional_info: elements[1])
            decisionHandler(.cancel)
            
        default:
            break
        }
        
        decisionHandler(.allow)
        
    }
    
    func openCustomApp(urlScheme: String, additional_info:String){
        if let requestUrl: URL = URL(string:"\(urlScheme)"+"\(additional_info)") {
            let application:UIApplication = UIApplication.shared
            if application.canOpenURL(requestUrl) {
                application.openURL(requestUrl)
            }
        }
    }
}

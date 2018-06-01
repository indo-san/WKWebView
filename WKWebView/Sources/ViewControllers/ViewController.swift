//
//  ViewController.swift
//  WKWebView
//
//  Created by 林　翼 on 2017/10/11.
//  Copyright © 2017年 Tsubasa Hayashi. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController {

    private var previousY: CGFloat = 0
    
    
    @IBOutlet weak var topbarTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottombarBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var webViewContainer: UIView!
    @IBOutlet private weak var textField: UITextField!
    @IBOutlet private weak var indicatorView: UIActivityIndicatorView! {
        didSet {
            indicatorView.hidesWhenStopped = true
        }
    }
    
    @IBOutlet private weak var bottomLabel: UILabel!

    private var webView: WKWebView! {
        didSet {
            webView.uiDelegate = self
            webView.navigationDelegate = self
            webView.allowsBackForwardNavigationGestures = true
            webView.translatesAutoresizingMaskIntoConstraints = false
            webView.scrollView.delegate = self
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        webView.load(URLRequest(url: URL(string: "https://github.com/")!))
    }
    
    @IBAction func onReloadButton(_ sender: UIButton) {
        if webView.isLoading {
            webView.stopLoading()
        }
        webView.reload()
    }
    
    @IBAction func onTrashButton(_ sender: UIButton) {
        let ac = UIAlertController(title: "Delete All Website Data", message: "DiskCache\nOfflineWebApplicationCache\nMemoryCache\nLocalStorage\nCookies\nSessionStorage\nIndexedDBDatabases\nWebSQLDatabases", preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default) { [weak self] (action) in
            self?.removeAllWKWebsiteData()
        }
        let cancel = UIAlertAction(title: "cancel", style: .cancel) { (action) in }
        ac.addAction(ok)
        ac.addAction(cancel)
        self.present(ac, animated: true, completion: nil)
    }
    
    
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        self.webViewContainer.addSubview(webView)
        self.webViewContainer.addConstraints([
            NSLayoutConstraint(item: webView, attribute: .top, relatedBy: .equal, toItem: self.webViewContainer, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: webView, attribute: .left, relatedBy: .equal, toItem: self.webViewContainer, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: webView, attribute: .right, relatedBy: .equal, toItem: self.webViewContainer, attribute: .right, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: webView, attribute: .bottom, relatedBy: .equal, toItem: self.webViewContainer, attribute: .bottom, multiplier: 1, constant: 0)
            ])
    }
    
    fileprivate func removeAllWKWebsiteData() {
        let websiteDataTypes = Set([
            WKWebsiteDataTypeDiskCache,
            WKWebsiteDataTypeOfflineWebApplicationCache,
            WKWebsiteDataTypeMemoryCache,
            WKWebsiteDataTypeLocalStorage,
            WKWebsiteDataTypeCookies,
            WKWebsiteDataTypeSessionStorage,
            WKWebsiteDataTypeIndexedDBDatabases,
            WKWebsiteDataTypeWebSQLDatabases
            ])
        
        WKWebsiteDataStore
            .default()
            .removeData(
                ofTypes: websiteDataTypes,
                modifiedSince: Date(timeIntervalSince1970: 0),
                completionHandler: {}
        )
    }
}

// MARK: WebViewDelegate
extension ViewController: WKUIDelegate, WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard let url = navigationAction.request.url else {
            return nil
        }
        
        guard let targetFrame = navigationAction.targetFrame, targetFrame.isMainFrame else {
            webView.load(URLRequest(url: url))
            return nil
        }
        return nil
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        Benchmarks.shared.start(key: webView.url?.absoluteString ?? "")
        indicatorView.startAnimating()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let time = Benchmarks.shared.finish(key: webView.url?.absoluteString ?? "")
        bottomLabel.text = time
        textField.text = webView.url?.absoluteString ?? ""
        indicatorView.stopAnimating()
        textField.resignFirstResponder()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        indicatorView.stopAnimating()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print(error)
    }
}


// MARK: UITextFieldDelegate
extension ViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text, !text.isEmpty else {
            let ac = UIAlertController.makeSimpleAlert("TextField is empty", message: nil, okTitle: "OK", okAction: nil, cancelTitle: nil, cancelAction: nil)
            self.present(ac, animated: true, completion: nil)
            return true
        }
        
        guard let url = URL(string: text), UIApplication.shared.canOpenURL(url) else {
            let ac = UIAlertController.makeSimpleAlert("Text is not URL", message: nil, okTitle: "OK", okAction: nil, cancelTitle: nil, cancelAction: nil)
            self.present(ac, animated: true, completion: nil)
            return true
        }
        
        webView.load(URLRequest(url: url))
        textField.resignFirstResponder()
        return true
    }
    
}


extension ViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print(scrollView.contentOffset.y)
        let dy = scrollView.contentOffset.y - previousY
        guard !scrollView.isBouncingY else { return }
        guard !scrollView.isAtTop else { return }

        guard dy != 0 else { return }
        if dy > 0 {
            let topConstraint = topbarTopConstraint.constant - abs(dy)
            topbarTopConstraint.constant = max(topConstraint, UIConstant.topbarTopConstraintMin)
            
            let bottomConstraint = bottombarBottomConstraint.constant - abs(dy)
            bottombarBottomConstraint.constant = max(bottomConstraint, UIConstant.bottombarTopConstraintMin)
        } else {
            let topConstraint = topbarTopConstraint.constant + abs(dy)
            topbarTopConstraint.constant = min(topConstraint, UIConstant.topbarTopConstraintMax)
            
            let bottomConstraint = bottombarBottomConstraint.constant + abs(dy)
            bottombarBottomConstraint.constant = min(bottomConstraint, UIConstant.bottombarTopConstraintMax)
        }
        
        previousY = scrollView.contentOffset.y
    }
}

extension UIScrollView {
    var isAtTop: Bool {
        return contentOffset.y <= 0
    }

    var isBouncingY: Bool {
        let contentTop = contentSize.height - frame.size.height
        return contentOffset.y >= contentTop
    }
}


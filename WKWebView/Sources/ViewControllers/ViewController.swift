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
    
    private var previousPointY = CGFloat()
    
    private var recommendationView: RecommendationView? = nil
    private var recommendationViewHeight: CGFloat = 500
    private var recommendationViewOffset: CGFloat = 20

    private var bottomInset: CGFloat = 0 {
        didSet {
            bottomInset = max(bottomInset, 0)
        }
    }
    
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
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        webView.load(URLRequest(url: URL(string: "https://news.yahoo.co.jp/pickup/6282592")!))
    }
    
    @IBAction func onReloadButton(_ sender: UIBarButtonItem) {
        if webView.isLoading {
            webView.stopLoading()
        }
        webView.reload()
    }
    
    @IBAction func onTrashButton(_ sender: UIBarButtonItem) {
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
        webView.scrollView.delegate = self
        self.webViewContainer.addSubview(webView)
        self.webViewContainer.addConstraints([
            NSLayoutConstraint(item: webView, attribute: .top, relatedBy: .equal, toItem: self.webViewContainer, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: webView, attribute: .left, relatedBy: .equal, toItem: self.webViewContainer, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: webView, attribute: .right, relatedBy: .equal, toItem: self.webViewContainer, attribute: .right, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: webView, attribute: .bottom, relatedBy: .equal, toItem: self.webViewContainer, attribute: .bottom, multiplier: 1, constant: 0)
            ])
        
        
        webView.scrollView.addObserver(self, forKeyPath: #keyPath(UIScrollView.contentSize), options: [.new, .old], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath else { return }
        guard let newValue = change?[.newKey] as? CGSize else { return }
        guard let oldValue = change?[.oldKey] as? CGSize else { return }
        guard recommendationView?.superview == nil || oldValue.height != newValue.height else { return }
        if keyPath == "contentSize" {
            recommendationView?.removeFromSuperview()
            setRecommendView()
        }
        
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
        recommendationView?.removeFromSuperview()
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
        
        
        if let url = URL(string: text), UIApplication.shared.canOpenURL(url) {
            webView.load(URLRequest(url: url))
            textField.resignFirstResponder()
            return true
        } else {
            
            if let encodedText = text.addingPercentEncoding(withAllowedCharacters: .alphanumerics),
                let url = URL(string: "https://www.google.co.jp/search?q=" + encodedText),
                UIApplication.shared.canOpenURL(url) {
                webView.load(URLRequest(url: url))
                textField.resignFirstResponder()
                return true
            } else {
                let ac = UIAlertController.makeSimpleAlert("Text is not URL", message: nil, okTitle: "OK", okAction: nil, cancelTitle: nil, cancelAction: nil)
                self.present(ac, animated: true, completion: nil)
                return true
            }
        }
    }
    
}

extension ViewController {
    func setRecommendView() {
        let recommendationView = UINib(nibName: "RecommendationView", bundle: nil).instantiate(withOwner: nil, options: nil).first as! RecommendationView
        recommendationView.frame = CGRect(x: 0,
                                          y: webView.scrollView.contentSize.height,
                                          width: UIApplication.shared.keyWindow!.bounds.width,
                                          height: recommendationViewHeight)
        recommendationView.backgroundColor = .gray
        webView.scrollView.addSubview(recommendationView)
        self.recommendationView = recommendationView
    }
}

extension ViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.contentSize.height > 0 else { return }
        let dy = scrollView.contentOffset.y - previousPointY
        
        let recommendContentHeight = recommendationView!.tableView.contentSize.height
        recommendationViewHeight = recommendContentHeight + recommendationViewOffset
        if recommendationView!.frame.height != recommendationViewHeight {
            recommendationView!.frame = CGRect(x: 0,
                                               y: webView.scrollView.contentSize.height,
                                               width: UIApplication.shared.keyWindow!.bounds.width,
                                               height: recommendationViewHeight + recommendationViewOffset)
        }

        
        if webView.scrollView.contentInset.bottom == recommendationViewHeight && dy > 0 {
            return
        }
        
        // show recommendation view
        if scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.frame.height {
            bottomInset += dy
            if dy > 0 {
                bottomInset = min(recommendationViewHeight, bottomInset)
            }
            
            webView.scrollView.contentInset = UIEdgeInsetsMake(0, 0, bottomInset, 0)
        } else {
            webView.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        }
        
        previousPointY = scrollView.contentOffset.y
        
        
    }
}


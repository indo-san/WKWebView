/*
 * This file is part of Adblock Plus <https://adblockplus.org/>,
 * Copyright (C) 2006-present eyeo GmbH
 *
 * Adblock Plus is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * Adblock Plus is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Adblock Plus.  If not, see <http://www.gnu.org/licenses/>.
 */

import ABPKit
import UIKit
import WebKit

// ABP content blocking example for iOS.
@available(iOS 11.0, *)
class WebViewVC: UIViewController,
                 ABPBlockable,
                 UITextFieldDelegate,
                 WKNavigationDelegate,
                 WKUIDelegate {
    @IBOutlet weak var aaButton: UIButton!
    @IBOutlet weak var reloadButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var urlField: UITextField!
    @IBOutlet weak var webView: WKWebView!
    var shared: WebViewShared!
    /// For assignment of tab name.
    var tabViewID: String = ""
    /// Set to true to add the home page to the whitelist.
    let whiteListHome = false

    override
    func viewDidLoad() {
        super.viewDidLoad()
        if ABPKit.isTesting() { reportTesting(); return }
        shared = WebViewShared(self)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        urlField.delegate = self
        if whiteListHome {
            shared.whitelistedDomains = [shared.location]
        }
        do {
            shared.abp = try ABPWebViewBlocker(
                host: self,
                noRemote: shared.noRemote)
        } catch let err { log("🚨 Error: \(err)") }
    }

    override
    func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if ABPKit.isTesting() { return }
        do {
            try shared.abp.user = shared.abp.lastUser()
                .whiteListedDomainsSet()(shared.whitelistedDomains).saved()
        } catch let err { log("🚨 Error: \(err)") }
        updateAA(shared.abp.user.acceptableAdsInUse() )
        disableControls()
    }

    override
    func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if ABPKit.isTesting() { return }
        do {
            try shared.setupABP { [unowned self] in self.enableControls() }
            #if ABP_AUTO_TESTER_AA
            if !HostAppTester.shared.testerStarted {
                HostAppTester.shared.autoAASwitch(wvc: self)
                HostAppTester.shared.testerStarted = true
            }
            #endif
        } catch let err { log("🚨 Error: \(err)") }
    }

    // ------------------------------------------------------------
    // MARK: - Actions -
    // ------------------------------------------------------------

    @IBAction func aaPressed(_ sender: Any) {
        disableControls()
        do {
            try shared.setupABP(aaChangeTo: aaButton.title(for: .normal) == shared.aaOn ? false : true) { [unowned self] in
                self.enableControls()
            }
        } catch let err { log("🚨 Error: \(err)") }
    }

    @IBAction func reloadPressed(_ sender: Any) {
        if let text = urlField.text {
            shared.loadURLString(text)
        }
    }

    // ------------------------------------------------------------

    func updateURLField(urlString: String) {
        DispatchQueue.main.async {
            self.urlField.text = urlString
        }
    }

    func reportTesting() {
        DispatchQueue.main.async {
            self.statusLabel.isHidden = false
            self.urlField.isEnabled = false
            self.reloadButton.isEnabled = false
            self.webView.isHidden = true
        }
    }

    // swiftlint:disable multiple_closures_with_trailing_closure
    // swiftlint:disable closure_end_indentation
    func reportStatus(_ status: String) {
        DispatchQueue.main.async {
            self.statusLabel.text = status
            self.statusLabel.alpha = 1
            self.statusLabel.isHidden = false
            UIView.setAnimationBeginsFromCurrentState(true)
            UIView.animate(
                withDuration: self.shared.statusDuration,
                delay: 0,
                options: .curveEaseIn,
                animations: { self.statusLabel.alpha = 0 }) { [weak self] _ in
                    self?.statusLabel.isHidden = true
                    self?.statusLabel.alpha = 1
                }
        }
    }
    // swiftlint:enable multiple_closures_with_trailing_closure
    // swiftlint:enable closure_end_indentation

    func updateAA(_ withAA: Bool) {
        DispatchQueue.main.async {
            switch withAA {
            case true:
                self.aaButton.setTitle(self.shared.aaOn, for: .normal)
            case false:
                self.aaButton.setTitle(self.shared.aaOff, for: .normal)
            }
        }
    }

    func disableControls() {
        DispatchQueue.main.async {
            self.aaButton.isEnabled = false
            self.urlField.isEnabled = false
            self.reloadButton.isEnabled = false
        }
    }

    func enableControls() {
        DispatchQueue.main.async {
            self.aaButton.isEnabled = true
            self.urlField.isEnabled = true
            self.reloadButton.isEnabled = true
        }
    }

    // ------------------------------------------------------------
    // MARK: - UITextFieldDelegate -
    // ------------------------------------------------------------

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = urlField.text {
            shared.loadURLString(text)
            textField.resignFirstResponder()
            return true
        }
        return false
    }
}

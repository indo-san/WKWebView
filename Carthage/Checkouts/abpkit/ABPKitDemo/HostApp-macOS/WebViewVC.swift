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
import Cocoa
import WebKit

// ABP content blocking example for macOS.
@available(macOS 10.13, *)
class WebViewVC: NSViewController,
                 ABPBlockable,
                 NSTextFieldDelegate,
                 WKNavigationDelegate,
                 WKUIDelegate {
    @IBOutlet weak var aaCheckButton: NSButton!
    @IBOutlet weak var reloadButton: NSButton!
    @IBOutlet weak var statusField: NSTextField!
    @IBOutlet weak var urlField: NSTextField!
    @IBOutlet weak var webView: WKWebView!
    /// Set to true to add the home page to the whitelist.
    let whiteListHome = false
    var shared: WebViewShared!
    /// For assignment of tab name.
    var tabViewID: String = ""

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
    }

    override
    func viewWillAppear() {
        super.viewWillAppear()
        if ABPKit.isTesting() { return }
        // On iOS, the following code happens in viewDidLoad. It is placed here so that unit tests can run.
        do {
            if shared.abp == nil {
                shared.abp = try ABPWebViewBlocker(
                    host: self,
                    noRemote: shared.noRemote)
            }
            try shared.abp.user = shared.abp.lastUser()
                .whiteListedDomainsSet()(shared.whitelistedDomains).saved()
        } catch let err { log("🚨 Error: \(err)") }
        updateAA(shared.abp.user.acceptableAdsInUse() )
        urlField.becomeFirstResponder()
        disableControls()
    }

    override
    func viewDidAppear() {
        super.viewDidAppear()
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

    @IBAction func enterURLSelected(_ sender: Any) {
        self.view.window?.makeFirstResponder(urlField)
    }

    @IBAction func aaPressed(_ sender: Any) {
        disableControls()
        #if ABP_AUTO_TESTER_AA
        aaCheckButton.setNextState()
        #endif
        do {
            try shared.setupABP(aaChangeTo: aaCheckButton.state == .off ? false : true) { [unowned self] in
                self.enableControls()
            }
        } catch let err { log("🚨 Error: \(err)") }
    }

    @IBAction func reloadPressed(_ sender: Any) {
        shared.loadURLString(urlField.stringValue)
    }

    // ------------------------------------------------------------

    func updateURLField(urlString: String) {
        DispatchQueue.main.async {
            self.urlField.stringValue = urlString
        }
    }

    func reportTesting() {
        DispatchQueue.main.async {
            self.statusField.isHidden = false
            self.aaCheckButton.isEnabled = false
            self.urlField.isEnabled = false
            self.reloadButton.isEnabled = false
            self.webView.isHidden = true
        }
    }

    func reportStatus(_ status: String) {
        let animate: (NSTextField, TimeInterval, CGFloat, @escaping () -> Void) -> Void = { fld, dur, alp, cmp in
            NSAnimationContext.runAnimationGroup ({ ctx in
                ctx.duration = dur
                fld.animator().alphaValue = alp
            }, completionHandler: cmp)
        }
        DispatchQueue.main.async {
            self.statusField.stringValue = status
            self.statusField.isHidden = false
            animate(self.statusField, 0, 1) {
                animate(self.statusField, self.shared.statusDuration, 0, {})
            }
        }
    }

    func updateAA(_ withAA: Bool) {
        DispatchQueue.main.async {
            switch withAA {
            case true:
                self.aaCheckButton.state = .on
            case false:
                self.aaCheckButton.state = .off
            }
        }
    }

    func disableControls() {
        DispatchQueue.main.async {
            self.aaCheckButton.isEnabled = false
            self.urlField.isEnabled = false
            self.reloadButton.isEnabled = false
        }
    }

    func enableControls() {
        DispatchQueue.main.async {
            self.aaCheckButton.isEnabled = true
            self.urlField.isEnabled = true
            self.reloadButton.isEnabled = true
            self.urlField.becomeFirstResponder()
        }
    }

    // ------------------------------------------------------------
    // MARK: - NSTextFieldDelegate -
    // ------------------------------------------------------------

    func controlTextDidEndEditing(_ obj: Notification) {
        if urlField.stringValue.count > 0 {
            shared.loadURLString(urlField.stringValue)
        }
    }
}

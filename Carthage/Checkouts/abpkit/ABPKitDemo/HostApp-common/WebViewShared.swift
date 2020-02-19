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
import RxSwift
import WebKit

class WebViewShared {
    // MARK: - For Testing -
    let webHome = "adblockplus.org"
    let webProtocol = "https"
    /// Set domains to be whitelisted. Note that an empty string member ("") will match all domains.
    /// If there is a port number (eg 8080), it can be included here with a colon separator.
    var whitelistedDomains: [String] = []
    // MARK: - End For Testing -
    let aaOff = "AA is Off"
    let aaOn = "AA is On"
    /// Disable JavaScript to eliminate interference during testing.
    let javascriptDisabledDomains = ["adblockplus.org"]
    let retryMax = 2
    let retryDelay: TimeInterval = 9
    /// When true, no remote blocklist downloads will be used.
    let noRemote = false
    /// Length of time to show status messages.
    let statusDuration: TimeInterval = 17
    /// This message should be displayed whenever new downloaded rules are being used for the first time.
    let switchToDLMessage = "Switched to Downloaded Rules"
    /// For logging user history.
    let userHist: (ABPWebViewBlocker) -> [String] = {
        $0.user.getHistory()?.reduce([]) { $0 + [$1.name] } ?? ["missing"]
    }
    var abp: ABPWebViewBlocker!
    var bag = DisposeBag()
    var location: String!
    var retryCount = 0
    /// Domain names hardcoded here will be whitelisted for the user.
    weak var wvvc: WebViewVC!

    init(_ webViewVC: WebViewVC) {
        wvvc = webViewVC
        location = webProtocol + "://" + webHome
    }

    /// Add and enable content blocking rules while loading a URL and start
    /// download of remote sources. User state is logged for information only.
    /// - parameter aaChangeTo: Change the AA enabled state to the given value.
    /// - parameter completion: For running a closure on completion.
    func setupABP(aaChangeTo: Bool? = nil, completion: @escaping () -> Void) throws {
        log("👩🏻‍🎤0 \(wvvc.tabViewID) hist \(self.userHist(self.abp))")
        var forceCompile = false
        if aaChangeTo != nil {
            try changeUserAA(aaChangeTo!)
            forceCompile = true // list change requires new compilation
        }
        try wvvc.updateAA(abp.lastUser().acceptableAdsInUse())
        abp.useContentBlocking(
            forceCompile: forceCompile,
            logCompileTime: true,
            logBlockListSwitchDL: { [unowned self] in
                self.wvvc.reportStatus(self.switchToDLMessage)
                log("▶️ \(self.switchToDLMessage)")
            }, completeWith: { [unowned self] err in
                if err != nil {
                    log("🚨 Error: \(err as Error?)")
                    // Rule loading failures can occur with a mismatched User state where the
                    // specified rules are not available such as when switching tabs before
                    // downloaded rules are ready. The following retry is a workaround to this
                    // problem until a more definitive solution is created.
                    self.validateRules(user: self.abp.user, error: err)
                    self.retryCount += 1
                    if self.retryCount <= self.retryMax {
                        DispatchQueue.main.asyncAfter(deadline: .now() + self.retryDelay) {
                            do {
                                try self.setupABP(aaChangeTo: aaChangeTo, completion: completion)
                            } catch let err { log("🚨 Error: \(err)") }
                        }
                    } else { log("🚨 Failure: Maximum retries exceeded.") }
                } else {
                    self.loadURLString(self.location)
                    completion()
                    forceCompile = false // reset state
                }
            })
    }

    /// Validate the rules if WK rule loading did not succeed.
    /// This example implementation only logs the error.
    func validateRules(user: User, error: Error?) {
        if ((error as? WKErrorHandler)?.wkError as? WKError)?.errorCode != nil {
            abp.validateRules(user: user) { result in
                switch result {
                case .success(let validation):
                    log("⚠️ WK rule loading validation result: \(validation)")
                case .failure(let err):
                    log("🚨 Rule validation completely failed: \(err)")
                }
            }
        }
    }

    /// User state is changed according to their AA preference.
    /// The correct matching blocklist should be saved for the user.
    /// If there is no matching blocklist then save a new one.
    func changeUserAA(_ aaIsOn: Bool) throws {
        var src: RemoteBlockList!
        switch aaIsOn {
        case true:
            src = .easylistPlusExceptions
        case false:
            src = .easylist
        }
        // Using the persisted user here helps use the most recent historical block list match.
        // However, it is not strictly necessary and `abp.user = try abp.user.blockListSet()`
        // is also sufficient for most cases.
        abp.user = try abp.lastUser().blockListSet()(
            BlockList(withAcceptableAds: aaIsOn, source: src, initiator: .userAction)).saved()
    }

    /// Disable JavaScript for a matching host or hosts.
    func disableJavaScript(urlString: String) {
        DispatchQueue.main.async {
            URL(string: urlString)?.host.map { host in
                self.wvvc.webView.configuration.preferences.javaScriptEnabled =
                    self.javascriptDisabledDomains.map {
                        host.range(of: "\($0)$", options: .regularExpression, range: nil, locale: nil) != nil
                    }
                    .filter { $0 }
                    .count < 1
            }
        }
    }

    func loadURLString(_ urlString: String) {
        disableJavaScript(urlString: urlString)
        abp.loadURLString(urlString) { [unowned self] url, err in
            guard let url = url, err == nil else { log("🚨 Error: \(err!)"); return }
            wvvc.updateURLField(urlString: url.absoluteString)
            self.location = url.absoluteString
        }
    }
}

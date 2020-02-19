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

import RxSwift
import WebKit

/// Block ads in a WKWebView for a host app.
///
/// The User state in this class, accessed as self.user, is used internally to direct operations. It
/// is not persisted on every change. Passing the transient user state as a parameter is preferred
/// over relying on a persistent copy. Both cases exist within and are carefully coordinated for
/// consistency.
@available(iOS 11.0, macOS 10.13, *)
public
class ABPWebViewBlocker {
    public let lastUpdater: () throws -> Updater = {
        if let updtr = try Updater(fromPersistentStorage: true) { return updtr }
        return try Updater().saved()
    }
    /// Retrieve the last user state. If none, return the default.
    public let lastUser: () throws -> User = {
        if let user = try User(fromPersistentStorage: true) { return user }
        return try User().saved()
    }
    /// Overrideable function allowing specification of the user state that will be used for block list updates.
    public var setUserForBlockListUpdate: (@escaping () -> (User)) -> Void = {
        ABPBlockListUpdater.sharedInstance().userForUpdate = $0
    }
    /// Check if a remote source has not yet been downloaded for the user.
    /// This does not look at existing DLs. Since this is a state change, initiated by a user, not look at existing DLs
    /// ensures that the user receives the latest version.
    let remoteNotYetDL: (User) -> Bool? = { user in
        let notYetDL = user.getBlockList().map { blst in
            SourceHelper().isRemote()(blst.source) &&
                blst.dateDownload == nil &&
                user.acceptableAdsInUse() == (blst.source as? RemoteBlockList)?.hasAcceptableAds()
        }
        return notYetDL
    }
    var updater: Updater!
    public var user: User!
    /// For rule processing:
    lazy var abpQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = Constants.queueRules
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    weak var ctrl: WKUserContentController!
    /// Log file removals during user state syncing if true.
    var logFileRemovals = false
    /// For debugging: Don't use remote rules when true.
    var noRemote: Bool!
    var ruleListID: String?
    var wkcb: WebKitContentBlocker!
    weak var host: ABPBlockable!

    /// Uses a given user state.
    public
    init(host: ABPBlockable,
         user: User? = nil,
         noRemote: Bool = false,
         logFileRemovals: Bool = false) throws {
        Bags.bagCreate()(.webViewBlocker, self)
        RxSchedulers.createWebViewBlockerScheduler(queue: abpQueue)
        self.host = host
        self.logFileRemovals = logFileRemovals
        self.noRemote = noRemote
        wkcb = WebKitContentBlocker(logWith: { log("📙 store \($0 as [String]?)") })
        ctrl = host.webView.configuration.userContentController
        if user != nil {
            self.user = user
        } else { self.user = try lastUser() }
        _ = ABPBlockListUpdater.sharedInstance()
        ABPBlockListUpdater.sharedInstance().startUpdating()
    }

    deinit {
        Bags.bagDispose()(.webViewBlocker, self)
    }
}

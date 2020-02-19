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

@available(iOS 11.0, macOS 10.13, *)
extension ABPBlockListUpdater {
    /// An extra bag creation is added here due to having found the bag to
    /// be nil under the conditions created by testDeallocatedWebView().
    func startUpdating() {
        if !updaterRunning {
            downloadsUpdate().disposed(by: Bags.bag()(.blockListUpdater, self))
            handleErrors()
            updaterRunning = true
        }
    }

    func handleErrors() {
        // Ignore NSErrorDomain code 4 (remove item failed) as it is a non-critical error
        // related to download file syncing.
        let allowedErrorCode = 4
        updaterErrors
            .filter { err in
                if let nsErr = err as NSError?, nsErr.code == allowedErrorCode {
                    log("⚠️ upd_err \(err as Error?)")
                    return false
                }
                return true
            }
            .subscribe(onNext: { err in
                if err != nil {
                    // If an error occurs that is not explicitly handled above, the updater will remove
                    // itself from memory and automatic updates will no longer occur.
                    log("🛑 upd_err \(err as Error?)")
                }
            }).disposed(by: Bags.bag()(.blockListUpdater, self))
    }

    /// Start a timer to provide a signal for a periodic update.
    /// Call with ABPBlockListUpdater.sharedInstance().userAfterUpdate().
    /// WARNING: Emits no next event when user for update is nil.
    func afterUpdate() -> SingleUpdater {
        Observable<Int>.interval(self.period.toMilliseconds(), scheduler: scheduler)
            .filter { [unowned self] _ in
                /// Perform a check on whether to update on the user state:
                if let user = ABPBlockListUpdater.sharedInstance().userForUpdate(),
                    self.userBlockListShouldUpdate()(user) { return true }
                return false
            }
            .flatMap { _ -> SingleUpdater in
                if let user = ABPBlockListUpdater.sharedInstance().userForUpdate() {
                    var updtr: Updater!
                    do {
                        updtr = try Updater(fromPersistentStorage: true)
                        updtr.blockList = user.blockList
                        let dler = try BlockListDownloader(initiator: .automaticUpdate, consumer: updtr)
                        return dler.afterDownloads(initiator: .automaticUpdate)(dler.userSourceDownloads(initiator: .automaticUpdate))
                    } catch let err { return .error(err) }
                }
                return .empty()
            }
    }

    /// Works with a User state but not intended to automatically replace the user's block list.
    func downloadsUpdate() -> Disposable {
        let updater = ABPBlockListUpdater.sharedInstance()
        #if ABPDEBUG
        updater.expiration = Constants.blocklistExpirationDebug
        #endif
        return updater.afterUpdate()
            .flatMap { updtr -> SingleUpdater in
                var updaterToSave: Updater!
                do {
                    updaterToSave = try updtr.userSyncedDownloadsSaved(initiator: .automaticUpdate)
                } catch let err { return .error(err) }
                return .just(updaterToSave)
            }.subscribe(onNext: { upd in
                /// The rules do not get added to the content controller until the host app calls
                /// useContentBlocking(). This prevents state mismatches between the user's history
                /// and the rules loaded into the WK rule store.
                ///
                /// It is always the **next call** to useContentBlocking() that activates the new rules
                /// (adding them to the content controller). In this way, even if the history maximum is
                /// exceeded by new downloads, it won't affect the next call.
                do {
                    try upd.save()
                } catch let err { self.updaterErrors.onNext(err) }
            }, onError: {
                self.updaterErrors.onNext($0)
            }, onDisposed: {
                // This is the only place where destroy should be called.
                ABPBlockListUpdater.destroy()
            })
    }
}

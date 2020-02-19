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

@available(iOS 11.0, macOS 10.13, *)
extension ABPWebViewBlocker {
    /// Activate bundled or downloaded rule list, as needed.
    /// * Requires a persisted User to be available.
    /// * Compilation can be forced when a new list will be loaded.
    /// - parameter forceCompile: Rule compilation will happen (optional).
    /// - parameter logCompileTime: For logging rule compile time if true (optional).
    /// - parameter logBlockListSwitchDL: For logging BL switching after downloading (optional).
    /// - parameter completeWith: Handle completion.
    // swiftlint:disable function_body_length
    public
    func useContentBlocking(forceCompile: Bool = false,
                            logCompileTime: Bool = false,
                            logBlockListSwitchDL: (() -> Void)? = nil,
                            completeWith: @escaping (Error?) -> Void) {
        var didDL = false
        do {
            user = try lastUser() // load user state
        } catch let err { completeWith(err); return }
        fromExistingOrNewRuleList(forceCompile: forceCompile, logCompileTime: true)
            .flatMap { _ -> Observable<User> in
                // Call the completion handler to allow a UI update but continue additional processing.
                completeWith(nil)
                let shlp = SourceHelper()
                if let src = shlp.userSourceable(self.user), !shlp.isRemote()(src) && !self.noRemote ||
                    self.remoteNotYetDL(self.user) == true {
                        didDL = true
                        return self.withRemoteBLNewDownloader(self.user.acceptableAdsInUse())
                } else { return .just(self.user) }
            }
            .filter { _ in didDL }
            .flatMap { usr -> Observable<User> in
                do { // state change to remote BL after DLs
                    // Get a matching BL:
                    if let blst = ABPWebViewBlocker.matchUserBlockList(toListType: .userDownload)(usr, try self.lastUpdater()) {
                        self.user = try usr.blockListSet()(blst).saved()
                    }
                } catch let err { completeWith(err) }
                return .just(self.user)
            }
            .filter { (usr: User) in
                // Prevent placeholder block lists from being added:
                usr.blockList?.dateDownload != nil
            }
            .flatMap { usr -> Observable<WKContentRuleList?> in
                // Rule adding path #4:
                self.rulesAdded(rhc: .usersBlockList)(usr)
            }
            .subscribeOn(RxSchedulers.webViewBlockerScheduler)
            .subscribe(onNext: { _ in
                if didDL {
                    logBlockListSwitchDL?()
                }
            }, onError: { err in
                // If the rules failed to load into WK, isolated handling can happen, for example:
                // if type(of: err) == WKErrorHandler.self { }
                //
                // There is an edge case where matching rule store rules do not exist for any member in
                //
                // 1. User history
                // 2. Downloads
                // 3. Blocklist (active)
                //
                // for the current user state that is not explicitly handled. Starting with a new user
                // state should bypass this condition if it occurs.
                #if ABP_AUTO_TESTER_FAIL_ON_ERR
                fatalError(err.localizedDescription)
                #else
                completeWith(err)
                #endif
            }, onCompleted: { [unowned self] in
                do {
                    self.user = try self.user.userSyncedDownloadsSaved(initiator: .userAction)
                } catch let err { completeWith(err) }
                completeWith(nil)
            }, onDisposed: {
                // This subscription will be disposed after completion.
            }).disposed(by: Bags.bag()(.webViewBlocker, self))
    }
    // swiftlint:enable function_body_length

    /// For extra performance, rules are not validated or counted before loading.
    /// This function provides that service.
    /// - parameter completion: Callback that gives a struct containing rules validation results.
    public
    func validateRules(user: User, completion: @escaping (Result<RulesValidation, Error>) -> Void) {
        do {
            _ = try user.rawRulesString()(user.rulesURL())
                .map {
                    if let rules = $0 {
                        self.wkcb.validatedRulesWithRaw(rules: rules)
                            .subscribe {
                                switch $0 {
                                case .success(let rslt):
                                    completion(.success(rslt))
                                case .error(let err):
                                    completion(.failure(err))
                                }
                            }.disposed(by: Bags.bag()(.webViewBlocker, self))
                    } else { throw ABPBlockListError.badRulesRaw }
                }
        } catch let err { completion(.failure(err)) }
    }

    // swiftlint:disable unused_closure_parameter
    /// Synchronize the WK rule store while returning a given added rule list.
    ///
    /// Optionality of rule list, for this one and all related usages, can be removed once a nil
    /// condition is not used to check remote DLs.
    func historySyncForAdded() -> (WKContentRuleList?) -> SingleRuleListOptional {
        { list in
            guard let added = list else { return .just(nil) }
            return self.wkcb.syncHistoryRemovers(target: .userBlocklistAndHistory)(self.user) // one or more removes
                .flatMap { remove -> SingleRuleListID in
                    remove
                }
                .flatMap { removed -> SingleRuleListOptional in
                    .just(added)
                }
        }
    }
    // swiftlint:enable unused_closure_parameter

    /// Add rules from user's history or user's blocklist.
    /// If a DL needs to happen, this function returns early. This will be refactored in future
    /// revisions to not be required. The intention is to treat existing lists the same as future
    /// (not yet DL) lists.
    func fromExistingOrNewRuleList(forceCompile: Bool = false,
                                   logCompileTime: Bool = false) -> SingleRuleListOptional {
        var existing: BlockList?
        if remoteNotYetDL(user) == true { return .just(nil) }
        do {
            if let update = ABPWebViewBlocker.matchUserBlockList(toListType: .automaticUpdate)(user, try self.lastUpdater()) {
                user = user.blockListSet()(update)
            } else {
                existing = ABPWebViewBlocker.matchUserBlockList(toListType: .userHistory)(user, try self.lastUpdater())
            }
        } catch let err { return .error(err) }
        // Force compilation of lists due to condition that WK rule store should
        // only have active rules. Not forcing allows re-use of existing rules
        // and non-delayed switching among consumers.
        if !forceCompile && existing != nil {
            // Rule adding path #1:
            // This pathway is traversed when switching amongst multiple WKWebViews where we use existing rules in the store:
            return rulesAdded(rhc: .existing(existing!))(user)
        }
        // Rule adding path #2:
        if existing != nil {
            return rulesAdded(rhc: .existing(existing!))(user)
        }
        // Rule adding path #3:
        return rulesAdded(rhc: .usersBlockList, logCompileTime: logCompileTime)(user)
    }

    /// Loads rules (from the user's BL) into the user content controller.
    /// History sync returning multiple observables can be handled with takeLast(1).
    func blockListableCCAdded() -> (User) -> SingleRuleListOptional {
        { usr in
            if let blst = usr.getBlockList() {
                return self.contentControllerAddBlocklistable(clear: true)(blst)
                    .flatMap { added -> SingleRuleListOptional in
                        self.historySyncForAdded()(added)
                    }
            } else { return .just(nil) }
        }
    }

    /// Initiate a download when needed.
    /// The user state blocklist is switched to a **placeholder** remote source with the AA state of
    /// the user passed in so that the downloader knows how to proceed. The eventual `BlockList`
    /// resulting from the download will be a different one.
    /// - returns: A user state after downloads.
    func withRemoteBLNewDownloader(_ aaInUse: Bool) -> SingleUser {
        var user: User!
        do {
            user = try User(
                fromPersistentStorage: true,
                withBlockList: BlockList(
                    withAcceptableAds: aaInUse,
                    source: SourceHelper().remoteSourceForAA()(aaInUse),
                    initiator: .userAction))
        } catch let err { return .error(err) }
        let dler = BlockListDownloader(user: user)
        return dler.afterDownloads(initiator: .userAction)(dler.userSourceDownloads(initiator: .userAction))
    }
}

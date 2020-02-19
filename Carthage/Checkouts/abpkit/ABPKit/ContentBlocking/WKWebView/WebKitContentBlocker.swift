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
class WebKitContentBlocker: Loggable {
    typealias LogType = [String]?

    let cfg = Config()
    var bag: DisposeBag!
    var bundle: Bundle?
    var rulesStore: WKContentRuleListStore!
    /// For debugging.
    var logWith: ((LogType) -> Void)?

    init?(logWith: ((LogType) -> Void)? = nil) {
        bag = DisposeBag()
        guard let rulesStore =
            try? WKContentRuleListStore(url: cfg.rulesStoreIdentifier())
        else { return nil }
        self.rulesStore = rulesStore
        self.logWith = logWith
    }

    /// From user's block list, make a rule list and add it to the WK rule store.
    /// - parameter user: State for user
    /// - parameter logCompileTime: For logging rule compile time (optional)
    /// - returns: Observable of a rule list
    func rulesAddedWKStore(user: User,
                           initiator: DownloadInitiator,
                           customBundle: Bundle? = nil,
                           logCompileTime: Bool = false) -> SingleRuleList {
        whitelistToRulesAdded(customBundle: customBundle)(user)
            .flatMap { result -> SingleRuleList in
                guard let rules = result else { return .error(ABPBlockListError.badRulesRaw) }
                return self.rulesCompiled(user: user, rules: rules, initiator: initiator, logCompileTime: logCompileTime)
            }
            .flatMap { rlst -> Observable<WKContentRuleList> in
                self.ruleListVerified(userList: user.blockList, ruleList: rlst)
            }
    }

    func testingWhiteListRuleForUser() -> (User) -> StreamRule {
        { user in
            guard let dmns = user.whitelistedDomains, dmns.count > 0 else { return .error(ABPUserModelError.badDataUser) }
            let userWLRule: (User) -> Observable<BlockingRule> = { user in
                var cbUtil: ContentBlockerUtility!
                do {
                    cbUtil = try ContentBlockerUtility()
                } catch let err { return .error(err) }
                return .just(cbUtil.whiteListRuleForDomains()(dmns))
            }
            return userWLRule(user)
        }
    }

    /// Check that a user list, in their history, matches a rule list in the WK store.
    /// * This function has a completely different meaning from validated rules in that it verifies user state against
    ///   the rule store and is not related to parsing.
    /// * IDs may be logged using withIDs.
    func ruleListVerified<U: BlockListable>(userList: U?, ruleList: WKContentRuleList) -> SingleRuleList {
        ruleListIdentifiers()
            .flatMap { ids -> Observable<WKContentRuleList> in
                .create { observer in
                    if let ulst = userList,
                       ulst.name != ruleList.identifier ||
                       ids?.contains(ulst.name) == false { observer.onError(ABPWKRuleStoreError.invalidRuleData)
                        }
                    self.logWith?(ids)
                    observer.onNext(ruleList)
                    observer.onCompleted()
                    return Disposables.create()
                }
            }
    }

    /// Wrapper for IDs in the rule store.
    func ruleListIdentifiers() -> SingleRuleListIDsOptional {
        .create { [unowned self] observer in
            self.rulesStore
                .getAvailableContentRuleListIdentifiers { ids in
                    observer.onNext(ids)
                    observer.onCompleted()
                }
            return Disposables.create()
        }
    }

    /// Wrapper for rules compile.
    /// Rules should match the user's block list.
    func rulesCompiled(user: User,
                       rules: String,
                       initiator: DownloadInitiator,
                       logCompileTime: Bool = false) -> SingleRuleList {
        switch initiator {
        case .userAction:
            return rulesCompiledForIdentifier(user.blockList?.name, logCompileTime: logCompileTime)(rules)
        case .automaticUpdate:
            return rulesCompiledForIdentifier(UUID().uuidString, logCompileTime: logCompileTime)(rules)
        default:
            return .error(ABPBlockListError.badInitiator)
        }
    }

    /// Compile rules with WK.
    /// - parameters:
    ///   - identifier: WK rule list ID.
    ///   - logCompileTime: For compile time logging due to being longest running, CPU intensive process.
    /// - returns: Observable with the WK rule list.
    func rulesCompiledForIdentifier(_ identifier: String?,
                                    logCompileTime: Bool = false) -> (String) -> SingleRuleList {
        { [unowned self] rules in
            Observable.create { observer in
                let start = Date() // only for compile time logging
                self.rulesStore
                    .compileContentRuleList(forIdentifier: identifier,
                                            encodedContentRuleList: rules) { list, err in
                        if logCompileTime { log("⏱️ cmpl \(fabs(start.timeIntervalSinceNow)) - (\(identifier as String?)") }
                            guard err == nil else { observer.onError(WKErrorHandler(err!)); return }
                            if list != nil {
                                observer.onNext(list!)
                                observer.onCompleted()
                            }
                            observer.onError(ABPWKRuleStoreError.invalidRuleData)
                    }
                    return Disposables.create()
            }.subscribeOn(MainScheduler.asyncInstance)
            // In WebKit, compileContentRuleList was found to be not
            // thread-safe. It requires being called from main even though it
            // runs on a different thread.
        }
    }

    /// Failures during remove are allowed because subsequent calls can account for any items not
    /// previously removed.
    /// Additional withID closure for debugging as found useful during testing.
    func listRemovedFromStore(identifier: String, withID: ((String) -> Void)? = nil) -> SingleRuleListID {
        .create { observer in
            self.rulesStore
                .removeContentRuleList(forIdentifier: identifier) { err in
                    withID?(identifier)
                    // Remove for identifier operation is complete at this point.
                    if err != nil {
                        if let wkErr = err as? WKError, wkErr.code == .contentRuleListStoreRemoveFailed {
                            observer.onNext("") // ignore error
                            observer.onCompleted()
                        } else { observer.onError(err!) }
                    }
                    observer.onNext(identifier)
                    observer.onCompleted()
                }
            return Disposables.create()
        }
    }
}

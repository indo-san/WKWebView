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

import Combine
import WebKit

@available(iOS 13.0, *)
class WebKitContentBlocker: Loggable
{
    typealias LogType = [String]?

    let cfg = Config()
    var bundle: Bundle?
    var rulesStore: WKContentRuleListStore!
    /// For debugging.
    var logWith: ((LogType) -> Void)?

    init?(logWith: ((LogType) -> Void)? = nil)
    {
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
                           logCompileTime: Bool = false) -> SingleRuleList
    {
        whitelistToRulesAdded()(user)
            .flatMap { result -> SingleRuleList in
                guard let rules = result else { return Fail(error: ABPBlockListError.badRulesRaw).eraseToAnyPublisher() }
                return self.rulesCompiled(user: user, rules: rules, initiator: initiator, logCompileTime: logCompileTime)
            }
            .flatMap { rlst in
                self.ruleListVerified(userList: user.blockList, ruleList: rlst)
            }.eraseToAnyPublisher()
    }

    func testingWhiteListRuleForUser() -> (User) -> StreamRule
    {
        { user in
            guard let dmns = user.whitelistedDomains, dmns.count > 0 else { return Fail(error: ABPUserModelError.badDataUser).eraseToAnyPublisher() }
            let userWLRule: (User) -> StreamRule = { user in
                var cbUtil: ContentBlockerUtility!
                do {
                    cbUtil = try ContentBlockerUtility()
                } catch let err { return Fail(error: err).eraseToAnyPublisher() }
                return SinglePublisher(cbUtil.whiteListRuleForDomains()(dmns)).eraseToAnyPublisher()
            }
            return userWLRule(user)
        }
    }

    /// Check that a user list, in their history, matches a rule list in the WK store.
    /// * This function has a completely different meaning from validated rules in that it verifies user state against
    ///   the rule store and is not related to parsing.
    /// * IDs may be logged using withIDs.
    func ruleListVerified<U: BlockListable>(userList: U?, ruleList: WKContentRuleList) -> SingleRuleList
    {
        return ruleListIdentifiers()
            .flatMap { ids in
                RuleListVerifiedPublisher(ids: ids, userList: userList, ruleList: ruleList, wkcb: self)
            }.eraseToAnyPublisher()
    }

    /// Wrapper for IDs in the rule store.
    func ruleListIdentifiers() -> SingleRuleListIDsOptional
    {
        RuleListIdentifiersPublisher(wkcb: self).eraseToAnyPublisher()
    }

    /// Wrapper for rules compile.
    /// Rules should match the user's block list.
    func rulesCompiled(user: User,
                       rules: String,
                       initiator: DownloadInitiator,
                       logCompileTime: Bool = false) -> SingleRuleList
    {
        switch initiator {
        case .userAction:
            return rulesCompiledForIdentifier(user.blockList?.name, logCompileTime: logCompileTime)(rules)
        case .automaticUpdate:
            return rulesCompiledForIdentifier(UUID().uuidString, logCompileTime: logCompileTime)(rules)
        default:
            return Fail(error: ABPBlockListError.badInitiator).eraseToAnyPublisher()
        }
    }

    /// Compile rules with WK.
    /// - parameters:
    ///   - identifier: WK rule list ID.
    ///   - logCompileTime: For compile time logging due to being longest running, CPU intensive process.
    /// - returns: Observable with the WK rule list.
    func rulesCompiledForIdentifier(_ identifier: String?, logCompileTime: Bool = false) -> (String) -> SingleRuleList
    {
        { RuleListPublisher(identifier: identifier, rules: $0, wkcb: self).eraseToAnyPublisher() }
    }

    /// Failures during remove are allowed because subsequent calls can account for any items not
    /// previously removed.
    /// Additional withID closure for debugging as found useful during testing.
    func listRemovedFromStore(identifier: String, withID: ((String) -> Void)? = nil) -> SingleRuleListID
    {
        ListRemovedFromStorePublisher(identifier: identifier, withID: withID, wkcb: self).eraseToAnyPublisher()
    }
}

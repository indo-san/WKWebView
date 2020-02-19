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
extension WebKitContentBlocker {
    /// Get the content blocking rules while validating and counting them.
    /// This function will be deprecated in a future version.
    /// Only called during testing.
    /// Not added to ABPKit-Combine.
    /// - parameter customBundle: For testing and special cases.
    /// - returns: Observable of rules and their count.
    func countedRules(customBundle: Bundle? = nil) -> (User) -> SingleRuleStringAndCount {
        { user in
            do {
                let url = try user.rulesURL(customBundle: customBundle)
                var total = 0
                return try user.decodedRulesFromURL()(url)
                    .reduce(0) { acc, _ in acc + 1 }
                    .flatMap { cnt -> SingleRawRulesOptional in
                        total = cnt
                        return user.rawRulesString()(url)
                    }.flatMap { rawRules -> SingleRuleStringAndCount in
                        if let rules = rawRules {
                            return .just((rules, total))
                        } else { return .error(ABPBlockListError.badRulesRaw) }
                    }
            } catch let err { return .error(err) }
        }
    }

    /// Wrapper for rawRulesString.
    func rawRules(customBundle: Bundle? = nil) -> (User) -> SingleRawRulesOptional {
        { user in
            do {
                return try user.rawRulesString()(user.rulesURL(customBundle: customBundle))
            } catch let err { return .error(err) }
        }
    }

    func whitelistToRulesAdded(customBundle: Bundle? = nil) -> (User) -> SingleRawRulesOptional {
        { user in
            RulesBeforeWK(user: user, wkcb: self, bundle: customBundle)
                .rawRules()
        }
    }

    /// Get only block list rules without whitelist items added.
    /// This is a counterpart to whitelistToRulesAdded().
    /// Not added to ABPKit-Combine.
    func onlyBlockListRules(customBundle: Bundle? = nil) -> (User) -> SingleRawRulesOptional {
        { user in
            RulesBeforeWK(user: user, withNoWhitelist: true, wkcb: self, bundle: customBundle)
                .rawRules()
        }
    }

    /// This function is only used during testing:
    /// Handles blocklist rules for a user.
    /// Not added to ABPKit-Combine.
    func concatenatedRules(user: User,
                           customBundle: Bundle? = nil) -> SingleRuleStringAndCount {
        let withWL: (User) throws -> SingleRuleStringAndCount = {
            try self.concatenatedRules(customBundle: customBundle)(
                $0.decodedRulesFromURL()($0.rulesURL(customBundle: customBundle))
                    .concat(self.testingWhiteListRuleForUser()($0)))
        }
        let withoutWL: (User) throws -> SingleRuleStringAndCount = {
            try self.concatenatedRules(customBundle: customBundle)($0.decodedRulesFromURL()($0.rulesURL(customBundle: customBundle)))
        }
        do {
            if user.whitelistedDomains?.count ?? 0 > 0 {
                return try withWL(user)
            } else {
                return try withoutWL(user)
            }
        } catch let err { return .error(err) }
    }

    /// Only called during testing.
    /// Not added to ABPKit-Combine.
    /// - returns: Clearers for rules in the rule store for a user.
    func ruleListClearersForUser() -> (User) -> StreamRuleListID {
        { [unowned self] user in
            self.ruleListIdentifiers()
                .flatMap { identifiers -> StreamRuleListID in
                    guard let hist = user.blockListHistory,
                        let ids = identifiers else { return .error(ABPWKRuleStoreError.invalidRuleData) }
                    let obs = ids
                        .filter { idr in !(hist.contains { $0.name == idr }) }
                        .map { [unowned self] idr in self.listRemovedFromStore(identifier: idr) }
                    if obs.count < 1 { return .error(ABPWKRuleStoreError.missingRuleList) }
                    return .concat(obs)
                }
        }
    }

    /// Only called during testing.
    /// Not added to ABPKit-Combine.
    /// - returns: Clearers for all RLs.
    func ruleListAllClearers() -> StreamRuleListID {
        ruleListIdentifiers()
            .flatMap { identifiers -> StreamRuleListID in
                guard let ids = identifiers else { return .error(ABPWKRuleStoreError.invalidRuleData) }
                return .concat(ids.map { [unowned self] in self.listRemovedFromStore(identifier: $0) })
            }
    }
}

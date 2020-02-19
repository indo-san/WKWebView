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
extension RulesBeforeWK {
    /// There is a function with a signature of rawRules(customBundle:) in the WebKitContentBlocker.
    /// That one is not related to white list processing in RulesBeforeWK.
    /// The bundle parameter comes from the init in this definition.
    func rawRules() -> SingleRawRulesOptional {
        switch self {
        case .whiteListAdded(let user, let wkcb, let bndl):
            return self.withWL()(user, wkcb, bndl)
        case .withoutWhiteList(let user, let wkcb, let bndl):
            return self.withoutWL()(user, wkcb, bndl)
        }
    }

    func withWL() -> (User, WebKitContentBlocker, Bundle?) -> SingleRawRulesOptional {
        { user, wkcb, bndl in
            wkcb.rawRules(customBundle: bndl)(user)
                .flatMap { raw -> SingleRawRulesOptional in
                    guard let rules = raw else { return .error(ABPBlockListError.badRulesRaw) }
                    do {
                        return try .just(WhiteListAdder().wlAdded(rules, user, wkcb))
                    } catch let err { return .error(err) }
                }
        }
    }

    func withoutWL() -> (User, WebKitContentBlocker, Bundle?) -> SingleRawRulesOptional {
        { user, wkcb, bndl in
            #if ABPDEBUG
            return wkcb.rawRules(customBundle: bndl)(user)
                .flatMap { raw -> SingleRawRulesOptional in
                    guard let rules = raw else { return .error(ABPBlockListError.badRulesRaw) }
                    var copy = rules
                    do {
                        try wkcb.openJSONArray(&copy)
                    } catch let err { return .error(err) }
                    return .just(copy
                        .appending(Constants.blocklistRuleSeparator)
                        .appending(wkcb.hostAppTestRuleString(aaEnabled: user.acceptableAdsInUse()))
                        .appending(Constants.blocklistArrayEnd))
                }
            #else
            return wkcb.rawRules(customBundle: bndl)(user)
            #endif
        }
    }
}

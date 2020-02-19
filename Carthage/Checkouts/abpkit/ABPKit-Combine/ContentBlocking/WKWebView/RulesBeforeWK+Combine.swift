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

// Work In Progress for Combine.

extension RulesBeforeWK
{
    func rawRules() -> SingleRawRulesOptional {
        switch self {
        case .whiteListAdded(let user, let wkcb, let bndl):
            return self.withWL()(user, wkcb, bndl)
        case .withoutWhiteList(let user, let wkcb, let bndl):
            return self.withoutWL()(user, wkcb, bndl)
        }
    }

    func withWL() -> (User, WebKitContentBlocker, Bundle?) -> SingleRawRulesOptional
    {
        { user, wkcb, bndl in
            wkcb.rawRules(customBundle: bndl)(user)
                .flatMap { raw -> SingleRawRulesOptional in
                    guard let rules = raw else { return Fail(error: ABPBlockListError.badRulesRaw).eraseToAnyPublisher() }
                    do {
                        return try SinglePublisher(WhiteListAdder().wlAdded(rules, user, wkcb)).eraseToAnyPublisher()
                    } catch let err { return Fail(error: err).eraseToAnyPublisher() }
                }.eraseToAnyPublisher()
        }
    }

    func withoutWL() -> (User, WebKitContentBlocker, Bundle?) -> SingleRawRulesOptional
    {
        { user, wkcb, bndl in
            #if ABPDEBUG
            return wkcb.rawRules(customBundle: bndl)(user)
                .flatMap { raw -> SingleRawRulesOptional in
                    guard let rules = raw else { return Fail(error: ABPBlockListError.badRulesRaw).eraseToAnyPublisher() }
                    var copy = rules
                    do {
                        try wkcb.openJSONArray(&copy)
                    } catch let err { return Fail(error: err).eraseToAnyPublisher() }
                    return SinglePublisher(copy
                        .appending(Constants.blocklistRuleSeparator)
                        .appending(wkcb.hostAppTestRuleString(aaEnabled: user.acceptableAdsInUse()))
                        .appending(Constants.blocklistArrayEnd)).eraseToAnyPublisher()
                }.eraseToAnyPublisher()
            #else
            return wkcb.rawRules(customBundle: bndl)(user).eraseToAnyPublisher()
            #endif
        }
    }
}

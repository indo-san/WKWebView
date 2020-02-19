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

@available(iOS 11.0, macOS 10.13, *)
protocol WhiteListAddable {
    func withoutWL() -> (User, WebKitContentBlocker, Bundle?) -> SingleRawRulesOptional
    func withWL() -> (User, WebKitContentBlocker, Bundle?) -> SingleRawRulesOptional
}

/// For adding a WL rule given a User state with whitelisted domains.
@available(iOS 11.0, macOS 10.13, *)
struct WhiteListAdder {
    let wlAdded: (String, User, WebKitContentBlocker) throws -> String = { rules, user, wkcb in
        var copy = rules
        try wkcb.openJSONArray(&copy)
        let wlRule = try wkcb.whiteListRuleStringForUser()(user)
        #if ABPDEBUG
        return copy
            .appending(Constants.blocklistRuleSeparator)
            .appending(wkcb.hostAppTestRuleString(aaEnabled: user.acceptableAdsInUse()))
            .appending(Constants.blocklistRuleSeparator)
            .appending(wlRule)
            .appending(Constants.blocklistArrayEnd)
        #else
        return copy
            .appending(Constants.blocklistRuleSeparator)
            .appending(wlRule)
            .appending(Constants.blocklistArrayEnd)
        #endif
    }
}

/// For handling rules before they are loaded into WebKit.
/// * Includes addition of a special debugging rule to distinguish content
///   blocking states in builds defined with ABPDEBUG.
///
/// String copy is used during WL processing.
@available(iOS 11.0, macOS 10.13, *)
enum RulesBeforeWK: WhiteListAddable {
    case withoutWhiteList(User, WebKitContentBlocker, Bundle?)
    case whiteListAdded(User, WebKitContentBlocker, Bundle?)

    init(user: User, withNoWhitelist: Bool = false, wkcb: WebKitContentBlocker, bundle: Bundle? = nil) {
        if !withNoWhitelist && user.whitelistedDomains?.count ?? 0 > 0 {
            self = .whiteListAdded(user, wkcb, bundle)
            return
        }
        self = .withoutWhiteList(user, wkcb, bundle)
    }
}

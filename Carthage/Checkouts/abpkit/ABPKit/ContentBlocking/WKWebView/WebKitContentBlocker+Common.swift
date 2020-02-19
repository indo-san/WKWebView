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

@available(OSXApplicationExtension 10.13, *)
extension WebKitContentBlocker {
    /// Mutative operation on JSON text to allow appending array elements.
    /// * Performed in place to increase performance.
    /// * Fails after `fail` characters have been evaluated.
    func openJSONArray(_ rules: inout String, _ count: Int = 1, _ fail: Int = 10) throws {
        if count > fail { throw ABPBlockListError.failedJSONArrayOpen }
        if rules.popLast() != Character(Constants.blocklistArrayEnd) {
            try openJSONArray(&rules, count + 1)
        }
    }

    /// This is the actively used function for production frameworks.
    func whiteListRuleStringForUser() -> (User) throws -> String {
        { user in
            guard let dmns = user.whitelistedDomains, dmns.count > 0 else { throw ABPUserModelError.badDataUser}
            let userWLRuleString: (User) throws -> String = { user in
                let encoded = try String(
                    data: JSONEncoder()
                        .encode(ContentBlockerUtility()
                            .whiteListRuleForDomains()(dmns)),
                    encoding: Constants.blocklistEncoding)
                if let ruleString = encoded {
                    return ruleString
                } else { throw ABPUserModelError.badDataUser }
            }
            return try userWLRuleString(user)
        }
    }
}

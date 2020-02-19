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
extension WebKitContentBlocker {
    /// Add a CB rule for testing AA states in the ABPKit demo host apps.
    func hostAppTestRuleString(aaEnabled: Bool) -> String {
        let domain = "adblockplus.org"
        let selectorLarge = "#intro-graphic-large"
        let selectorSmall = "#intro-graphic-small"
        var actionType = ""
        switch aaEnabled {
        case true:
            actionType = "ignore-previous-rules"
        case false:
            actionType = "css-display-none"
        }
        let esc: (String) -> String = {
            $0.replacingOccurrences(of: "\\", with: "\\\\", options: .literal, range: nil)
        }
        return #"""
             {
               "trigger": {
                 "url-filter": "\#(esc(Constants.domainWrapLeader))\#(domain)\#(esc(Constants.domainWrapTrailer))",
                 "url-filter-is-case-sensitive": true
               },
               "action": {
                 "type": "\#(actionType)",
                 "selector": "\#(selectorLarge), \#(selectorSmall)"
               }
             }
        """#
    }
}

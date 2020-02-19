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

// Work In Progress for Combine.

extension ABPWebViewBlocker
{
    /// Activate bundled or downloaded rule list, as needed.
    /// * Requires a persisted User to be available.
    /// * Compilation can be forced when a new list will be loaded.
    /// - parameter forceCompile: Rule compilation will happen (optional).
    /// - parameter logCompileTime: For logging rule compile time if true (optional).
    /// - parameter logBlockListSwitchDL: For logging BL switching after downloading (optional).
    /// - parameter completeWith: Handle completion.
    public
    func useContentBlocking(forceCompile: Bool = false,
                            logCompileTime: Bool = false,
                            logBlockListSwitchDL: (() -> Void)? = nil,
                            completeWith: @escaping (Error?) -> Void)
    {
        do {
            user = try lastUser() // load user state
        } catch let err { completeWith(err); return }
        fatalError("Work In Progress")
    }

    /// For extra performance, rules are not validated or counted before loading. This function
    /// provides that service. In general, rules validation should be handled at the server level
    /// and additional validation will be unneeded under most conditions.
    /// - parameter completion: Callback that gives a struct containing rules validation results.
    public
    func validateRules(user: User, completion: @escaping (Result<RulesValidation, Error>) -> Void)
    {
        completion(.failure(ABPDummyError.workInProgress))
    }

    // swiftlint:disable unused_closure_parameter
    /// Synchronize the WK rule store while returning a given added rule list.
    ///
    /// Optionality of rule list, for this one and all related usages, can be removed once a nil
    /// condition is not used to check remote DLs.
    func historySyncForAdded() -> (WKContentRuleList?) -> SingleRuleListOptional
    {
        { list in
            guard let added = list else { return SinglePublisher(nil).eraseToAnyPublisher() }
            return self.wkcb.syncHistoryRemovers(target: .userBlocklistAndHistory)(self.user) // one or more removes
                .flatMap { remove -> SingleRuleListID in
                    remove
                }
                .flatMap { removed -> SingleRuleListOptional in
                    SinglePublisher(added).eraseToAnyPublisher()
                }.eraseToAnyPublisher()
        }
    }
    // swiftlint:enable unused_closure_parameter

    /// Add rules from user's history or user's blocklist.
    /// If a DL needs to happen, this function returns early. This will be refactored in future
    /// revisions to not be required. The intention is to treat existing lists the same as future
    /// (not yet DL) lists.
    func fromExistingOrNewRuleList(forceCompile: Bool = false,
                                   logCompileTime: Bool = false) -> SingleRuleListOptional
    {
        rulesAdded(rhc: .usersBlockList, logCompileTime: logCompileTime)(user)
    }

    /// Loads rules (from the user's BL) into the user content controller.
    /// History sync returning multiple observables can be handled with takeLast(1).
    func blockListableCCAdded() -> (User) -> SingleRuleListOptional
    {
        { usr in
            if let blst = usr.getBlockList() {
                return self.contentControllerAddBlocklistable(clear: true)(blst)
                    .flatMap { added -> SingleRuleListOptional in
                        self.historySyncForAdded()(added)
                    }.eraseToAnyPublisher()
            } else { return SinglePublisher(nil).eraseToAnyPublisher() }
        }
    }

    /// Initiate a download when needed.
    /// The user state blocklist is switched to a **placeholder** remote source with the AA state of
    /// the user passed in so that the downloader knows how to proceed. The eventual `BlockList`
    /// resulting from the download will be a different one.
    /// - returns: A user state after downloads.
    func withRemoteBLNewDownloader(_ aaInUse: Bool) -> SingleUser
    {
        Fail(error: ABPDummyError.workInProgress).eraseToAnyPublisher()
    }
}

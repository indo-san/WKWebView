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
extension ABPWebViewBlocker
{
    enum RuleHandlingCondition
    {
        case usersBlockList
        case existing(BlockList)
    }

    /// Handle adding block list rules.
    func rulesAdded(rhc: RuleHandlingCondition, logCompileTime: Bool = false) -> (User) -> SingleRuleListOptional
    {
        { usr in
            let compileAndAdd: () -> SingleRuleListOptional = {
                // The following use of self.user is required for correct operation:
                self.wkcb.rulesAddedWKStore(user: self.user, initiator: .userAction, logCompileTime: logCompileTime)
                    .flatMap { _ -> SingleRuleListOptional in
                        self.blockListableCCAdded()(self.user)
                    }
                    .last()
                    .flatMap { rlst -> SingleRuleListOptional in
                        SinglePublisher(rlst).eraseToAnyPublisher()
                    }.eraseToAnyPublisher()
            }
            let addExisting: (BlockList) -> SingleRuleListOptional = { existing in
                    // Set the new BL for the user:
                    do {
                        self.user = try self.user.blockListSet()(existing).saved()
                    } catch let err { return Fail(error: err).eraseToAnyPublisher() }
                    return self.contentControllerAddBlocklistable(clear: true)(existing)
                        .flatMap { rlst -> SingleRuleListOptional in
                            self.historySyncForAdded()(rlst)
                        }
                        .last()
                        .flatMap { rlst -> SingleRuleListOptional in
                            SinglePublisher(rlst).eraseToAnyPublisher()
                        }.eraseToAnyPublisher()
            }
            switch rhc {
            case .usersBlockList:
                return compileAndAdd()
            case .existing(let blst):
                return addExisting(blst)
            }
        }
    }
}

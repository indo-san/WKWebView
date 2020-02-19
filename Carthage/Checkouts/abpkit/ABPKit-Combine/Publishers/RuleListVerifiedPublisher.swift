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

/// Should be suscribed on main thread.
///
/// In WebKit, compileContentRuleList was found to be not
/// thread-safe. It requires being called from main even though it
/// runs on a different thread.
struct RuleListVerifiedPublisher<U: BlockListable>: Publisher
{
    typealias Output = WKContentRuleList
    typealias Failure = Error

    let ids: [String]?
    let userList: U?
    let ruleList: WKContentRuleList
    let wkcb: WebKitContentBlocker

    func receive<S>(subscriber: S)
    where S: Subscriber, RuleListVerifiedPublisher.Failure == S.Failure, RuleListVerifiedPublisher.Output == S.Input
    {
        if let ulst = userList,
            ulst.name != ruleList.identifier ||
            ids?.contains(ulst.name) == false {
                subscriber.receive(completion: .failure(ABPWKRuleStoreError.invalidRuleData))
            }
        wkcb.logWith?(ids)
        _ = subscriber.receive(ruleList)
        subscriber.receive(completion: .finished)
    }
}

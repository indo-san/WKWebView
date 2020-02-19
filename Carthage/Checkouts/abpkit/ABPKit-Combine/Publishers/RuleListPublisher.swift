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
struct RuleListPublisher: Publisher
{
    typealias Output = WKContentRuleList
    typealias Failure = Error

    let logCompileTime: Bool = false
    let identifier: String?
    let rules: String
    let wkcb: WebKitContentBlocker

    func receive<S>(subscriber: S)
    where S: Subscriber, RuleListPublisher.Failure == S.Failure, RuleListPublisher.Output == S.Input
    {
        guard Thread.isMainThread else { subscriber.receive(completion: .failure(ABPSchedulerError.notOnMain)); return }
        let start = Date() // only for compile time logging
        wkcb.rulesStore
            .compileContentRuleList(forIdentifier: identifier, encodedContentRuleList: rules) { list, err in
                if self.logCompileTime { log("⏱️ cmpl \(fabs(start.timeIntervalSinceNow)) - (\(self.identifier as String?)") }
                guard err == nil else { subscriber.receive(completion: .failure(err!)); return }
                if list != nil {
                    _ = subscriber.receive(list!)
                    subscriber.receive(completion: .finished)
                }
            }
    }
}

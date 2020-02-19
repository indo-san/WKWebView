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

struct ListRemovedFromStorePublisher: Publisher
{
    typealias Output = String
    typealias Failure = Error

    let identifier: String
    /// For debugging. Can be nil otherwise.
    let withID: ((String) -> Void)?
    let wkcb: WebKitContentBlocker

    func receive<S>(subscriber: S)
    where S: Subscriber, ListRemovedFromStorePublisher.Failure == S.Failure, ListRemovedFromStorePublisher.Output == S.Input
    {
        wkcb.rulesStore
            .removeContentRuleList(forIdentifier: identifier) { err in
                self.withID?(self.identifier)
                // Remove for identifier operation is complete at this point.
                if err != nil {
                    if let wkErr = err as? WKError, wkErr.code == .contentRuleListStoreRemoveFailed {
                        _ = subscriber.receive("") // ignore error
                        subscriber.receive(completion: .finished)
                    } else { subscriber.receive(completion: .failure(err!)) }
                }
                _ = subscriber.receive(self.identifier)
                subscriber.receive(completion: .finished)
            }
    }
}

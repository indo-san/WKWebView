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

/// Delivers an array of available identifiers, if they exist.
struct RuleListIdentifiersPublisher: Publisher
{
    typealias Output = [String]?
    typealias Failure = Error

    let wkcb: WebKitContentBlocker

    func receive<S>(subscriber: S)
    where S: Subscriber, RuleListIdentifiersPublisher.Failure == S.Failure, RuleListIdentifiersPublisher.Output == S.Input
    {
        wkcb.rulesStore
            .getAvailableContentRuleListIdentifiers { ids in
                _ = subscriber.receive(ids)
                subscriber.receive(completion: .finished)
            }
    }
}

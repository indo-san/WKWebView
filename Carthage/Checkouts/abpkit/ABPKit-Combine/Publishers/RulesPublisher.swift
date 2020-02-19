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

/// Used by the parsers to deliver encoded rules.
struct RulesPublisher: Publisher
{
    typealias Output = BlockingRule
    typealias Failure = Error

    let list: V1FilterList

    func receive<S>(subscriber: S)
    where S: Subscriber, RulesPublisher.Failure == S.Failure, RulesPublisher.Output == S.Input
    {
        var copy = list
        while !copy.container.isAtEnd {
            var rule = BlockingRule()
            do {
                let contents = try copy.container
                    .nestedContainer(keyedBy: BlockingRule.CodingKeys.self)
                if let decoded = try contents.decodeIfPresent(Trigger.self, forKey: .trigger) {
                    rule.trigger = decoded
                } else { subscriber.receive(completion: .failure(ABPBlockListParameterizedError.badRule(rule))) }
                if let decoded = try contents.decodeIfPresent(Action.self, forKey: .action) {
                    rule.action = decoded
                } else { subscriber.receive(completion: .failure(ABPBlockListParameterizedError.badRule(rule))) }
                if rule.trigger != nil && rule.action != nil {
                    _ = subscriber.receive(rule)
                }
            } catch let err { subscriber.receive(completion: .failure(err)) }
        }
        subscriber.receive(completion: .finished)
    }
}

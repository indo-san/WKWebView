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

import RxSwift

extension V1FilterList {
    /// - returns: Observable of filter list rules
    func rules() -> StreamRule {
        var mself = self // copy
        guard let container = mself.container,
              let count = container.count,
              count > 0
        else { return .empty() }
        return .create { observer in
            while !mself.container.isAtEnd {
                var rule = BlockingRule()
                do {
                    let contents = try mself.container
                        .nestedContainer(keyedBy: BlockingRule.CodingKeys.self)
                    if let decoded = try contents.decodeIfPresent(Trigger.self, forKey: .trigger) {
                        rule.trigger = decoded
                    } else { observer.onError(ABPBlockListParameterizedError.badRule(rule)) }
                    if let decoded = try contents.decodeIfPresent(Action.self, forKey: .action) {
                        rule.action = decoded
                    } else { observer.onError(ABPBlockListParameterizedError.badRule(rule)) }
                    if rule.trigger != nil && rule.action != nil {
                        observer.onNext(rule)
                    }
                } catch let err { observer.onError(err) }
            }
            observer.onCompleted()
            return Disposables.create()
        }
    }
}

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

extension LegacyFilterList {
    func filterListData(url: FilterListFileURL) -> Data? {
        guard let data = try? Data(contentsOf: url,
                                   options: .uncached)
        else { return nil }
        return data
    }

    private
    func count(_ rules: Observable<BlockingRule>) -> Observable<Int> {
        rules
            .reduce(0, accumulator: { acc, _ in
                acc + 1
            })
    }

    /// Count of rules in for a corresponding filter list.
    /// V2 filter lists are first attempted to be parsed before failing over to v1 parsing.
    /// - returns: Observable of the count while defaulting to zero on parsing failures.
    func ruleCount(bundle: Bundle = Config().bundle()) -> Observable<Int> {
        #if compiler(>=5)
            guard let rules = try? self.rulesURL(bundle: bundle) else {
                return Observable.just(0)
            }
        #else
        guard let tryRules = try? self.rulesURL(bundle: bundle), let rules = tryRules else {
            return Observable.just(0)
        }
        #endif
        let decoder = JSONDecoder()
        if let data = self.filterListData(url: rules) {
            if let list =
                try? decoder
                    .decode(V2FilterList.self, from: data) {
                return count(list.rules())
            } else if let list =
                try? decoder
                    .decode(V1FilterList.self, from: data) {
                return count(list.rules())
            }
        }
        return Observable.just(0)
    }
}

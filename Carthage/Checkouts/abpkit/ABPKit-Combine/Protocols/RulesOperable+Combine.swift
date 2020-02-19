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

/// Some operations related to accessing content blocking rules.
protocol RulesOperable
{
    func rulesURL(customBundle: Bundle?) throws -> URL?
    func rawRulesString() -> (URL?) -> SingleRawRulesOptional
    func decodedRulesFromURL() -> (URL?) throws -> StreamRule
}

extension RulesOperable where Self: BlockListDownloadable
{
    private
    func rawRulesData() -> (URL?) throws -> SingleData
    {
        {
            if $0 == nil { return Fail(error: ABPFilterListError.badSource).eraseToAnyPublisher() }
            if let data = FileManager.default.contents(atPath: ($0!.path)) {
                return SinglePublisher(data).eraseToAnyPublisher()
            }
            return Fail(error: ABPFilterListError.badSource).eraseToAnyPublisher()
        }
    }

    /// - returns: Observable of raw JSON content blocking rules or an empty JSON array.
    func rawRulesString() -> (URL?) -> SingleRawRulesOptional
    {
        {
            do {
                return try self.rawRulesData()($0)
                    .flatMap { data in
                        SinglePublisher(String(data: data, encoding: Constants.blocklistEncoding))
                    }.eraseToAnyPublisher()
            } catch let err { return Fail(error: err).eraseToAnyPublisher() }
        }
    }

    /// Subsequent encoding via Codable may not be time efficient wrt reduce operations. This may be
    /// due to unoptimized complexity within the ABPKit implementation and/or a consequence of using
    /// Codable, known to not offer as high performance as other methods.
    /// - returns: Observable of parsed CB rules.
    func decodedRulesFromURL() -> (URL?) throws -> StreamRule
    {
        {
            if $0 == nil { return Fail(error: ABPFilterListError.badSource).eraseToAnyPublisher() }
            return try JSONDecoder().decode(V1FilterList.self, from: self.contentBlockingData(url: $0!)).rules()
        }
    }
}

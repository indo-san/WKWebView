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

@testable import ABPKit

struct BlockListOperations {
    /// For a dictionary A, check that its key-value pairs match those in dictionary B.
    /// - parameters:
    ///   - dictA: A dictionary to be compared
    ///   - dictB: A dictionary to be compared
    /// - returns: True if equal, otherwise false
    static
    func equal<T>(dictA: [T: T], dictB: [T: T]) -> Bool {
        var mismatch = false
        dictA.keys.forEach { key in
            if dictA[key] != dictB[key] { mismatch = true }
        }
        return !mismatch
    }

    /// Get filter list data.
    /// - parameter url: File URL of the data
    /// - returns: Data of the filter list
    /// - throws: ABPKitTestingError
    static
    func filterListData(url: URL) throws -> Data {
        try Data(contentsOf: url, options: .uncached)
    }

    /// Sort FilterListV2Sources based on the url key.
    /// - parameter sources: Contents of the v2 filter list sources key
    /// - returns: Sorted FilterListV2Sources
    /// - throws: ABPFilterListError
    static
    func sort(_ sources: FilterListV2Sources) throws -> FilterListV2Sources {
        try sources.sorted {
            let key = "url"
            if let valA = $0[key], let valB = $1[key] {
                return valA < valB
            } else { throw ABPFilterListError.invalidData }
        }
    }
}

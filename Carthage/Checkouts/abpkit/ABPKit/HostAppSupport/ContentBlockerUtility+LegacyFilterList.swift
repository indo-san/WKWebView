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

extension ContentBlockerUtility {
    /// Retrieve a reference (file URL) to a blocklist file in a bundle.
    /// - parameter name: The given name for a filter list.
    /// - parameter bundle: Defaults to config bundle.
    func getBundledFilterListFileURL(modelName: FilterListName,
                                     bundle: Bundle = Config().bundle()) throws -> FilterListFileURL {
        #if compiler(>=5)
        let filename = (try? LegacyFilterList(persistenceID: modelName))?.fileName
        if let url = bundle.url(forResource: filename, withExtension: "") {
            return url
        } else { throw ABPFilterListError.notFound }
        #else
        if let model = try? FilterList(persistenceID: modelName),
            let filename = model?.fileName {
            if let url = bundle.url(forResource: filename, withExtension: "") {
                return url
            } else { throw ABPFilterListError.notFound }
        }
        throw ABPFilterListError.notFound
        #endif
    }
}

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

/// Utility functions related to content blocking.
/// These support the ABP Safari iOS app.
class ContentBlockerUtility {
    var bag: DisposeBag!

    init() throws {
        bag = DisposeBag()
    }

    /// Get bundled rules by filename only.
    func getBundledFilterListFileURL(filename: String,
                                     bundle: Bundle = Config().bundle()) throws -> FilterListFileURL {
        if let url = bundle.url(forResource: filename, withExtension: "") {
            return url
        } else { throw ABPFilterListError.notFound }
    }

    func filenameFromURL(_ url: BlockListFileURL) -> BlockListFilename {
        url.lastPathComponent
    }
}

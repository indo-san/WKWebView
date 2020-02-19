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

import XCTest

class UserUtility {
    let lastUser: (Bool) -> User? = {
        do {
            let user = try User(fromPersistentStorage: $0)
            if user != nil { return user! }
        } catch let err { XCTFail("Error: \(err)") }
        return nil
    }

    let aaUserNewSaved: (BlockListSourceable) throws -> User? = {
        try User(
            fromPersistentStorage: false,
            withBlockList: BlockList(
                withAcceptableAds: true,
                source: $0,
                initiator: .userAction))?.saved()
    }
}

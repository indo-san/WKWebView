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

class BlockListModelTests: XCTestCase {
    override
    func setUp() {
        super.setUp()
        try? Persistor().clearRulesFiles()
    }

    func bundleToUse() -> Bundle? {
        Bundle(for: BlockListModelTests.self)
    }

    func testMakeBlockListWithSources() throws {
        var blst: BlockList!
        blst = try BlockList(withAcceptableAds: false, source: BundledBlockList.easylist, initiator: .userAction)
        XCTAssert(try encDecBlocklist(blst).source as? BundledBlockList == .easylist, "Bad source.")
        blst = try BlockList(withAcceptableAds: true, source: BundledBlockList.easylistPlusExceptions, initiator: .userAction)
        XCTAssert(try encDecBlocklist(blst).source as? BundledBlockList == .easylistPlusExceptions, "Bad source.")
        blst = try BlockList(withAcceptableAds: false, source: RemoteBlockList.easylist, initiator: .userAction)
        XCTAssert(try encDecBlocklist(blst).source as? RemoteBlockList == .easylist, "Bad source.")
        blst = try BlockList(withAcceptableAds: true, source: RemoteBlockList.easylistPlusExceptions, initiator: .userAction)
        XCTAssert(try encDecBlocklist(blst).source as? RemoteBlockList == .easylistPlusExceptions, "Bad source.")
    }

    func testBundledRules() throws {
        if let user = try User(
            fromPersistentStorage: false,
            withBlockList: BlockList(
                withAcceptableAds: false,
                source: BundledTestingBlockList.testingEasylist,
                initiator: .userAction)) {
                    return try XCTAssert(user.rulesURL(customBundle: bundleToUse()) != nil, "Bad rules")
                }
        XCTFail("Bad user.")
    }

    func testBundledRulesToFile() throws {
        try XCTAssert(LegacyRulesHelper().rulesForFilename()(
            FilterListTestModeler().makeLocalBlockList().name
                .addingFileExtension(Constants.rulesExtension)) != nil,
            "Bad rules")
    }

    private
    func encDecBlocklist(_ source: BlockList) throws -> BlockList {
        try PropertyListDecoder()
            .decode(BlockList.self, from: PropertyListEncoder().encode(source))
    }
}

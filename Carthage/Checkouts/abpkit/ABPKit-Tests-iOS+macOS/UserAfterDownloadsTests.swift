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

import RxSwift
import XCTest

/// Tests future user states.
class UserAfterDownloadsTests: XCTestCase {
    let testSource = RemoteBlockList.self
    let timeout: TimeInterval = 10
    var bag: DisposeBag!
    var user: User!

    override
    func setUp() {
        super.setUp()
        bag = DisposeBag()
        do {
            try Persistor().clearRulesFiles()
            user = try UserUtility().aaUserNewSaved(testSource.easylistPlusExceptions)
        } catch let err { XCTFail("Error: \(err)") }
    }

    /// Integration test:
    func testUserAfterDL() throws {
        let expect = expectation(description: #function)
        let expectedDLs = 1
        let start = user // copy
        let lastUser = UserUtility().lastUser
        DownloadUtility().downloadForUser(
            lastUser,
            afterUserSavedTest: { saved in
                // User BL not updated after DLs:
                if let savedBL = saved.blockList {
                    // Compare a single block list:
                    XCTAssert(saved.blockList == start?.blockList, "Bad blocklist of \(savedBL).")
                } else { XCTFail("Missing block list.") }
                XCTAssert(saved.downloads?.count == expectedDLs, "Bad count: Got \(saved.downloads?.count as Int?), expected \(expectedDLs).")
                XCTAssert(saved.name == start?.name, "Bad user.")
                let updated = try? BlockListDownloader(user: saved)
                    .userBlockListUpdated()(saved)
                if let dls = updated?.downloads, let blst = updated?.blockList {
                    XCTAssert(dls.contains(blst), "List not found: Expected \(blst).")
                } else { XCTFail("Missing lists.") }
            },
            withCompleted: { expect.fulfill() }).disposed(by: bag)
        wait(for: [expect], timeout: timeout)
    }

    func testUserAfterDLWithError() throws {
        let expect = expectation(description: #function)
        let mockError = ABPDownloadTaskError.failedMove
        BlockListDownloader(user: user)
            .afterDownloads(initiator: .userAction)(MockEventer(error: mockError).mockObservable())
            .subscribe(onNext: { (_: User) in // empty except for annotation
            }, onError: { err in
                XCTAssert(err as? ABPDownloadTaskError == mockError, "Bad error.")
                expect.fulfill()
            }).disposed(by: bag)
        wait(for: [expect], timeout: timeout)
    }
}

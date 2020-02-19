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
import WebKit
import XCTest

class TestHost: ABPBlockable {
    var webView: WKWebView!
}

class WebViewBlockerHostTests: XCTestCase {
    let testSource = RemoteBlockList.self
    let timeout: TimeInterval = 20
    var bag: DisposeBag!
    var blocker: ABPWebViewBlocker!
    var testHost: TestHost!
    var user: User!

    private
    func bundleToUse() -> Bundle? {
        Bundle(for: WebViewBlockerHostTests.self)
    }

    override
    func setUp() {
        super.setUp()
        bag = DisposeBag()
        testHost = TestHost()
        testHost.webView = WKWebView()
        do {
            if let testUser = try User(
            fromPersistentStorage: true,
            withBlockList: BlockList(
                withAcceptableAds: false,
                source: BundledTestingBlockList.testingEasylist,
                initiator: .userAction)) {
                    user = try testUser.saved()
                } else { XCTFail("Bad user.") }
            blocker = try ABPWebViewBlocker(host: testHost)
        } catch let err { XCTFail(err.localizedDescription) }
    }

    /// Verify the error for an unexpected web view deallocation
    /// during setup of content blocking for a given WKWebView.
    func testDeallocatedWebView() throws {
        let expect = expectation(description: #function)
        testHost.webView = nil
        var blst = self.user.getBlockList()
        // The following operation chain tests all of the paths of RuleHandlingCondition.
        blocker.rulesAdded(rhc: .usersBlockList, customBundle: bundleToUse())(user)
            .flatMap { _ -> SingleRuleListOptional in
                blst = self.user.getBlockList()
                XCTAssert(blst != nil, "Block list is nil.")
                return self.blocker.rulesAdded(rhc: .existing(blst!), customBundle: self.bundleToUse())(self.user)
            }
            .subscribe(onError: {
                XCTFail("Unexpected error: \($0.localizedDescription)")
            }, onCompleted: {
                expect.fulfill()
            }).disposed(by: bag)
        wait(for: [expect], timeout: timeout)
    }
}

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

class UserRulesTests: XCTestCase {
    let testCount = 21475
    var bag: DisposeBag!
    var user: User!

    override
    func setUp() {
        super.setUp()
        bag = DisposeBag()
        do {
            user = try User()
            user.blockList =
                try BlockList(
                    withAcceptableAds: false,
                    source: BundledTestingBlockList.testingEasylist,
                    initiator: .userAction)
        } catch let err { XCTFail("Error: \(err)") }
    }

    func bundleToUse() -> Bundle? {
        Bundle(for: UserRulesTests.self)
    }

    func testRawRulesString() throws {
        let rules = try user.rawRulesString()(user.rulesURL(customBundle: bundleToUse()))
        rules
            .subscribe(onNext: {
                XCTAssert($0 != nil, "Bad string.")
            }, onError: { XCTFail("Error: \($0)") })
            .disposed(by: bag)
    }

    /// Test time efficiency of Codable rules handling for counting only.
    func testRulesValidatedCount() throws {
        let rules = try user.decodedRulesFromURL()(user.rulesURL(customBundle: bundleToUse()))
        let start = Date()
        rules
            // Encode/Decode within reduce causes unacceptable performance:
            .reduce(0) { acc, _ in acc + 1 }
            .subscribe(onNext: { cnt in
                let end = fabs(start.timeIntervalSinceNow)
                XCTAssert(self.testCount == cnt, "Bad count.")
                log("🔢 cnt \(cnt), ⏱️ \(end)")
            }, onError: { XCTFail("Error: \($0)") })
            .disposed(by: bag)
    }

    func testCountedRules() throws {
        let wkcb = WebKitContentBlocker()
        XCTAssert(wkcb != nil, "Bad WebKitContentBlocker.")
        let start = Date()
        wkcb!.countedRules(customBundle: bundleToUse())(user)
            .subscribe(onNext: {
                let end = fabs(start.timeIntervalSinceNow)
                log("🔢 cnt \($0.1), ⏱️ \(end)")
            }, onError: { XCTFail("Error: \($0)")})
            .disposed(by: bag)
    }
}

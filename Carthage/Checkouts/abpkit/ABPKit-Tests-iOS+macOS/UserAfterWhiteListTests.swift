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

import RxBlocking
import RxRelay
import RxSwift
import WebKit
import XCTest

/// Tests future user states.
class UserAfterWhiteListTests: XCTestCase {
    let testSource = RemoteBlockList.self
    let lastUser = UserUtility().lastUser
    let timeout: TimeInterval = 5
    var bag: DisposeBag!
    var user: User!
    var wkcb: WebKitContentBlocker!
    var expectedCount: Int?
    /// Test domains.
    let domains: (_ expectedCount: inout Int) throws -> [String] = { expCnt in
        guard let arr = RandomStateUtility().randomState(for: [String].self) else {
            throw ABPKitTestingError.invalidData
        }
        expCnt = arr.count
        return arr
    }

    override
    func setUp() {
        super.setUp()
        bag = DisposeBag()
        do {
            try Persistor().clearRulesFiles()
            user = try UserUtility().aaUserNewSaved(testSource.easylistPlusExceptions)
        } catch let err { XCTFail("Error: \(err)") }
        wkcb = WebKitContentBlocker()
        let unlock = BehaviorRelay<Bool>(value: false)
        wkcb.ruleListAllClearers()
            .subscribe(onError: { err in
                XCTFail("Error: \(err)")
            }, onCompleted: {
                unlock.accept(true)
            }).disposed(by: bag)
        let waitDone = try? unlock.asObservable()
            .skip(1)
            .toBlocking(timeout: timeout / 2.0)
            .first()
        XCTAssert(waitDone == true, "Failed to clear rules.")
    }

    func testMakeWhiteListRuleForDomains() throws {
        user.whitelistedDomains = RandomStateUtility().randomState(for: [String].self)
        let rule = try ContentBlockerUtility().whiteListRuleForUser()(user)
        XCTAssert(rule.trigger?.ifTopURL?.count == user.whitelistedDomains?.count, "Bad count.")
    }

    /// Variations of domain naming wrt regex domain wrapping.
    func testDomainMatch() throws {
        let factor = 7,
            valid = 4,
            domain = "example.com",
            schemes = ["http", "https", "ftp", "sftp"],
            ports = ["", ":80", ":8080"],
            domains = [
                "example.com",
                "www.example.com",
                "www.xxx.example.com",
                "www.xxx.yyy.example.com",
                "example.co",
                "xample.com",
                "aexample.com",
                "example.com.us",
                "example.not.com",
                "www.examples.com"
            ],
            paths = ["", "page.html", "example.com.html"],
            queries = ["", "?param=0", "?param1=0&param2=0", "?param=example.com", "?param=100%%25"],
            fragments = ["", "#example.com"]
        // Separated range function due to swiftc 5.0.1 unable to handle the complexity
        // in `count`.
        let range: (String) -> NSRange = { NSRange(location: 0, length: $0.count) }
        let validCount = try {
            try self.multiplied()(domains, 1, factor)
                .map {
                    schemes[Int.random(in: 0...schemes.count - 1)] +
                    "://" + $0 + ports[Int.random(in: 0...ports.count - 1)] +
                    "/" + paths[Int.random(in: 0...paths.count - 1)] +
                    queries[Int.random(in: 0...queries.count - 1)] +
                    fragments[Int.random(in: 0...fragments.count - 1)]
                }
                .filter {
                    try NSRegularExpression(
                        pattern: ContentBlockerUtility()
                            .whiteListRuleForUser()(self.user.whiteListedDomainsSet()([domain]))
                            .trigger?.ifTopURL?.first ?? "",
                        options: .caseInsensitive)
                        .matches(in: $0, options: [], range: range($0))
                        .count > 0
                }
                .count
        }()
        XCTAssert(validCount == valid * factor, "Bad match count of \(validCount), expected \(valid * factor).")
    }

    func testMultiDomainRuleToList() throws {
        let expect = expectation(description: #function)
        user.blockList = try BlockList(
            withAcceptableAds: true,
            source: BundledTestingBlockList.fakeExceptions,
            initiator: .userAction)
        let name = "user-whitelist"
        user.whitelistedDomains = RandomStateUtility().randomState(for: [String].self)
        let cbUtil = try ContentBlockerUtility()
        let whitelistRuleAddForUser: (User) -> Observable<WKContentRuleList> = { user in
            guard let dmns = user.whitelistedDomains else { return .error(ABPUserModelError.badDataUser) }
            let rule = cbUtil.whiteListRuleForDomains()(dmns)
            XCTAssert(rule.trigger?.ifTopURL?.count == dmns.count, "Bad count.")
            return self.wkcb.rawRules(customBundle: Bundle(for: UserAfterWhiteListTests.self))(user)
                .flatMap { result -> Observable<WKContentRuleList> in
                    if let rules = result {
                        return self.wkcb.rulesCompiledForIdentifier(name)(rules)
                    }
                    return .error(ABPBlockListError.badRulesRaw)
                }
        }
        whitelistRuleAddForUser(user)
            .subscribe(
                onError: { XCTFail("Error: \($0)") },
                onCompleted: { expect.fulfill() }
            ).disposed(by: bag)
        wait(for: [expect], timeout: timeout * 3)
    }

    /// Produce factor * number of array elements.
    private
    func multiplied() -> ([String], Int, Int) -> [String] {
        { arr, curr, factor in
            if curr >= factor { return arr }
            return arr + self.multiplied()(arr, curr + 1, factor)
        }
    }
}

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

class ContentBlockerUtilityTests: XCTestCase {
    let timeout: TimeInterval = 5
    let whitelistDomains =
        ["test1.com",
         "test2.com",
         "test3.com"]
    var bag: DisposeBag!
    var testingFile: URL?
    var cbUtil: ContentBlockerUtility!

    override
    func setUp() {
        super.setUp()
        bag = DisposeBag()
        do {
            cbUtil = try ContentBlockerUtility()
        } catch let err { XCTFail("Error: \(err)") }
    }

    override
    func tearDown() {
        if testingFile != nil { removeFile(testingFile!) }
        super.tearDown()
    }

    func testMakeWhitelistRules() throws {
        let max = Int.random(in: 100...1000)
        let actionType = "ignore-previous-rules"
        let loadType = ["first-party", "third-party"]
        let testDomains = domains(1, max, [])
        do {
            let data = try JSONEncoder().encode(cbUtil.whiteListRuleForDomains()(testDomains))
            let decoded: BlockingRule = try JSONDecoder().decode(BlockingRule.self, from: data)
            XCTAssert(decoded.action?.selector == nil, "Bad action selector.")
            XCTAssert(decoded.action?.type == actionType, "Bad action type.")
            XCTAssert(Set(decoded.trigger?.ifTopURL ?? []) == Set(testDomains.map { cbUtil.wrappedDomain()($0) }), "Bad trigger ifTopURL.")
            XCTAssert(Set(decoded.trigger?.loadType ?? []) == Set(loadType), "Bad trigger loadType.")
            XCTAssert(decoded.trigger?.resourceType == nil, "Bad trigger resourceType.")
            XCTAssert(decoded.trigger?.unlessTopURL == nil, "Bad trigger unlessDomain.")
            XCTAssert(decoded.trigger?.urlFilterIsCaseSensitive == false, "Bad trigger urlFilterIsCaseSensitive.")
        } catch let error { XCTFail("Bad rule with error: \(error)") }
    }

    // ------------------------------------------------------------
    // MARK: - Private -
    // ------------------------------------------------------------

    private
    func localTestFilterListRules() throws -> BlockListFileURL {
        var list = try LegacyFilterList()
        list.name = "test-v1-easylist-short"
        list.fileName = "test-v1-easylist-short.json"
        // Adding a list for testing to the relay does not work because the host
        // app loads its own lists into the relay.
        try Persistor().saveFilterListModel(list)
        if let url = try list.rulesURL(bundle: Bundle(for: ContentBlockerUtilityTests.self)) {
            return url
        } else { throw ABPFilterListError.missingRules }
    }

    private
    func ruleCount(rules: Data,
                   completion: @escaping (Int) -> Void) {
        var cnt = 0
        do {
            try JSONDecoder().decode(V1FilterList.self, from: rules).rules()
                .subscribe(onNext: { _ in
                    cnt += 1
                }, onError: { error in
                    XCTFail("Failed with error: \(error)")
                }, onCompleted: {
                    completion(cnt)
                }).disposed(by: bag)
        } catch let error { XCTFail("Failed with error: \(error)") }
    }

    private
    func removeFile(_ fileURL: URL) {
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch let err { XCTFail("Remove failed for: \(fileURL)) with error: \(err)"); return }
    }

    private
    func domains(_ cnt: Int, _ max: Int, _ arr: [String]) -> [String] {
        if cnt >= max { return arr }
        return domains(cnt + 1, max, arr + ["test\(cnt).com"])
    }
}

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

import Combine
import XCTest

@available(iOS 13.0, *)
class CombineParsingTests: XCTestCase {
    /// Expected v2 expires
    let testingExpires = "4 days"
    /// Expected number of test rules.
    let testingRuleCount = 7
    let testingSources: FilterListV2Sources =
        [["version": "201812121930",
          "url": "https://easylist-downloads.adblockplus.org/easylist_noadult.txt"]]
    /// Expected v2 version.
    let testingVersion = "201812121930"
    var v1FileURL: URL!
    var v2FileURL: URL!
    var v2PartialFileURL: URL!

    /// V2 test cases.
    enum V2ParseTestType: String,
                          CaseIterable {
        case short
        case partial
    }

    override
    func setUp() {
        super.setUp()
        let util = TestingFileUtility()
        v1FileURL = util.fileURL(resource: "test-v1-easylist-short", ext: Constants.rulesExtension)
    }

    /// Test parsing v1 filter lists.
    func testParsingV1FilterList() {
        guard let url = v1FileURL else { XCTFail("Missing url"); return }
        let decoder = JSONDecoder()
        do {
            let list = try decoder.decode(V1FilterList.self, from: BlockListOperations.filterListData(url: url))
            var rules = [BlockingRule]()
            let listRules: AnyPublisher<BlockingRule, Error> = list.rules()
            _ = listRules.sink(
                receiveCompletion: { cmpl in
                    switch cmpl {
                    case .failure(let err):
                        XCTFail("Error: \(err)")
                    case .finished:
                        break
                    }
                },
                receiveValue: { rules.append($0) })
            XCTAssert(rules.count == testingRuleCount, "Wrong rule count")
        } catch let error { XCTFail("Decode failed with error: \(error)") }
    }

    private
    func runV2ParsingTest(type: V2ParseTestType) {
        var url: URL!
        switch type {
        case .short:
            url = v2FileURL
        case .partial:
            url = v2PartialFileURL
        }
        let decoder = JSONDecoder()
        do {
            let list = try decoder.decode(V2FilterList.self, from: BlockListOperations.filterListData(url: url))
            var rules = [BlockingRule]()
            let listRules: AnyPublisher<BlockingRule, Error> = list.rules()
            _ = listRules.sink(
                receiveCompletion: { cmpl in
                    switch cmpl {
                    case .failure(let err):
                        XCTFail("Error: \(err)")
                    case .finished:
                        break
                    }
                },
                receiveValue: { rules.append($0) })
            XCTAssert(rules.count == testingRuleCount, "Wrong rule count")
            XCTAssert(list.expires == testingExpires, "Wrong expires")
            XCTAssert(list.version == testingVersion, "Wrong version")
            XCTAssert(testingSources.count == list.sources?.count, "Wrong sources count")
            for idx in try 0...BlockListOperations.sort(testingSources).count - 1 {
                try XCTAssertTrue(BlockListOperations.equal(
                        dictA: BlockListOperations.sort(testingSources)[idx],
                        dictB: BlockListOperations.sort(list.sources ?? [])[idx]),
                    "Wrong sources")
            }
        } catch let err { if [.short].contains(type) { XCTFail("Decode failed with error: \(err)") } }
    }
}

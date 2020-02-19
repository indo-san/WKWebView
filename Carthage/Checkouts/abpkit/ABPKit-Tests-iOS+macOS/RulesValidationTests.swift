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

class RulesValidationTests: XCTestCase {
    let invalidRules = {
        #"""
            [
                {
                    "invalid": "value"
                }
            ]FAILME
        """#
    }
    /// Contains a bad action.
    let rules1 = {
        #"""
            [
                {
                    "trigger": {
                        "url-filter": "example1.com",
                        "url-filter-is-case-sensitive": true
                    },
                    "action": {
                        "type": "css-display-none",
                        "selector": "#IAMGOOD",
                    }
                },
                {
                    "trigger": {
                        "url-filter": "example2.com",
                        "url-filter-is-case-sensitive": true
                    },
                    "bad_action": {
                        "type": "css-display-none",
                        "selector": "#IAMBAD",
                        "IGNOREME": ""
                    }
                }
            ]
        """#
    }
    /// All rules are valid.
    let rules2 = {
        #"""
            [
                {
                    "trigger": {
                        "url-filter": "example1.com",
                        "url-filter-is-case-sensitive": true
                    },
                    "action": {
                        "type": "css-display-none",
                        "selector": "#ad1"
                    }
                },
                {
                    "trigger": {
                        "url-filter": "example2.com",
                        "url-filter-is-case-sensitive": true
                    },
                    "action": {
                        "type": "css-display-none",
                        "selector": "#ad2"
                    }
                },
                {
                    "trigger": {
                        "url-filter": "example3.com",
                        "url-filter-is-case-sensitive": true
                    },
                    "action": {
                        "type": "block"
                    }
                }

            ]
        """#
    }
    let rulesCount1 = 2
    let rulesCount2 = 3
    let timeout: TimeInterval = 10
    var bag = DisposeBag()
    var wkcb: WebKitContentBlocker!

    override
    func setUp() {
        super.setUp()
        wkcb = WebKitContentBlocker()
        if wkcb == nil { XCTFail("Bad wkcb.") }
    }

    func testDecodingError() throws {
        let expect = expectation(description: #function)
        wkcb.validatedRulesWithRaw(rules: invalidRules())
            .subscribe {
                switch $0 {
                case .success(let rslt):
                    XCTAssert(rslt.parseSucceeded == false, "Parse was expected to fail.")
                    XCTAssert(rslt.rulesCounted == nil, "Rule count is unexpected.")
                    if rslt.error as? DecodingError == nil {
                        XCTFail("Bad error type of \(type(of: rslt.error))")
                    }
                    expect.fulfill()
                case .error(let err):
                    XCTFail("Error: \(err)")
                }
            }.disposed(by: bag)
        wait(for: [expect], timeout: timeout)
    }

    func testValidation1() throws {
        let expect = expectation(description: #function)
        wkcb.validatedRulesWithRaw(rules: rules1())
            .subscribe {
                switch $0 {
                case .success(let rslt):
                    XCTAssert(rslt.parseSucceeded == false, "Parse was expected to fail.")
                    XCTAssert(rslt.rulesCounted == nil, "Rule count is unexpected.")
                    XCTAssert(rslt.error != nil, "Didn't get an error as expected.")
                    expect.fulfill()
                case .error(let err):
                    XCTFail("Error: \(err)")
                }
            }.disposed(by: bag)
        wait(for: [expect], timeout: timeout)
    }

    func testValidation2() throws {
        let expect = expectation(description: #function)
        wkcb.validatedRulesWithRaw(rules: rules2())
            .subscribe {
                switch $0 {
                case .success(let rslt):
                    XCTAssert(rslt.parseSucceeded == true, "Parse failed.")
                    XCTAssert(rslt.rulesCounted == self.rulesCount2, "Expected \(self.rulesCount2) rules.")
                    XCTAssert(rslt.error == nil, "Error: \(rslt.error as Error?)")
                    expect.fulfill()
                case .error(let err):
                    XCTFail("Error: \(err)")
                }
            }.disposed(by: bag)
        wait(for: [expect], timeout: timeout)
    }

    func testValidateAfterRawLoad() throws {
        let expect = expectation(description: #function)
        wkcb.validatedRulesWithRaw(rules: rules1())
            .subscribe {
                switch $0 {
                case .success(let rslt):
                    XCTAssert(rslt.parseSucceeded == false, "Parse failed.")
                    XCTAssert(rslt.rulesCounted == nil, "Expected nil rules count.")
                    if rslt.error as? ABPBlockListParameterizedError == nil {
                        XCTFail("Bad error type of \(type(of: rslt.error))")
                    }
                    expect.fulfill()
                case .error(let err):
                    XCTFail("Unexpected error: \(err)")
                }
            }.disposed(by: bag)
        wait(for: [expect], timeout: timeout)
    }

    func testEmptyHandling() throws {
        let expect = expectation(description: #function)
        wkcb.validatedRulesWithRaw(rules: "")
            .subscribe {
                switch $0 {
                case .success(let rslt):
                    XCTAssert(rslt.parseSucceeded == false, "Parse failed.")
                    XCTAssert(rslt.rulesCounted == nil, "Expected nil rules count.")
                    if rslt.error as? DecodingError == nil {
                        XCTFail("Bad error type of \(type(of: rslt.error))")
                    }
                    expect.fulfill()
                case .error(let err):
                    XCTFail("Unexpected error: \(err)")
                }
            }.disposed(by: bag)
        wait(for: [expect], timeout: timeout)
    }
}

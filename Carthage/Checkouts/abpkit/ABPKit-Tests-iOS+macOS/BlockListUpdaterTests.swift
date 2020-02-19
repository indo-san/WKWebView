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

class BlockListUpdaterTests: XCTestCase {
    static let downloadCounterLabel = DownloadCounter.testingLabel
    let clearRandomness = 0.7
    /// Corresponds to block list expiration interval. Set extremely low here for testing.
    let expiration: TimeInterval = 5
    let expireDivisor: Double = 10
    let pointer: (ABPBlockListUpdater) -> UnsafeMutableRawPointer = {
        Unmanaged.passUnretained($0).toOpaque()
    }
    let scheduler = MainScheduler.asyncInstance
    let timeout: TimeInterval = 3 * 60
    var bag: DisposeBag!

    override
    func setUp() {
        do {
            try User().save()
            try Updater().save()
        } catch let err { XCTFail("Error: \(err)") }
        super.setUp()
        bag = DisposeBag()
    }

    private
    func destroyer() -> (Int, TimeInterval, XCTestExpectation) -> Disposable {
        { ival, expr, expt in
            Observable<Int>.interval(expr.toMilliseconds(), scheduler: self.scheduler)
                .subscribe(onNext: { [unowned self] in
                    if $0 > ival {
                        // Explicitly terminate user updates to prevent an attempt to read a deallocated instance:
                        self.bag = nil
                        ABPBlockListUpdater.destroy()
                        expt.fulfill()
                    }
                })
        }
    }

    /// Randomly clears the download counter.
    func testClearDownloadCounterNonTesting() throws {
        let total: Double = 100
        if Int.random(in: 0...Int(total)) > Int(total - clearRandomness * total) {
            try Persistor().clear(key: .downloadCounter)
            log("⚠️ download counter cleared")
        }
    }

    func testStaticInstance() {
        var addrs = Set<UnsafeMutableRawPointer>()
        _ = Array(1...Int.random(in: 10...100)).map { _ in
            addrs.insert(pointer(ABPBlockListUpdater.sharedInstance()))
        }
        XCTAssert(addrs.count == 1, "Bad count.")
    }

    func testUserAfterUpdateSet() {
        let updater = ABPBlockListUpdater.sharedInstance()
        updater.userForUpdate = { () -> User? in return nil }
        XCTAssert(updater.userForUpdate() == nil, "Bad assignment.")
    }

    func testCreateNewInstance() {
        let upd1 = ABPBlockListUpdater.sharedInstance()
        let ptr1 = pointer(upd1)
        ABPBlockListUpdater.destroy()
        let upd2 = ABPBlockListUpdater.sharedInstance()
        let ptr2 = pointer(upd2)
        if ptr1 == ptr2 {
            log("⚠️ Warning pointer equality.")
        }
        XCTAssert(upd1 !== upd2, "Same instance.")
    }

    func testUserNil() {
        let expect = expectation(description: #function)
        let destroyAfter: Double = expiration * 2.5
        let destroyBag = DisposeBag()
        let updater = ABPBlockListUpdater.sharedInstance()
        updater.expiration = expiration
        updater.userForUpdate = { () -> User? in return nil }
        updater.afterUpdate()
            .subscribe(onNext: { _ in
                XCTFail("Shouldn't get here.")
            }, onCompleted: {
                expect.fulfill()
            }).disposed(by: bag)
        destroyer()(Int(destroyAfter), expiration, expect).disposed(by: destroyBag)
        wait(for: [expect], timeout: expiration * destroyAfter * 10)
    }

    /// DL order checking was removed from this test due to DL order not being guaranteed.
    /// Importantly, destroying of the Updater is tested.
    func testPeriodicDownloads() {
        let expect = expectation(description: #function)
        let minDL = 3
        let maxDL = 8
        let expected = Int.random(in: minDL...maxDL)
        let updater = ABPBlockListUpdater.sharedInstance()
        var ptr: UnsafeMutableRawPointer?
        var cnt = 0
        updater.expiration = expiration
        updater.expireDivisor = expireDivisor
        ptr = pointer(updater)
        updater.userForUpdate = {
            do {
                if let user = try User(fromPersistentStorage: true) { return user }
                return try User().saved()
            } catch let err { XCTFail("Error: \(err)") }
            return nil
        }
        updater.afterUpdate()
            .subscribe(onNext: { (updtr: Updater) in
                cnt += 1
                if cnt >= expected {
                    ABPBlockListUpdater.destroy()
                    XCTAssert(self.pointer(ABPBlockListUpdater.sharedInstance()) != ptr, "Bad pointer.")
                    self.bag = nil // prevent further events and fulfills (API violation)
                    expect.fulfill()
                } else {
                    if let blst = updtr.getDownloads()?.first {
                        do {
                            try updtr.blockListSet()(blst).save()
                        } catch let err { XCTFail("Error (get_dls): \(err)") }
                    }
                }
            }, onError: {
                XCTFail("Error (subscription): \($0)")
            }, onCompleted: {
                XCTFail("Shouldn't get here.")
            }).disposed(by: bag)
        wait(for: [expect], timeout: timeout)
    }

    func testNoDownloadCounter() {
        do {
            try Persistor().clear(key: .downloadCounterTesting)
            _ = try DownloadCounter(fromPersistentStorage: true)
        } catch let err {
            let expected = ABPMutableStateError.invalidType
            XCTAssert(expected == err as? ABPMutableStateError, "Bad error of \(err), expected .invalidType.")
        }
    }

    func testDownloadCounterSaved() throws {
        try Persistor().clear(key: .downloadCounterTesting)
        var ctr = DownloadCounter(name: BlockListUpdaterTests.downloadCounterLabel)
        ctr.downloadCount = Int.random(in: 0...100)
        ctr.testing = true
        try ctr.saveTesting()
        var saved = try DownloadCounter(testingFromPersistentStorage: true)
        saved?.testing = true // persisted model does not include testing property
        XCTAssert(ctr == saved, "Not equal.")
    }

    func testDownloadCountString() throws {
        try Persistor().clear(key: .downloadCounterTesting)
        var ctr = DownloadCounter(name: BlockListUpdaterTests.downloadCounterLabel)
        for _ in 0...100 {
            ctr.downloadCount = Int.random(in: 0...100)
            switch ctr.downloadCount {
            case let cnt where cnt > Constants.downloadCounterMax:
                XCTAssert(ctr.stringForHTTPRequest() == String(Constants.downloadCounterMax) + "+", "Bad string (max).")
            case let cnt:
                XCTAssert(ctr.stringForHTTPRequest() == String(cnt), "Bad string.")
            }
        }
    }
}

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

class AppContainerTests: XCTestCase {
    let configPlistName = "Test-ABPKit-Configuration.plist"
    var user: User!

    override
    func setUp() {
        super.setUp()
        do {
            user = try User()
        } catch let err { XCTFail(err.localizedDescription) }
    }

    func testAppSupportDirectory() {
        do {
            _ = try Persistor.applicationSupportDirectory()
        } catch let err { XCTFail("Application support directory error: \(err).") }
    }

    func testPlistConfig() throws {
        let expectIOS = "group.org.adblockplus.abpkit-ios.testing-only"
        let expectMacOS = "group.org.adblockplus.abpkit-macos.testing-only"
        let expectAddonName = "abpkit.testing-only"
        let expectPartnerApp = "Partner-App.testing-only"
        let expectPartnerAppVer = "0.0.0.testing-only"
        let cfg = try Configured()
            .byBundledPlist(name: configPlistName, startWith: [AppContainerTests.self], for: ABPKitConfiguration.self)
        XCTAssert(cfg?.appGroupIOS == expectIOS, "Bad iOS group.")
        XCTAssert(cfg?.appGroupMacOS == expectMacOS, "Bad macOS group.")
        XCTAssert(cfg?.addonName == expectAddonName, "Bad addonName.")
        XCTAssert(cfg?.partnerApplication == expectPartnerApp, "Bad partner application.")
        XCTAssert(cfg?.partnerApplicationVersion == expectPartnerAppVer, "Bad partner application version.")
    }

    func testPartnerData() throws {
        let data = try BlockListDownloadData(consumer: user, configPlistName: configPlistName, startWith: [AppContainerTests.self])
        XCTAssertEqual(try data.partnerData(.addonName), "abpkit.testing-only", "Bad addonName.")
        XCTAssertEqual(try data.partnerData(.partnerApplication), "Partner-App.testing-only", "Bad partner application.")
        XCTAssertEqual(try data.partnerData(.partnerApplicationVersion), "0.0.0.testing-only", "Bad partner version.")
        XCTAssert(data.queryItems.contains(URLQueryItem(name: "addonName", value: "abpkit.testing-only")), "Missing addonName.")
        XCTAssert(data.queryItems.contains(URLQueryItem(name: "application", value: "Partner-App.testing-only")), "Missing app name.")
        XCTAssert(data.queryItems.contains(URLQueryItem(name: "applicationVersion", value: "0.0.0.testing-only")), "Missing version.")
    }
}

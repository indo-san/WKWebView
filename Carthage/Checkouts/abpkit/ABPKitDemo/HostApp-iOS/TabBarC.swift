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

import ABPKit
import UIKit

class TabBarC: UITabBarController {
    override
    func viewDidLoad() {
        super.viewDidLoad()
        tabViewIDsSet()
        do {
            try SetupShared.firstUser().save()
        } catch let err { log("🚨 Error: \(err)") }
        #if ABP_AUTO_TESTER_TABS
        if !isTesting() { HostAppTester.shared.autoTabSwitch(tbc: self) }
        #endif
    }

    func tabViewIDsSet() {
        let cnt = 2
        let tab = "tab"
        if let vcs = viewControllers {
            for idx in 1...cnt {
                if let vcn = vcs[idx - 1] as? WebViewVC {
                    vcn.tabViewID = "\(tab)\(idx)"
                }
            }
        }
    }
}

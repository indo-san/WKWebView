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
import Cocoa

class TabVC: NSTabViewController {
    let height = 744
    let width = 1024
    let xPosition = 50
    let yPosition = 600

    override
    func viewDidLoad() {
        super.viewDidLoad()
        do {
            try SetupShared.firstUser().save()
        } catch let err { log("🚨 Error: \(err)") }
    }

    override
    func viewWillAppear() {
        super.viewWillAppear()
        view.window?.setFrame(
            NSRect(x: xPosition, y: yPosition, width: width, height: height), display: true)
        #if ABP_AUTO_TESTER_TABS
        if !isTesting() { HostAppTester.shared.autoTabSwitch(tvc: self) }
        #endif
    }

    override
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        _ = (tabViewItem?.viewController as? WebViewVC).map {
            $0.tabViewID = (tabViewItem?.identifier as? String) ?? ""
        }
    }
}

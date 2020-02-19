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
import RxSwift

extension HostAppTester {
    #if os(iOS)
    func autoTabSwitch(tbc: TabBarC) {
        Observable<Int>.interval(.milliseconds(randomMS()), scheduler: scheduler)
            .subscribe(onNext: { [unowned self] _ in
                tbc.selectedIndex = tbc.selectedIndex == 0 ? 1 : 0
                self.bagTab = DisposeBag()
                self.autoTabSwitch(tbc: tbc)
            }, onError: { err in
                log("🛑 tbc \(err)")
            }).disposed(by: bagTab)
    }
    #elseif os(macOS)
    func autoTabSwitch(tvc: TabVC) {
        Observable<Int>.interval(.milliseconds(randomMS()), scheduler: scheduler)
            .subscribe(onNext: { [unowned self] _ in
                tvc.selectedTabViewItemIndex = tvc.selectedTabViewItemIndex == 0 ? 1 : 0
                self.bagTab = DisposeBag()
                self.autoTabSwitch(tvc: tvc)
            }, onError: { err in
                log("🛑 tvc \(err)")
            }).disposed(by: bagTab)
    }
    #endif
}

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

/// UI tester. This is ad-hoc code intended for special testing applications only. It is not
/// intended for general use.
///
/// Designed to be active with the following Swift compiler flags:
/// OTHER_SWIFT_FLAGS = "-DABP_AUTO_TESTER_FAIL_ON_ERR -DABP_AUTO_TESTER_TABS -DABP_AUTO_TESTER_AA";
class HostAppTester {
    static let shared = HostAppTester()
    let frequency = 80 // percent of fast delays
    let scheduler = MainScheduler.asyncInstance
    let slowdown: Double = 1.5
    var bagAA = DisposeBag()
    var bagTab = DisposeBag()
    var testerStarted = false

    private
    init() {
        // Intentionally empty.
    }

    /// Fast and slow delays.
    func randomMS() -> Int {
        if Int.random(in: 0...100) < frequency {
            return Int(Double(Int.random(in: 0...1000)) * slowdown)
        }
        return Int(Double(Int.random(in: 2000...5000)) * slowdown)
    }

    func autoAASwitch(wvc: WebViewVC) {
        Observable<Int>.interval(.milliseconds(randomMS()), scheduler: scheduler)
            .subscribe(onNext: { [unowned self] _ in
                #if os(iOS)
                if wvc.aaButton.isEnabled {
                    wvc.aaPressed(wvc)
                }
                #elseif os(macOS)
                if wvc.aaCheckButton.isEnabled {
                    wvc.aaPressed(wvc)
                }
                #endif
                self.bagAA = DisposeBag()
                self.autoAASwitch(wvc: wvc)
            }, onError: { err in
                log("🛑 wvc \(err)")
            }).disposed(by: bagAA)
    }
}

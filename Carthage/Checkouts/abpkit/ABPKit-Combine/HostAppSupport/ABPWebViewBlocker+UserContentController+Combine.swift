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

import Combine
import WebKit

@available(iOS 11.0, macOS 10.13, *)
extension ABPWebViewBlocker
{
    // swiftlint:disable nesting
    struct ContentControllerAddPublisher<U: BlockListable>: Publisher
    {
        typealias Output = WKContentRuleList?
        typealias Failure = Error

        let abpList: U?
        weak var webViewBlocker: ABPWebViewBlocker?

        func receive<S>(subscriber: S)
        where S: Subscriber, ContentControllerAddPublisher.Failure == S.Failure, ContentControllerAddPublisher.Output == S.Input
        {
            if let sub = subscriber as? AnySubscriber<WKContentRuleList?, Error> {
                addToContentController(abpList: abpList, subscriber: sub)
            }
            subscriber.receive(completion: .failure(ABPCombineError.badTypeCast))
        }

        private
        func addToContentController<U: BlockListable>(abpList: U?, subscriber: AnySubscriber<WKContentRuleList?, Error>, called: Int = 0)
        {
            guard let wvb = webViewBlocker else { subscriber.receive(completion: .failure(ABPCombineError.missingObject)); return }
            /// Embedded here due to use of generics as the containing function is where the type can be determined.
            ///
            /// The fallback mechanism serves to catch conditions that have not been fully accounted for
            /// in the implementation. It provides a matching BL from user history when one cannot be
            /// found. It has been verified through extreme UI testing to produce correct results. The
            /// frequency of occurrence should be rare to none under heavy usage.
            ///
            /// Failure has been observed on AA switching before rules processing has completed.
            /// Therefore, AA switching should not be initiated before completion of the previous AA
            /// switch. Rules may fail to be applied in this case.
            let fallback: (User) -> U? = {
                ABPWebViewBlocker.matchUserBlockList(toListType: .userHistory)($0, nil) as? U
            }
            wvb.wkcb.rulesStore
                .lookUpContentRuleList(forIdentifier: abpList?.name) { rlist, err in
                    if err != nil && called < 1 {
                        let fblst = fallback(wvb.user)
                        #if ABPDEBUG
                        log("⚠️ Unable to use \(abpList?.name as String?) due to error \(err as Error?).")
                        log("⚠️ Using fallback \(fblst?.name as String?).")
                        #endif
                        self.addToContentController(abpList: fblst, subscriber: subscriber, called: 1)
                    } else if err != nil {
                        #if ABP_AUTO_TESTER_FAIL_ON_ERR
                        // Catch a failure to have rules applied where no fallback is available:
                        if fblst == nil { fatalError("Fallback is nil") }
                        #endif
                        subscriber.receive(completion: .failure(err!))
                    }
                    if let list = rlist {
                        wvb.ctrl.add(list)
                        _ = subscriber.receive(list)
                    }
                    subscriber.receive(completion: .finished)
                }
        }
    }
    // swiftlint:enable nesting

    /// Add rules for a Blocklistable to the content controller.
    /// This is a different operation than adding rules to the WK rule store.
    /// See WebKitContentBlocker.rulesAddedWKStore().
    ///
    /// One fallback is used if there is an error on the given list.
    /// Future versions should handle a failed lookup more gracefully.
    /// - returns: List added.
    func contentControllerAddBlocklistable<U: BlockListable>(clear: Bool = false) -> (U?) -> SingleRuleListOptional
    {
        {
            guard let lst = $0 else { return Empty(completeImmediately: true).eraseToAnyPublisher() }
            if clear {
                return self.clearRuleLists()
                    .flatMap { () -> SingleRuleListOptional in
                        ContentControllerAddPublisher(abpList: lst, webViewBlocker: self).eraseToAnyPublisher()
                    }.eraseToAnyPublisher()
            }
            return ContentControllerAddPublisher(abpList: lst, webViewBlocker: self).eraseToAnyPublisher()
        }
    }

    /// Remove operations require main thread.
    /// This removal works in concert with the individual removers of syncHistoryRemovers (WebKitContentBlocker).
    /// Behavior of subscribe(on:) has not been verified.
    private
    func clearRuleLists() -> SingleVoid
    {
        SinglePublisher(()).subscribe(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    /// The only adder for the content controller.
    private
    func toContentControllerAdd() -> (WKContentRuleList?) throws -> WKContentRuleList?
    {
        { [unowned self] in if $0 != nil { self.ctrl.add($0!); return $0! }; return nil }
    }
}

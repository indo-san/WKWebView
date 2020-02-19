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

import RxSwift
import WebKit

// FilterList implementations will eventually be removed.
@available(iOS 11.0, macOS 10.13, *)
extension WebKitContentBlocker {
    /// FilterList implementation:
    func concatenatedRules(model: LegacyFilterList) -> SingleRuleStringAndCount {
        do {
            let url = bundle != nil ? try model.rulesURL(bundle: bundle!) : try model.rulesURL()
            return try concatenatedRules()(LegacyRulesHelper().decodedRulesFromURL()(url))
        } catch let err { return .error(err) }
    }

    /// Validation result only.
    /// - parameter rules: Raw rules.
    /// - returns: Single with a RulesValidation result.
    func validatedRulesWithRaw(rules: String) -> SingleRulesValidation {
        LegacyRulesHelper().decodedRulesFromString()(rules)
            .reduce(0) { acc, _ in acc + 1 }
            .asSingle()
            .flatMap { cnt -> SingleRulesValidation in
                if cnt > Constants.blocklistRulesMax {
                    return .just(RulesValidation(
                        parseSucceeded: true, rulesCounted: cnt, error: ABPBlockListError.ruleCountExceeded))
                }
                return .just(RulesValidation(
                    parseSucceeded: true, rulesCounted: cnt, error: nil))
            }
            .catchError { err in
                .just(RulesValidation(
                    parseSucceeded: false, rulesCounted: nil, error: err))
            }
    }

    /// Embedding a subscription inside this Observable has yielded the fastest performance for
    /// concatenating rules.
    /// Other methods tried:
    /// 1. flatMap + string append - ~4x slower
    /// 2. reduce - ~10x slower
    /// Returns blocklist string + rules count.
    func concatenatedRules(customBundle: Bundle? = nil) -> (StreamRule) -> SingleRuleStringAndCount {
        { obsRules in
            let rhlp = LegacyRulesHelper(customBundle: customBundle) // only uses bundle if overridden
            let encoder = JSONEncoder()
            var all = Constants.blocklistArrayStart
            var cnt = 0
            return .create { observer in
                obsRules
                    .subscribe(onNext: { rule in
                        do {
                            cnt += 1
                            try all += rhlp.ruleToStringWithEncoder(encoder)(rule) + Constants.blocklistRuleSeparator
                        } catch let err { observer.onError(err) }
                    }, onCompleted: {
                        observer.onNext((all.dropLast() + Constants.blocklistArrayEnd, cnt))
                        observer.onCompleted()
                    }).disposed(by: self.bag)
                return Disposables.create()
            }
        }
    }

    /// FilterList implementation:
    /// Clear one or more matching rule lists associated with a filter list model.
    func ruleListClearersForModel() -> (LegacyFilterList) -> StreamRuleListID {
        { [unowned self] model in
            self.ruleListIdentifiers()
                .flatMap { identifiers -> Observable<String> in
                    guard let ids = identifiers else { return .error(ABPWKRuleStoreError.invalidRuleData) }
                    let obs = ids
                        .filter { $0 == model.name }
                        .map { [unowned self] in self.listRemovedFromStore(identifier: $0) }
                    if obs.count < 1 { return .error(ABPWKRuleStoreError.missingRuleList) }
                    return .concat(obs)
                }
        }
    }

    /// Based on FilterList. This function is now only for reference and testing. The User model
    /// should be preferred over FilterList. IDs may be logged using withIDs.
    /// - returns: An observable after adding a list.
    func addedWKStoreRules(addList: LegacyFilterList) -> SingleRuleList {
        concatenatedRules(model: addList)
            .flatMap { result -> Observable<WKContentRuleList> in
                .create { observer in
                    // In WebKit, compileContentRuleList requires access to main
                    // even though it runs on a different thread.
                    DispatchQueue.main.async {
                        self.rulesStore
                            .compileContentRuleList(forIdentifier: addList.name,
                                                    encodedContentRuleList: result.0) { [unowned self] list, err in
                                guard err == nil else { observer.onError(err!); return }
                                self.rulesStore.getAvailableContentRuleListIdentifiers { [unowned self] (ids: [String]?) in
                                    if ids?.contains(addList.name) == false { observer.onError(ABPWKRuleStoreError.missingRuleList) }
                                    self.logWith?(ids)
                                }
                                if let compiled = list {
                                    observer.onNext(compiled)
                                    observer.onCompleted()
                                } else { observer.onError(ABPWKRuleStoreError.invalidRuleData) }
                            }
                    }
                    return Disposables.create()
                }
            }
    }
}

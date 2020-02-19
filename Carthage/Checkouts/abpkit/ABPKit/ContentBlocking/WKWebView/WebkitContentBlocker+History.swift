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

enum HistorySyncTarget {
    case userBlocklist
    case userBlocklistAndHistory
}

// For synchronization of states against the WK store.
@available(iOS 11.0, macOS 10.13, *)
extension WebKitContentBlocker {
    /// Remove rule lists from the WK store that are not meant to be persisted.
    /// The active BL for the user is maintained.
    ///
    /// Rule lists can be precompiled in the rule store.
    ///
    /// This is meant to operate on the user state **after** rules have been loaded into the rule
    /// store. In this way, the rules in the store are always available for use according to the
    /// history in a user state.
    ///
    /// See ABPBlockListUpdater.userBlockListUpdated().
    func syncHistoryRemovers(target: HistorySyncTarget) -> (User) -> CompoundRemovers {
        let removersFor: (User, [String]) -> CompoundRemovers = { user, names in
            self.ruleListIdentifiers()
                .flatMap { ids -> CompoundRemovers in
                    .create { observer in
                        // Add item to be removed if identifier in the store is not in the list of IDs.
                        let observables = ids?.filter { idr in !names.contains { $0 == idr } }
                            .map { self.listRemovedFromStore(identifier: $0) }
                            .reduce([]) { $0 + [$1] }
                        // Empty string sent to keep operation chains continuous:
                        if let obs = observables, obs.count > 0 {
                            observer.onNext(.concat(obs))
                        } else { observer.onNext(.just("")) }
                        observer.onCompleted()
                        return Disposables.create()
                    }
                }
        }
        return { user in
            var all: [String]!
            do {
                switch target {
                case .userBlocklist:
                    all = try self.names()(user.getBlockList().map {[$0]})
                case .userBlocklistAndHistory:
                    all = try self.names()(user.getBlockList().map {[$0]}) + self.names()(user.getHistory().map {$0})
                }
            } catch let err { return .error(err) }
            return removersFor(user, all)
        }
    }

    /// - returns: Array of names of a given set of BlockListables.
    private
    func names<U: BlockListable>() -> ([U]?) throws -> [String] {
        {
            guard let models = $0 else { throw ABPUserModelError.badDataUser }
            return models.map { $0.name }.reduce([]) { $0 + [$1] }
        }
    }
}

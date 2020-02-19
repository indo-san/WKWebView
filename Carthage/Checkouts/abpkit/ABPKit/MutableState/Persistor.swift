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

/// Persistent storage operations for UserDefaults backed storage:
/// * observe
/// * save
/// * load
/// * clear
class Persistor {
    typealias Action = (_ value: Any) -> Void
    /// Scheduler for all operations, main thread subscription is necessary for correct results.
    let scheduler = MainScheduler.asyncInstance
    let defaults: UserDefaults!

    init() throws {
        do {
            defaults = try UserDefaults(suiteName: Config().appGroup())
        } catch { throw ABPMutableStateError.missingDefaults }
    }

    /// Save a value to a key path in defaults.
    func save<T>(type: T.Type,
                 value: T,
                 key: ABPMutableState.StateName) throws {
        defaults
            .setValue(value, forKey: key.rawValue)
    }

    /// - returns: Persisted state model, should not be nil.
    func load<T>(type: T.Type,
                 key: ABPMutableState.StateName) throws -> T {
        guard let res = defaults.value(forKeyPath: key.rawValue) as? T else { throw ABPMutableStateError.invalidType }
        return res
    }

    /// Set value nil should be an equivalent action here.
    func clear(key: ABPMutableState.StateName) throws {
        defaults
            .removeObject(forKey: key.rawValue)
    }
}

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

/// Provides periodic checking and updating of a user's block list.
/// However, this module is not intended to alter a user's state.
///
/// - Only the sharedInstance() reference should be used for this class.
/// - Expiration is set with self.expiration.
/// - Updates are stopped by destroying the instance.
///
/// This class is intended to not operate on user state directly.
@available(iOS 11.0, macOS 10.13, *)
class ABPBlockListUpdater {
    /// Overrideable function that is used to get the user state to update.
    public var userForUpdate: (() -> User?)!
    /// Default implementation of the function that gets the user state to be updated.
    public static let defaultUserForUpdate: () -> User? = {
        do {
            if let user = try User(fromPersistentStorage: true) {
                return user
            }
        } catch { return nil }
        return nil
    }
    private static var privateSharedInstance: ABPBlockListUpdater?
    let scheduler = MainScheduler.asyncInstance
    private var _expireDivisor: Double
    var expireDivisor: Double {
        get { _expireDivisor }
        set(divisor) {
            _expireDivisor = divisor
            period = expiration / expireDivisor
        }
    }
    private var _expiration: TimeInterval
    var expiration: TimeInterval {
        get { _expiration }
        set(interval) {
            _expiration = interval
            period = _expiration / expireDivisor
        }
    }
    var period: TimeInterval
    /// Updater errors are not exported yet.
    var updaterErrors: ValueSubjectErrorOptional
    var updaterRunning = false
    var wkcb: WebKitContentBlocker!

    init() {
        fatalError("Should only be accessed from sharedInstance().")
    }

    /// Allows customization of conditions used to determine whether to update the user's active block
    /// list. This may be useful for situations where a block list download may not be preferred or
    /// available.
    /// - parameters:
    ///   - expiration: Period corresponding to block list expiration (in seconds).
    ///   - expireDivisor: Divisor for calculating when to check if expiration has occurred.
    private
    init(expiration: TimeInterval = Constants.defaultFilterListExpiration,
         expireDivisor: Double = Constants.periodicUpdateDivisor) {
        updaterErrors = RxSubjects.updaterErrors
        _expiration = expiration
        _expireDivisor = expireDivisor
        period = expiration / expireDivisor
        Bags.bagCreate()(.blockListUpdater, self)
        userForUpdate = ABPBlockListUpdater.defaultUserForUpdate
        wkcb = WebKitContentBlocker(logWith: { log("📙 store \($0 as [String]?)") })
    }

    deinit {
        /// Moved out of destroy in attempt to prevent the need for
        /// simultaneous access on the dispose bag during testing.
        Bags.bagDispose()(.blockListUpdater, self)
    }

    /// Destroy the shared instance in memory.
    class func destroy() {
        privateSharedInstance = nil
    }

    /// Provide access to the shared instance.
    class func sharedInstance() -> ABPBlockListUpdater {
        guard let shared = privateSharedInstance else {
            privateSharedInstance = ABPBlockListUpdater(expiration: Constants.defaultFilterListExpiration)
            return privateSharedInstance!
        }
        return shared
    }

    /// - returns: True if an update should proceed due to the last download being expired.
    func userBlockListShouldUpdate() -> (User) -> Bool {
        return { usr in
            // Check expiration based on downloads and the user BL:
            do {
                let updtr = try Updater(fromPersistentStorage: true)
                return ((updtr?.getDownloads()?
                    .filter { $0.initiator == .automaticUpdate }.first?.dateDownload ?? (usr.getBlockList()?.dateDownload)) ??
                        Date.distantPast).map { fabs($0.timeIntervalSinceNow) } ?? 0 >= self.expiration
            } catch { return false }
        }
    }
}

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

extension BlockListDownloader {
    /// Move a file to a destination. If the file exists, it will be first removed, if possible. If
    /// the operation cannot be completed, the function will throw an error.
    func moveItem(source: URL, destination: URL?) -> Completable {
        guard let dst = destination else { return .error(ABPDownloadTaskError.badDestinationURL) }
        let mgr = FileManager.default
        do {
            try mgr.moveItem(at: source, to: dst)
            return .empty()
        } catch let err { return .error(err) }
    }

    func removeFiles() -> ([URL]) throws -> Void {
        {
            let errorCode = 4 // remove failure is allowed
            let mgr = FileManager.default
            do {
                try $0.forEach {
                    try mgr.removeItem(at: $0)
                    self.logWith?($0.path)
                }
            } catch let err {
                switch err {
                case let nsErr as NSError where nsErr.code == errorCode:
                    break // ignore error
                default:
                    throw err
                }
            }
        }
    }

    /// Remove downloads from disk no longer in user **download history** based on a given user state.
    /// - parameter (User): the user state to be synced.
    /// - returns: User after sync.
    public
    func syncDownloads<S>(initiator: DownloadInitiator) -> (S) throws -> S
    where S: BlockListDownloadable & Persistable {
        // Strong self is required here.
        { consumer in
            var saved: S!
            let pstr = try Persistor()
            switch initiator {
            case .userAction:
                saved = try consumer.downloadsUpdated().historyUpdated().saved()
                self.user = saved as? User // internal state change
            case .automaticUpdate:
                saved = try consumer.downloadsUpdated().saved()
                self.updater = saved as? Updater
            default:
                throw(ABPBlockListError.badInitiator)
            }
            let filesNotInSaved = pstr.jsonFiles()(try pstr.fileEnumeratorForRoot()(Config().containerURL()))
                .filter { url in
                    !((saved.getDownloads()) ?? []).contains {
                        $0.name.addingFileExtension(Constants.rulesExtension) == url.lastPathComponent &&
                        $0.initiator == initiator
                    }
                }
            var rmv: [URL]!
            switch initiator {
            case .userAction:
                rmv = try self.toRemove(initiator: initiator, user: self.user)(filesNotInSaved)
            case .automaticUpdate:
                rmv = try self.toRemove(initiator: initiator, user: nil)(filesNotInSaved)
            default:
                throw(ABPBlockListError.badInitiator)
            }
            try self.removeFiles()(rmv)
            try self.sessionInvalidate()
            return saved
        }
    }

    func toRemove(initiator: DownloadInitiator, user: User?) -> ([URL]) throws -> [URL] {
        /// Relaxes the automatic removal of downloads to allow for user state differences between automatic updates
        /// and user actions. A little more storage is used.
        let downloadKeepRelaxer = Constants.automaticUpdateKeepFactor
        let mgr = FileManager.default
        let compareExpired: (URL) -> Bool = { url in
            do {
                #if ABPDEBUG
                let expired = Constants.blocklistExpirationDebug * downloadKeepRelaxer
                #else
                let expired = Constants.defaultFilterListExpiration * downloadKeepRelaxer
                #endif
                let compareTo =
                    fabs((try mgr.attributesOfItem(atPath: url.path)[FileAttributeKey.creationDate] as? NSDate)?
                        .timeIntervalSinceNow ?? expired)
                return compareTo >= expired
            } catch { return false } // keep by default
        }
        switch initiator {
        case .userAction:
            return {
                $0
                    .filter { !($0.lastPathComponent == user?.getBlockList()?.name.addingFileExtension(Constants.rulesExtension)) }
                    .filter { compareExpired($0) }
            }
        case .automaticUpdate:
            return { $0.filter { compareExpired($0) } }
        default:
            return { _ in throw(ABPBlockListError.badInitiator) }
        }
    }
}

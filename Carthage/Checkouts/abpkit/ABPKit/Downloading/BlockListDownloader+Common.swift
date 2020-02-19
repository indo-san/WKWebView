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

extension BlockListDownloader {
    // MARK: - Responses and Events -
    /// - returns: True if the status code is valid.
    func validURLResponse(_ response: HTTPURLResponse?) -> Bool {
        { response?.statusCode }().map { $0 >= 200 && $0 < 300 } ?? false
    }

    /// Get last event from behavior subject matching the task ID.
    /// - parameter taskID: A background task identifier.
    /// - returns: The download event value if it exists, otherwise nil.
    func lastDownloadEvent(taskID: Int) -> DownloadEvent? {
        (downloadEvents[taskID].map { try? $0.value() })?.map { $0 }
    }

    // MARK: - Session Handling -
    /// Examines downloads for the current instance. Throws an error upon
    /// encountering an incomplete source download. This should never be
    /// encountered during normal usage.
    func sessionInvalidate() throws {
        try srcDownloads.forEach {
            if $0.task?.state != .completed {
                throw ABPDownloadTaskParameterizedError.notComplete($0)
            }
        }
        self.downloadSession.invalidateAndCancel()
    }

    /// Cancel all existing downloads.
    func downloadsCancelled() -> ([SourceDownload]) -> [SourceDownload] {
        { dls in
            dls.map { $0.task?.cancel(); return $0 }
        }
    }

    /// Update user's block list with most recently downloaded block list.
    func userBlockListUpdated() -> (User) throws -> User {
        { user in
            let match = try user.downloads?
                .sorted { $0.dateDownload?.compare($1.dateDownload ?? .distantPast) == .orderedDescending }
                .filter { // only allow AA matches if AA enableable
                    if let blst = user.blockList, blst.source is AcceptableAdsEnableable {
                        return try AcceptableAdsHelper().aaExists()($0.source) == AcceptableAdsHelper().aaExists()(blst.source)
                    }
                    return true
                }.first
            if let updated = match.map({ user.updatedBlockList()($0) }) {
                return updated
            }
            throw ABPUserModelError.badDownloads
        }
    }

    func downloadedUserBlockLists(initiator: DownloadInitiator) throws -> [BlockList] {
        try sourcesToBlockLists()(blockListDownloadsForUser(initiator: initiator)(user))
    }

    /// Cancel all existing downloads.
    /// Start tasks after creating tasks for downloading sources in user's block list.
    /// - returns: An array of SourceDownloads for the given user.
    func blockListDownloadsForUser<S>(initiator: DownloadInitiator) -> (S) throws
        -> [SourceDownload] where S: BlockListDownloadable & Persistable {
            { consumer in
                _ = self.downloadsCancelled()(self.srcDownloads)
                do {
                    return try self.sourceDownloadsForAA(initiator: initiator)(consumer.acceptableAdsInUse())
                        .map { $0.task?.resume(); return $0 }
                } catch let err { throw err }
            }
    }

    /// Transform sources to block lists - for setting user block list caches.
    func sourcesToBlockLists() -> ([SourceDownload]) -> [BlockList] {
        {
            $0.reduce([]) {
                if let list = $1.blockList { return $0 + [list] }
                return $0
            }
        }
    }

    /// Create the SourceDownloads used to download the rules for a given AA state.
    /// - returns: SourceDownload collection for a RulesDownloadable BlockList.
    func sourceDownloadsForAA(initiator: DownloadInitiator) -> (Bool) throws -> [SourceDownload] {
        {
            var source: RemoteBlockList!
            switch $0 {
            case true:
                source = .easylistPlusExceptions
            case false:
                source = .easylist
            }
            if let url = try self.queryItemsAdded(initiator: initiator)(URL(string: source.rawValue)) {
                return [SourceDownload(
                    initiator: initiator,
                    task: self.downloadSession.downloadTask(with: url),
                    blockList: try BlockList(
                        withAcceptableAds: source.hasAcceptableAds(),
                        source: source,
                        initiator: initiator),
                    url: url)]
            } else { throw ABPDownloadTaskError.badSourceURL }
        }
    }

    /// Add additional parameters to request.
    func queryItemsAdded(initiator: DownloadInitiator) -> (URL?) throws -> URL? {
        {
            if let url = $0, var cmps = URLComponents(string: url.absoluteString) {
                switch initiator {
                case .userAction:
                    cmps.queryItems = try BlockListDownloadData(consumer: self.user).queryItems
                case .automaticUpdate:
                    cmps.queryItems = try BlockListDownloadData(consumer: self.updater).queryItems
                default:
                    throw(ABPBlockListError.badInitiator)
                }
                cmps.encodePlusSign()
                return cmps.url
            }
            return nil
        }
    }

    /// - returns: True if source is downloadable.
    func isDownloadable() -> ((BlockListSourceable & RulesDownloadable)?) -> Bool {
        { $0 as? RemoteBlockList != nil }
    }
}

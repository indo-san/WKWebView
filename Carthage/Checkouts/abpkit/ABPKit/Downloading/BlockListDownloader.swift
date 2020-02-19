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

import Foundation

/// Handles all downloads for a user. Some user states are persisted based on
/// their initial state.
class BlockListDownloader: NSObject,
                           URLSessionDownloadDelegate,
                           Loggable {
    typealias LogType = String

    /// Updater state.
    var updater: Updater!
    /// User state.
    var user: User!
    /// Active downloads for use by delegate - state is not persisted.
    var srcDownloads = [SourceDownload]()
    /// Download events keyed by task ID.
    var downloadEvents = TaskDownloadEvents()
    /// Serial queue for download session.
    lazy var downloadQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = Constants.queueDownloads
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    /// For download tasks.
    lazy var downloadSession: URLSession! = {
        URLSession(
            configuration: URLSessionConfiguration.default,
            delegate: self,
            delegateQueue: downloadQueue)
    }()
    /// For debugging.
    var logWith: ((LogType) -> Void)?

    init(user: User, logWith: ((LogType) -> Void)? = nil) {
        super.init()
        Bags.bagCreate()(.blockListDownloader, self)
        self.user = user
        self.logWith = logWith
    }

    init<S>(initiator: DownloadInitiator, consumer: S) throws where S: BlockListDownloadable & Persistable {
        super.init()
        Bags.bagCreate()(.blockListDownloader, self)
        switch initiator {
        case .userAction:
            self.user = consumer as? User
        case .automaticUpdate:
            self.updater = consumer as? Updater
        default:
            throw(ABPBlockListError.badInitiator)
        }
    }
}

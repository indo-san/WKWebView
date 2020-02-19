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
    /// A URL session task is transferring data.
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        let taskID = downloadTask.taskIdentifier
        downloadEvents[taskID]?.onNext(
            DownloadEvent(
                withNotFinishedEvent: lastDownloadEvent(taskID: taskID),
                bytesWritten: totalBytesWritten))
    }

    /// A download task has finished downloading. Update the user's block list
    /// metadata and move the downloaded file. Updates user state.
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        let taskID = downloadTask.taskIdentifier
        let idx = indexForTaskID()(taskID)
        if !validURLResponse(downloadTask.response as? HTTPURLResponse) {
            reportError(
                ABPDownloadTaskParameterizedError.invalidResponse(
                    downloadTask.response,
                    idx.map { srcDownloads[$0] }?.blockList?.source),
                taskID: taskID)
            return // handling ends if error
        }
        let fnameFromIndex: (Int?) -> String? = {
            $0.map { self.srcDownloads[$0] }.map { $0.blockList?.name.addingFileExtension(Constants.rulesExtension) }?.map({ $0 })
        }
        let initiatorFromIndex: (Int?) -> DownloadInitiator? = {
            $0.map { self.srcDownloads[$0] }.map { $0.initiator }
        }
        if let fname = fnameFromIndex(idx), let intr = initiatorFromIndex(idx) {
            do {
                switch intr {
                case .userAction:
                    try finalizeDownload(downloadTask: downloadTask, location: location, filename: fname)(self.user)
                case .automaticUpdate:
                    try finalizeDownload(downloadTask: downloadTask, location: location, filename: fname)(self.updater)
                default:
                    reportError(ABPBlockListError.badInitiator, taskID: taskID)
                }
            } catch let err { reportError(err, taskID: taskID) }
        } else { reportError(ABPDownloadTaskError.badFilename, taskID: taskID) }
    }

    /// A URL session task has finished transferring data.
    /// Download events are updated.
    /// The downloaded data is persisted to local storage.
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        let taskID = task.taskIdentifier
        downloadEvents[taskID]?.onNext(
            DownloadEvent(
                finishWithEvent: lastDownloadEvent(taskID: taskID)))
        if error != nil { reportError(error!, taskID: taskID) }
        downloadEvents[taskID]?.onCompleted()
    }

    /// The actual block list that is to be persisted.
    func blockListForPersistence(date: Date) -> (BlockList) throws -> BlockList {
        { srcBL in
            try BlockList(
                withAcceptableAds: AcceptableAdsHelper().aaExists()(srcBL.source),
                source: srcBL.source,
                name: srcBL.name,
                dateDownload: date,
                initiator: srcBL.initiator)
        }
    }

    func lastVersionSet<S>(_ version: String) -> (S) -> S where S: BlockListDownloadable & Persistable {
        {
            var copy = $0; copy.lastVersion = version; return copy
        }
    }

    /// - returns: Index of the source download if it exists.
    func indexForTaskID() -> (Int) -> Int? {
        { tid in
            self.srcDownloads.enumerated().filter { $1.task?.taskIdentifier == tid }.first?.0
        }
    }

    /// Report an error.
    func reportError(_ error: Error,
                     taskID: DownloadTaskID) {
        downloadEvents[taskID]?.onError(error)
    }
}

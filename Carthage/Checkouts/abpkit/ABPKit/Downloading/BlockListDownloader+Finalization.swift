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
    func finalizeDownload<S>(downloadTask: URLSessionDownloadTask, location: URL, filename: String) -> (S) throws -> Void
    where S: BlockListDownloadable & Persistable {
        { consumer in
            let taskID = downloadTask.taskIdentifier
            guard let idx = self.indexForTaskID()(taskID) else {
                self.reportError(ABPDownloadTaskError.badSourceDownload, taskID: taskID); return
            }
            /// A version from the server. It is not used for download date, by design.
            let dlVersion: (URLResponse?) -> String = {
                let dateKey = "Date"
                let dflt = Date().asTimestamp() // default value
                if let resp = $0 as? HTTPURLResponse {
                    return (resp.allHeaderFields[dateKey] as? Date)?.asTimestamp() ?? dflt
                }
                return dflt
            }
            do {
                self.moveItem(
                    source: location,
                    destination: try Config().containerURL().appendingPathComponent(filename, isDirectory: false))
                        .subscribe { cmpl in
                            switch cmpl {
                            case .completed:
                                switch self.srcDownloads[idx].initiator {
                                case .userAction:
                                    if let srcBL = self.srcDownloads[idx].blockList.map({ $0 }) {
                                        // Only AA enableable sources should succeed:
                                        do {
                                            self.user = try self.lastVersionSet(dlVersion(downloadTask.response))(self.user)
                                                .downloadAdded()(try self.blockListForPersistence(date: Date())(srcBL))
                                        } catch let err { self.reportError(err, taskID: taskID) }
                                    } else { self.reportError(ABPDownloadTaskError.badSourceDownload, taskID: taskID) }
                                case .automaticUpdate:
                                    if let srcBL = self.srcDownloads[idx].blockList.map({ $0 }) {
                                        // Only AA enableable sources should succeed:
                                        do {
                                            self.updater = try self.lastVersionSet(dlVersion(downloadTask.response))(self.updater)
                                                .downloadAdded()(try self.blockListForPersistence(date: Date())(srcBL))
                                        } catch let err { self.reportError(err, taskID: taskID) }
                                    } else { self.reportError(ABPDownloadTaskError.badSourceDownload, taskID: taskID) }
                                default:
                                    self.reportError(ABPBlockListError.badInitiator, taskID: taskID)
                                }
                            case .error(let err):
                                self.reportError(err, taskID: taskID)
                            }
                        }.disposed(by: Bags.bag()(.blockListDownloader, self))
            } catch let err { self.reportError(err, taskID: taskID) }
        }
    }
}

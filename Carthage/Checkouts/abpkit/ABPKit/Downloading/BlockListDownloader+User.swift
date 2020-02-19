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

// Download handling for a User.
extension BlockListDownloader {
    /// An Observable containing a User/Updater after downloading has finished.
    /// More than one event can have didFinishDownloading == true.
    /// - returns: Only self.user or self.updater as additional processing on the state has been removed through refactoring.
    // swiftlint:disable force_cast
    func afterDownloads<S>(initiator: DownloadInitiator) -> (StreamDownloadEvent) -> Observable<S>
    where S: BlockListDownloadable & Persistable {
        { event in
            event
                .takeLast(1)
                .filter { $0.didFinishDownloading == true }
                .flatMap { [unowned self] _ -> Observable<S> in
                    do {
                        try self.sessionInvalidate()
                    } catch let err { return .error(err) }
                    switch initiator {
                    case .userAction:
                        return .just(self.user as! S)
                    case .automaticUpdate:
                        return .just(self.updater as! S)
                    default:
                        return .error(ABPBlockListError.badInitiator)
                    }
                }
        }
    }
    // swiftlint:enable force_cast

    /// Performs downloading and assigns events.
    /// - returns: Observable of all concatenated user download events.
    func userSourceDownloads(initiator: DownloadInitiator) -> StreamDownloadEvent {
        do {
            // Downloader has state dependency on source DLs property:
            switch initiator {
            case .userAction:
                srcDownloads = try blockListDownloadsForUser(initiator: initiator)(user)
            case .automaticUpdate:
                srcDownloads = try blockListDownloadsForUser(initiator: initiator)(updater)
            default:
                return .error(ABPBlockListError.badInitiator)
            }
            // Downloader has state dependency on download events:
            downloadEvents = makeDownloadEvents()(srcDownloads)
            return .concat(downloadEvents.map { $1 })
        } catch { return .error(ABPUserModelError.badDownloads) }
    }

    /// Seed events.
    func makeDownloadEvents() -> ([SourceDownload]) -> (TaskDownloadEvents) {
        {
            Dictionary(uniqueKeysWithValues: $0
                .map { $0.task?.taskIdentifier }
                .compactMap {
                    ($0!, BehaviorSubject<DownloadEvent>(value: DownloadEvent()))
                })
        }
    }
}

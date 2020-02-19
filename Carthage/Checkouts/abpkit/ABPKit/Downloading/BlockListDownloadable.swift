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

/// This applies to User and Updater.
public
protocol BlockListDownloadable {
    associatedtype UserType: Persistable

    var blockList: BlockList? { get set }
    /// To be synced with local storage.
    var downloads: [BlockList]? { get set }
    var lastVersion: String? { get set }

    func getBlockList() -> BlockList?
    func blockListSet() -> (BlockList) -> Self
    func getDownloads() -> [BlockList]?
    func downloadAdded() -> (BlockList) throws -> Self
    func downloadsUpdated() throws -> Self
    func historyUpdated() throws -> Self
    func acceptableAdsInUse() -> Bool
}

extension BlockListDownloadable where Self: HistoryEditable & DownloadCountable {
    public
    func getBlockList() -> BlockList? {
        blockList
    }

    public
    func blockListSet() -> (BlockList) -> Self {
        { var copy = self; copy.blockList = $0; return copy }
    }

    public
    func getDownloads() -> [BlockList]? {
        downloads?.sorted {
            $0.dateDownload?.compare($1.dateDownload ?? .distantPast) == .orderedDescending
        }
    }

    /// Add a block list to the user's downloads.
    public
    func downloadAdded() -> (BlockList) throws -> Self {
        {
            var copy = self
            if copy.downloads == nil { copy.downloads = [] }
            var blst = $0
            blst.dateDownload = Date()
            copy.downloads!.append(blst)
            try self.incrementDownloadCount()
            return copy
        }
    }

    /// Does not include current block list.
    public
    func downloadsUpdated() throws -> Self {
        var max: Int!
        switch UserType.self {
        case is User.Type:
            max = Constants.userBlockListMax
        case is Updater.Type:
            max = Constants.updaterBlockListMax
        default:
            throw ABPMutableStateError.invalidType
        }
        var copy = self
        if copy.downloads == nil { copy.downloads = [] }
        copy.downloads = self.prunedHistory(max)(copy.downloads!)
        return copy
    }

    public
    func acceptableAdsInUse() -> Bool {
        if let blst = blockList,
            let sourceHasAA = try? AcceptableAdsHelper().aaExists()(blst.source) {
            return sourceHasAA
        }
        return false
    }
}

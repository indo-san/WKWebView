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

/// Represents the state of the automatic updater.
public
struct Updater: Persistable,
                BlockListDownloadable,
                HistoryEditable,
                DownloadsSyncable,
                DownloadCountable {
    public typealias UserType = Updater

    public let name: String
    /// Active block list from the User.
    public var blockList: BlockList?
    /// To be synced with local storage.
    public var downloads: [BlockList]?
    /// Last downloaded blocklist version, if available.
    public var lastVersion: String?
}

extension Updater {
    public
    init() throws {
        name = UUID().uuidString
        blockList = try BlockList(
            withAcceptableAds: true,
            source: RemoteBlockList.easylistPlusExceptions,
            initiator: .automaticUpdate)
        downloads = []
    }

    init?(fromPersistentStorage: Bool,
          persistenceID: String? = nil) throws {
        switch fromPersistentStorage {
        case true:
            try self.init(persistenceID: "ignore_id")
        case false:
            try self.init()
        }
    }

    public
    init?(persistenceID: String) throws {
        let pstr = try Persistor()
        do {
            self = try pstr.decodeModelData(
                type: Updater.self,
                modelData: pstr.load(type: Data.self, key: ABPMutableState.StateName.updater))
        } catch { self = try Updater().saved() } // init with default
    }
}

extension Updater {
    /// Exists only to satisfy generic usage of BlockListDownloadable.
    public
    func historyUpdated() throws -> Updater {
        self
    }
}

extension Updater {
    public
    func save(file: String = #file, line: Int = #line, function: String = #function) throws {
        try Persistor().saveModel(self, state: .updater)
    }

    public
    func saved(file: String = #file, line: Int = #line, function: String = #function) throws -> Updater {
        try Persistor().saveModel(self, state: .updater); return self
    }
}

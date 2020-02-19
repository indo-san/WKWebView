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

/// User state has one active BlockList. It may be a copy from a cache collection.
public
struct User: Persistable,
             Equatable,
             RulesOperable,
             BlockListDownloadable,
             HistoryEditable,
             DownloadsSyncable,
             DownloadCountable {
    public typealias UserType = User
    public let name: String
    /// Active block list.
    public var blockList: BlockList?
    /// Lists that have been used by a user. To be synced with rule lists in WKContentRuleListStore.
    var blockListHistory: [BlockList]?
    /// To be synced with local storage.
    public var downloads: [BlockList]?
    /// Last downloaded blocklist version, if available.
    public var lastVersion: String?
    var whitelistedDomains: [String]?
}

extension User {
    /// Default init: User gets a default block list.
    public
    init() throws {
        name = UUID().uuidString
        blockList = try BlockList(
            withAcceptableAds: true,
            source: RemoteBlockList.easylistPlusExceptions,
            initiator: .userAction)
        blockListHistory = []
        downloads = []
        whitelistedDomains = []
        lastVersion = "0"
    }

    /// For use during the period where only a single user is supported.
    public
    init?(fromPersistentStorage: Bool,
          persistenceID: String? = nil) throws {
        switch fromPersistentStorage {
        case true:
            try self.init(persistenceID: "ignore_id")
        case false:
            try self.init()
        }
    }

    /// Set the block list during init.
    public
    init?(fromPersistentStorage: Bool,
          withBlockList: BlockList) throws {
        try self.init(fromPersistentStorage: fromPersistentStorage)
        blockList = withBlockList
    }

    /// Only a single user is supported here and identifier is not used.
    /// Multiple user support will be in a future version.
    public
    init?(persistenceID: String) throws {
        let pstr = try Persistor()
        self = try pstr.decodeModelData(
            type: User.self,
            modelData: pstr.load(type: Data.self, key: ABPMutableState.StateName.user))
    }

    /// Log stored rules files when logRulesFiles is true.
    init?(persistenceID: String,
          logRulesFiles: Bool = false) throws {
        try self.init(persistenceID: persistenceID)
        if logRulesFiles { try Persistor().logRulesFiles() }
    }
}

// MARK: - Getters -

extension User {
    public
    func getName() -> String {
        name
    }

    public
    func getWhiteListedDomains() -> [String]? {
        whitelistedDomains
    }

    /// Exclude nil download dates. These are placeholder items that are not added to the store.
    /// This may be need to be revised for integrations that use bundled block lists.
    public
    func getHistory() -> [BlockList]? {
        blockListHistory?
            .filter { $0.dateDownload != nil }
            .sorted { $0.dateDownload?.compare($1.dateDownload ?? .distantPast) == .orderedDescending }
    }

    func blockListNamed(_ name: String) -> ([BlockList]) throws -> BlockList? {
        { lists in
            let res = lists.filter { $0.name == name }
            if res.count == 1 { return res.first }
            throw ABPUserModelError.badDataUser
        }
    }
}

// MARK: - Copiers -

extension User {
    /// Set domains for user's white list.
    public
    func whiteListedDomainsSet() -> ([String]) -> User {
        { var copy = self; copy.whitelistedDomains = $0; return copy }
    }

    /// Adds the current blocklist to history while pruning.
    /// Does not automatically get called.
    /// Should be called when changing the user's rule list.
    /// The active BL is kept in the history.
    public
    func historyUpdated() throws -> User {
        let max = Constants.userHistoryMax
        var copy = self
        guard let blst = copy.blockList else { throw ABPUserModelError.failedUpdateData }
        if copy.blockListHistory == nil { copy.blockListHistory = [] }
        if (copy.blockListHistory!.contains { $0.name == blst.name }) {
            copy.blockListHistory = self.prunedHistory(max)(copy.blockListHistory!)
        } else {
            copy.blockListHistory = self.prunedHistory(max)(self.prunedHistory(max)(copy.blockListHistory!) + [blst])
        }
        return copy
    }

    func updatedBlockList() -> (BlockList) -> User {
        { var copy = self; copy.blockList = $0; return copy }
    }
}

// MARK: - Savers -

extension User {
    public
    func save(file: String = #file, line: Int = #line, function: String = #function) throws {
        try Persistor().saveModel(self, state: .user)
    }

    public
    func saved(file: String = #file, line: Int = #line, function: String = #function) throws -> User {
        try Persistor().saveModel(self, state: .user); return self
    }
}

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

/// A download counter that is meant to used independently from user state.
struct DownloadCounter: Persistable,
                        Equatable {
    typealias UserType = User

    static let defaultLabel = "download-counter"
    static let testingLabel = "download-counter-testing"
    let name: String
    var downloadCount: Int = 0
    var testing: Bool = false

    private
    enum CodingKeys: String, CodingKey {
        case name
        case downloadCount
    }

    // The throwing requirement will be revisited in future versions for Persistables.
    init() throws {
        name = DownloadCounter.defaultLabel
    }

    init(name: String) {
        self.name = name
    }

    public
    init?(fromPersistentStorage: Bool,
          persistenceID: String? = nil) throws {
        switch fromPersistentStorage {
        case true:
            try self.init(persistenceID: DownloadCounter.defaultLabel)
        case false:
            try self.init()
        }
    }

    public
    init?(testingFromPersistentStorage: Bool) throws {
        switch testingFromPersistentStorage {
        case true:
            let pstr = try Persistor()
            self = try pstr.decodeModelData(
                type: DownloadCounter.self,
                modelData: pstr.load(type: Data.self, key: ABPMutableState.StateName.downloadCounterTesting))
        case false:
            try self.init()
        }
    }

    init?(persistenceID: String) throws {
        let pstr = try Persistor()
        self = try pstr.decodeModelData(
            type: DownloadCounter.self,
            modelData: pstr.load(type: Data.self, key: ABPMutableState.StateName.downloadCounter))
    }
}

extension DownloadCounter {
    func save(file: String = #file, line: Int = #line, function: String = #function) throws {
        try Persistor().saveModel(self, state: .downloadCounter)
    }

    func saved(file: String = #file, line: Int = #line, function: String = #function) throws -> DownloadCounter {
        try Persistor().saveModel(self, state: .downloadCounter); return self
    }

    func saveTesting() throws {
        try Persistor().saveModel(self, state: .downloadCounterTesting)
    }
}

extension DownloadCounter {
    func stringForHTTPRequest() -> String {
        switch downloadCount {
        case let cnt where cnt <= Constants.downloadCounterMax:
            return String(cnt)
        default:
            return String(Constants.downloadCounterMax) + "+"
        }
    }
}

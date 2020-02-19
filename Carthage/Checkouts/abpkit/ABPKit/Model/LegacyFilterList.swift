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

/// Swift-based FilterList model struct to replace the Objective-C FilterList model object. This
/// is used internally to represent filter lists.
///
/// Some legacy properties exist but will be removed in future versions.
///
/// Overall, this struct represents the legacy model and will be re-factored in
/// a future version.
public
struct LegacyFilterList: Persistable {
    typealias UserType = User

    /// Counter for number of successful downloads.
    public var downloadCount: Int?

    /// Name used to identify a list uniquely.
    public var name: FilterListName

    /// The last version value extracted from the filter list or default value of "0".
    public var lastVersion: FilterListLastVersion = "0"

    /// Task identifier of the associated download task.
    public var taskIdentifier: Int?

    /// Group identifier refer to an associated download group. Only download tasks triggered by a
    /// user are allowed to display download failure dialogs. The updatingGroupIdentifier
    /// represents the group of the most recent download tasks.
    public var updatingGroupIdentifier: Int?

    public var downloaded: Bool?
    public var expires: TimeInterval?
    public var fileName: String?
    /// Date of download.
    public var lastUpdate: Date?
    /// Legacy property.
    public var lastUpdateFailed: Bool?
    /// Legacy property.
    public var updating: Bool?
    /// Original download location as a URL string.
    public var source: String?
    /// Legacy property.
    public var userTriggered: Bool?
    public var version: String?

    public
    init() throws {
        name = UUID().uuidString
    }

    public
    init?(persistenceID: String) throws {
        let models: () throws -> ([LegacyFilterList]) = {
            try Persistor()
                .loadFilterListModels()
                .filter { $0.name == persistenceID }
        }
        switch try models() {
        case let arr where arr.count == 1:
            self = arr.first!
        case let arr where arr.count > 1:
            throw ABPMutableStateError.ambiguousModels
        default:
            return nil
        }
    }
}

extension LegacyFilterList {
    /// The bundle may need to be explicitly set when accessing rules from a bundle other than the
    /// Config's bundle.
    /// Example: rulesURL(bundle: Bundle(for: ...))
    /// - returns: URL for local content blocking rules, i.e. the JSON file.
    func rulesURL(bundle: Bundle = Config().bundle(),
                  ignoreBundle: Bool = false) throws -> URL? {
        try LegacyRulesHelper()
            .rulesURL(identifier: self.name,
                      bundle: bundle,
                      ignoreBundle: ignoreBundle)
    }

    public
    func save(file: String = #file, line: Int = #line, function: String = #function) throws {
        try Persistor().saveFilterListModel(self)
    }

    public
    func saved(file: String = #file, line: Int = #line, function: String = #function) throws -> LegacyFilterList {
        try Persistor().saveFilterListModel(self); return self
    }

    /// This is not using an expiration interval from a v2 filter list as that data is not yet available.
    /// - Returns: True if the filter list is considered to be expired.
    public
    func expired() -> Bool {
        let nowInterval = Date.timeIntervalSinceReferenceDate
        if expires == nil && lastUpdate != nil {
            // Default to a fixed expiration.
            let defaultIntervalPlusLast =
                lastUpdate!.addingTimeInterval(Constants.defaultFilterListExpiration)
                    .timeIntervalSinceReferenceDate
            return defaultIntervalPlusLast < nowInterval
        } else if expires != nil && lastUpdate != nil {
            return expires! < nowInterval
        } else {
            // Expires is nil and last update is nil.
            return true
        }
    }
}

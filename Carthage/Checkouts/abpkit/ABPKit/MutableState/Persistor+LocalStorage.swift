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

extension Persistor {
    class func applicationSupportDirectory() throws -> URL {
        try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }

    /// Show files in the container.
    func logRulesFiles() throws {
        try clearRulesFiles(onlyLog: true)
    }

    /// Wipe out rules files in the current configured container.
    func clearRulesFiles() throws {
        try clearRulesFiles(onlyLog: false)
    }

    func jsonFiles() -> (FileManager.DirectoryEnumerator) -> [URL] {
        {
            var urls = [URL]()
            while let fileURL = $0.nextObject() as? URL {
                if self.jsonFile()(fileURL) { urls.append(fileURL) }
            }
            return urls
        }
    }

    func fileEnumeratorForRoot() -> (URL) throws -> FileManager.DirectoryEnumerator {
        {
            let errHandler: (URL, Error) -> Bool = { _, err in
                log("Error during enumeration: \(err)")
                return true
            }
            if let enmr = FileManager.default
                .enumerator(
                    at: $0,
                    includingPropertiesForKeys: [.isDirectoryKey, .nameKey],
                    options: [.skipsHiddenFiles, .skipsPackageDescendants],
                    errorHandler: errHandler) {
                return enmr
            } else { throw ABPMutableStateError.badEnumerator }
        }
    }

    private
    func jsonFile() -> (URL) -> Bool {
        {
            $0
                .lastPathComponent
                .split(separator: ".")
                .contains(Substring(Constants.rulesExtension))
        }
    }

    private
    func storeFile() -> (URL) -> Bool {
        let storeSuffix = "store"
        return {
            $0
                .lastPathComponent
                .contains(Substring(storeSuffix))
            }
    }

    /// Used during testing.
    private
    func clearRulesFiles(onlyLog: Bool = false) throws {
        let mgr = FileManager.default
        let url = try Config().containerURL()
        let enmr = try fileEnumeratorForRoot()(url)
        var paths = [String]()
        while let fileURL = enmr.nextObject() as? URL {
            if jsonFile()(fileURL) {
                if !onlyLog {
                    do {
                        try mgr.removeItem(at: fileURL)
                        log("🗑️ \(fileURL.path)")
                    } catch let err { throw err }
                } else {
                    paths.append(fileURL.path)
                }
            }
            if storeFile()(fileURL) {
                paths.append(fileURL.path)
            }
        }
        paths.sorted().forEach {
            log("🔵 \($0)")
        }
        log("")
    }
}

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

extension LegacyBlockListDownloader {
    /// - returns: The filter list name for a given task identifier.
    func filterListName(for taskIdentifier: Int) throws -> FilterListName? {
        let models = try Persistor().loadFilterListModels()
        var result: FilterListName?
        var cnt = 0
        for list in models where list.taskIdentifier == taskIdentifier {
            result = list.name
            cnt += 1
        }
        if cnt != 0 && cnt != 1 {
            throw ABPFilterListError.ambiguousModels
        }
        return result
    }

    func filterList(withName name: String?) throws -> LegacyFilterList? {
        guard name != nil else { return nil }
        let models = try Persistor().loadFilterListModels()
        var result: LegacyFilterList?
        var cnt = 0
        for list in models where list.name == name {
            cnt += 1
            result = list
        }
        if cnt != 0 && cnt != 1 {
            throw ABPFilterListError.ambiguousModels
        }
        return result
    }

    /// Move a file to a destination. If the file exists, it will be first removed, if possible.
    /// - returns: With no error if the operation cannot be completed.
    func moveOrReplaceItem(source: URL,
                           destination: URL?) throws {
        guard let dest = destination else {
            throw ABPDownloadTaskError.badDestinationURL
        }
        let mgr = FileManager.default
        let destPath = dest.path
        let exists = mgr.fileExists(atPath: destPath)
        var removeError: Error?
        if exists {
            do {
                try mgr.removeItem(atPath: destPath)
            } catch let rmErr {
                removeError = rmErr
            }
        }
        if removeError == nil {
            do {
                try mgr.moveItem(at: source, to: dest)
            } catch {
                throw ABPDownloadTaskError.failedMove
            }
        } else {
            throw ABPDownloadTaskError.failedRemoval
        }
    }

    func copyItem(source: URL,
                  destination: URL) throws {
        let mgr = FileManager.default
        do {
            try mgr.copyItem(at: source, to: destination)
        } catch {
            throw ABPDownloadTaskError.failedCopy
        }
    }
}
